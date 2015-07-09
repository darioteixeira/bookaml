(************************************************************************)

open Eliom_content
open Html5.F
open Lwt
open Bookaml_book


(************************************************************************)

let locale = `US            (* Set your locale *)
let associate_tag = "***"   (* Replace asterisks with your actual associate tag *)
let access_key = "***"      (* Replace asterisks with your actual access key *)
let secret_key = "***"      (* Replace asterisks with your actual secret key *)

let credential = Bookaml_amazon.make_credential ~locale ~associate_tag ~access_key ~secret_key


(************************************************************************)

let title_service =
    Eliom_service.Http.service
        ~path:["title"]
        ~get_params:(Eliom_parameter.string "title")
        ()

let isbn_service =
    Eliom_service.Http.service
        ~path:["isbn"]
        ~get_params:(Eliom_parameter.string "isbn")
        ()


let main_service =
    Eliom_service.Http.service
        ~path:[""]
        ~get_params:Eliom_parameter.unit
        ()


(************************************************************************)

let output_book book =
    let mprint = function
        | Some x -> x
        | None   -> "(none)"
    and output_price = function
        | Some price -> Printf.sprintf "(%d, %s, %s)" price.amount price.currency price.formatted
        | None       -> "(none)"
    and output_image = function
        | Some image -> p [Raw.a ~a:[a_href (Raw.uri_of_string image.url)] [pcdata (Printf.sprintf "(%d x %d)" image.width image.height)]]
        | None       -> p [pcdata "(none)"]
    in div
        [
        p [pcdata "Title: "; pcdata book.title];
        p [pcdata "Author: "; pcdata (mprint book.author)];
        p [pcdata "Publisher: "; pcdata (mprint book.publisher)];
        p [pcdata "Publication date: "; pcdata (mprint book.pubdate)];
        p [pcdata "Page: "; (match book.page with Some page -> Raw.a ~a:[a_href (Raw.uri_of_string page)] [pcdata "Page"] | None -> pcdata "(none)")];
        p [pcdata ("List price: " ^ (output_price book.list_price))];
        p [pcdata ("New price: " ^ (output_price book.price_new))];
        p [pcdata ("Used price: " ^ (output_price book.price_used))];
        p [pcdata ("Collectible price: " ^ (output_price book.price_collectible))];
        p [pcdata ("Refurbished price: " ^ (output_price book.price_refurbished))];
        p [pcdata "Small image:"]; output_image book.image_small;
        p [pcdata "Medium image:"]; output_image book.image_medium;
        p [pcdata "Large image:"]; output_image book.image_large;
        ]


let title_handler title () =
    let criteria = Bookaml_amazon.make_criteria ~title () in
    Bookaml_amazon_ocsigen.find_all_books ~credential criteria >>= fun books ->
    Lwt.return
        (html
        (head (Html5.F.title (pcdata "Book")) [])
        (body (p [pcdata ("Total results: " ^ (string_of_int (List.length books)))] :: List.map output_book books)))


let isbn_handler isbn () =
    Bookaml_amazon_ocsigen.book_from_isbn_exn ~credential (Bookaml_ISBN.of_string isbn) >>= fun book ->
    Lwt.return
        (html
        (head (title (pcdata "Book")) [])
        (body [output_book book]))


let title_form e_title =
    [
    label ~a:[a_for e_title] [pcdata "Title:"];
    string_input ~input_type:`Text ~name:e_title ();
    button ~button_type:`Submit [pcdata "Submit"];
    ]


let isbn_form e_isbn =
    [
    label ~a:[a_for e_isbn] [pcdata "ISBN:"];
    string_input ~a:[a_id "enter_isbn"] ~input_type:`Text ~name:e_isbn ();
    button ~button_type:`Submit [pcdata "Submit"];
    ]


let main_handler () () =
    Lwt.return
        (html
        (head (title (pcdata "Book")) [])
        (body
            [
            p [a isbn_service [pcdata "Book with ISBN 144932391X"] "144932391X"];
            p [a isbn_service [pcdata "Book with ISBN 978-1449323912"] "978-1449323912"];
            hr ();
            get_form title_service title_form;
            hr ();
            get_form isbn_service isbn_form;
            ]))


(************************************************************************)

let () =
    Eliom_registration.Html5.register title_service title_handler;
    Eliom_registration.Html5.register isbn_service isbn_handler;
    Eliom_registration.Html5.register main_service main_handler

