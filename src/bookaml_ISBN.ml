(********************************************************************************)
(*	Bookaml_ISBN.ml
	Copyright (c) 2010-2014 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GNU LGPL 2.1
	with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

module String = BatString


(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception Bad_ISBN_length of string
exception Bad_ISBN_checksum of string
exception Bad_ISBN_character of char


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

type +'a t =
	| ISBN10 of string
	| ISBN13 of string
	constraint 'a = [< `ISBN10 | `ISBN13 ]


type pg_t = string


(********************************************************************************)
(**	{1 Private functions and values}					*)
(********************************************************************************)

let value =
	let base = int_of_char '0' in
	function
		| '0' .. '9' as x -> (int_of_char x) - base
		| 'X' | 'x'	  -> 10
		| x		  -> raise (Bad_ISBN_character x)


let digit = 
	let base = int_of_char '0' in
	function
		| 10			  -> 'X'
		| x when x >= 0 && x < 10 -> char_of_int (x + base)
		| x			  -> invalid_arg ("Bookaml_ISBN.digit: " ^ (string_of_int x))


let sum10 digits =
	List.fold_left (+) 0 (List.mapi (fun i x -> (10 - i) * (value x)) digits)


let sum13 digits =
	List.fold_left (+) 0 (List.mapi (fun i x -> (if i mod 2 = 1 then 3 else 1) * (value x)) digits)


let check10 digits =
	(sum10 digits) mod 11 = 0


let check13 digits =
	(sum13 digits) mod 10 = 0


let compute10 digits =
	digit (11 - (sum10 digits mod 11))
		

let compute13 digits =
	digit ((10 - (sum13 digits mod 10)) mod 10)
		

let is_valid_aux f str =
	try ignore (f str); true
	with _ -> false


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

let of_string str =
	let digits = List.filter ((<>) '-') (String.explode str) in
	let (checker, cons) = match List.length digits with
		| 10 -> (check10, fun x -> ISBN10 x)
		| 13 -> (check13, fun x -> ISBN13 x)
		| _  -> raise (Bad_ISBN_length str) in
	if checker digits
	then cons (String.implode digits)
	else raise (Bad_ISBN_checksum str)


let of_string10 str = match of_string str with
	| (ISBN10 _) as isbn -> isbn
	| (ISBN13 _)	     -> raise (Bad_ISBN_length str)


let of_string13 str = match of_string str with
	| (ISBN13 _) as isbn -> isbn
	| (ISBN10 _)	     -> raise (Bad_ISBN_length str)


let to_string = function
	| ISBN10 x -> x
	| ISBN13 x -> x


let to_10 = function
	| ISBN10 _ as x ->
		Some x
	| ISBN13 x when String.starts_with x "978" ->
		let digits = String.explode (String.slice ~first:3 ~last:(-1) x) in
		let check_digit = compute10 digits in
		Some (ISBN10 (String.implode (digits @ [check_digit])))
	| ISBN13 _ ->
		None


let to_13 = function
	| ISBN10 x ->
		let digits = String.explode ("978" ^ String.slice ~last:(-1) x) in
		let check_digit = compute13 digits in
		ISBN13 (String.implode (digits @ [check_digit]))
	| ISBN13 _ as x ->
		x


let of_pg xstr = match String.length xstr with
	| 10 -> ISBN10 xstr
	| 13 -> ISBN13 xstr
	| _  -> invalid_arg ("Bookaml_ISBN.of_pg: " ^ xstr)


let of_pg10 xstr = match String.length xstr with
	| 10 -> ISBN10 xstr
	| _  -> invalid_arg ("Bookaml_ISBN.of_pg10: " ^ xstr)


let of_pg13 xstr = match String.length xstr with
	| 13 -> ISBN13 xstr
	| _  -> invalid_arg ("Bookaml_ISBN.of_pg13: " ^ xstr)


let to_pg = to_string


let is_valid = is_valid_aux of_string


let is_valid10 = is_valid_aux of_string10


let is_valid13 = is_valid_aux of_string13


let is_10 = function
	| ISBN10 _ -> true
	| ISBN13 _ -> false


let is_13 = function
	| ISBN10 _ -> false
	| ISBN13 _ -> true

