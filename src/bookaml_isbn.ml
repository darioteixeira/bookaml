open Sexplib.Std


(********************************************************************************)
(** {1 Exceptions}                                                              *)
(********************************************************************************)

exception Bad_isbn_length of string
exception Bad_isbn_checksum of string
exception Bad_isbn_character of char


(********************************************************************************)
(** {1 Type definitions}                                                        *)
(********************************************************************************)

type from10 = {isbn10: string; isbn13: string} [@@deriving sexp]
type from13 = {isbn10: string option; isbn13: string} [@@deriving sexp]

type t =
    | From10 of from10
    | From13 of from13
    [@@deriving sexp]


(********************************************************************************)
(** {1 Private functions and values}                                            *)
(********************************************************************************)

let value_of_char =
    let base = int_of_char '0' in
    function
        | '0' .. '9' as x -> (int_of_char x) - base
        | 'X' | 'x'       -> 10
        | x               -> raise (Bad_isbn_character x)


let char_of_value = 
    let base = int_of_char '0' in
    function
        | 10                      -> 'X'
        | x when x >= 0 && x < 10 -> char_of_int (x + base)
        | x                       -> assert false


let sum ~f ~limit digits =
    let rec aux accum i = function
        | hd :: tl when i < limit -> aux (accum + f i hd) (i + 1) tl
        | _                       -> accum in
    aux 0 0 digits


let sum10 ~limit digits =
    let f i x = (10 - i) * value_of_char x in
    sum ~f ~limit digits


let sum13 ~limit digits =
    let f i x = (if i mod 2 = 1 then 3 else 1) * value_of_char x in
    sum ~f ~limit digits


let check10 digits =
    (sum10 ~limit:10 digits) mod 11 = 0


let check13 digits =
    (sum13 ~limit:13 digits) mod 10 = 0


let explode_and_filter str =
    let rec loop acc i =
        if i < 0
        then
            acc
        else
            let chr = str.[i] in
            let acc = if chr = '-' then acc else chr :: acc in
            loop acc (i - 1) in
    loop [] (String.length str - 1)


let implode ?length ?check_digit digits =
    let length = match length with Some l -> l | None -> List.length digits in
    let buf = Bytes.make length '\x00' in
    let rec loop i = function
        | hd :: tl when i < length -> Bytes.set buf i hd; loop (i + 1) tl
        | _                        -> () in
    loop 0 digits;
    begin match check_digit with
        | Some x -> Bytes.set buf (length - 1) x
        | None   -> ()
    end;
    Bytes.unsafe_to_string buf
       

let isbn10_of_isbn13 = function
    | '9' :: '7' :: '8' :: digits ->
        let check_digit = char_of_value ((11 - (sum10 ~limit:9 digits mod 11)) mod 11) in
        Some (implode ~length:10 ~check_digit digits)
    | _ ->
        None


let isbn13_of_isbn10 digits =
    let digits = '9' :: '7' :: '8' :: digits in
    let check_digit = char_of_value ((10 - (sum13 ~limit:12 digits mod 10)) mod 10) in
    implode ~length:13 ~check_digit digits


(********************************************************************************)
(** {1 Public functions and values}                                             *)
(********************************************************************************)

let of_string str =
    let digits = explode_and_filter str in
    let str' = implode digits in
    match String.length str' with
        | 10 ->
            if check10 digits
            then From10 {isbn10 = str'; isbn13 = isbn13_of_isbn10 digits}
            else raise (Bad_isbn_checksum str)
        | 13 ->
            if check13 digits
            then From13 {isbn10 = isbn10_of_isbn13 digits; isbn13 = str'}
            else raise (Bad_isbn_checksum str)
        | _ ->
            raise (Bad_isbn_length str)


let to_string = function
    | From10 x -> x.isbn10
    | From13 x -> x.isbn13


let to_string10 = function
    | From10 x -> Some x.isbn10
    | From13 x -> x.isbn10


let to_string13 = function
    | From10 x -> x.isbn13
    | From13 x -> x.isbn13


let is_valid str =
    try
        let digits = explode_and_filter str in
        let len = List.length digits in
        (len = 10 && check10 digits) || (len = 13 && check13 digits)
    with _ ->
        false


let is_valid10 str =
    try
        let digits = explode_and_filter str in
        List.length digits = 10 && check10 digits
    with _ ->
        false


let is_valid13 str =
    try
        let digits = explode_and_filter str in
        List.length digits = 13 && check13 digits
    with _ ->
        false

