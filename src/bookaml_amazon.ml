(********************************************************************************)
(*	Bookaml_amazon.ml
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

open Lwt
open CalendarLib
open ExtString
open ExtList
open Simplexmlparser


(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception No_response
exception No_match of ISBN.t


(********************************************************************************)
(**	{1 Inner modules}							*)
(********************************************************************************)

module Locale =
struct
	type t = [ `CA | `CN | `DE | `ES | `FR | `IT | `JP | `UK | `US ]

	type pg_t = string

	let of_string = function
		| "CA" | "ca" -> `CA
		| "CN" | "cn" -> `CN
		| "DE" | "de" -> `DE
		| "ES" | "es" -> `ES
		| "FR" | "fr" -> `FR
		| "IT" | "it" -> `IT
		| "JP" | "jp" -> `JP
		| "UK" | "uk" -> `UK
		| "US" | "us" -> `US
		| x 	      -> invalid_arg ("Locale.of_string: " ^ x)

	let to_string = function
		| `CA -> "CA"
		| `CN -> "CN"
		| `DE -> "DE"
		| `ES -> "ES"
		| `FR -> "FR"
		| `IT -> "IT"
		| `JP -> "JP"
		| `UK -> "UK"
		| `US -> "US"

	let of_pg = of_string

	let to_pg = to_string
end


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

type credential_t =
	{
	bk_locale: Locale.t;
	bk_associate_tag: string;
	bk_access_key: string;
	bk_secret_key: string;
	}


type price_t =
	{
	bk_amount: int;
	bk_currency: string;
	bk_formatted: string;
	}


type image_t =
	{
	bk_url: XHTML.M.uri;
	bk_width: int;
	bk_height: int;
	}


type book_t =
	{
	bk_isbn: ISBN.t;
	bk_title: string;
	bk_author: string;
	bk_publisher: string;
	bk_pubdate: string option;
	bk_page: XHTML.M.uri;
	bk_price_list: price_t option;
	bk_price_new: price_t option;
	bk_price_used: price_t option;
	bk_price_collectible: price_t option;
	bk_price_refurbished: price_t option;
	bk_image_small: image_t option;
	bk_image_medium: image_t option;
	bk_image_large: image_t option;
	}


type criteria_t = (string * string) list


(********************************************************************************)
(**	{1 Private functions and values}					*)
(********************************************************************************)

let maybe f = function
	| Some x -> Some (f x)
	| None	 -> None


let endpoint locale =
	let host_prefix1 = "ecs.amazonaws."
	and host_prefix2 = "webservices.amazon." in
	let host = match locale with
		| `CA -> host_prefix1 ^ "ca"
		| `CN -> host_prefix2 ^ "cn"
		| `DE -> host_prefix1 ^ "de"
		| `ES -> host_prefix2 ^ "es"
		| `FR -> host_prefix1 ^ "fr"
		| `IT -> host_prefix2 ^ "it"
		| `JP -> host_prefix1 ^ "jp"
		| `UK -> host_prefix1 ^ "co.uk"
		| `US -> host_prefix1 ^ "com"
	in (host, ["onca"; "xml"])


let xfind_all forest tag =
	let is_tag = function
		| Element (x, _, children) when x = tag -> Some children
		| _					-> None
	in List.filter_map is_tag forest


let xfind_one forest tag = match xfind_all forest tag with
	| hd :: _ -> hd
	| []	  -> raise Not_found


let rec xget = function
	| (PCData x) :: [] -> x
	| (PCData x) :: tl -> x ^ (xget tl)
	| _		   -> raise Not_found


let (|>) x f = f x


let (<*>) = xfind_all


let (<|>) = xfind_one


let (<|?>) xml tag =
	try Some (xfind_one xml tag)
	with Not_found -> None


let (<!>) xml tag = xfind_one xml tag |> xget


let (<!?>) xml tag =
	try Some (xfind_one xml tag |> xget)
	with Not_found -> None


let make_request ~host ~path ~secret_key pairs =
	let pathstr = "/" ^ (String.join "/" path)
	and base_request =
		pairs |>
		List.sort ~cmp:(fun (k1, _) (k2, _) -> Pervasives.compare k1 k2) |>		(* Sort items by key *)
		List.map (fun (k, v) -> (k, Netencoding.Url.encode ~plus:false v)) |>		(* URL-encode values. Note: we do not use '+' for spaces! *)
		List.map (fun (k, v) -> k ^ "=" ^ v) |>						(* Merge keys and values *)
		String.join "&"									(* Join all pairs with ampersand *)
	and base64enc = Cryptokit.Base64.encode_multiline ()
	and hmac = Cryptokit.MAC.hmac_sha256 secret_key in
	let payload = "GET\n" ^ host ^ "\n" ^ pathstr ^ "\n" ^ base_request in
	let signature =
		hmac#add_string payload;
		base64enc#put_string hmac#result;
		base64enc#finish;
		base64enc#get_string |>
		String.rchop in
	let query = base_request ^ "&Signature=" ^ (Netencoding.Url.encode ~plus:false signature) in
	let uri = pathstr ^ "?" ^ query in
	Ocsigen_http_client.get ~host ~uri () >>= fun frame ->
	match frame.Ocsigen_http_frame.frame_content with
		| Some stream ->
			let buf = Buffer.create 4096 in
			let rec string_of_stream stream =
				Ocsigen_stream.next stream >>= function
					| Ocsigen_stream.Cont (str, stream)	-> Buffer.add_string buf str; string_of_stream stream
					| Ocsigen_stream.Finished (Some stream) -> string_of_stream stream
					| Ocsigen_stream.Finished None		-> Lwt.return (Buffer.contents buf)
			in string_of_stream (Ocsigen_stream.get stream)
		| None ->
			Lwt.fail No_response


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

let make_credential ~locale ~associate_tag ~access_key ~secret_key =
	{
	bk_locale = locale;
	bk_associate_tag = associate_tag;
	bk_access_key = access_key;
	bk_secret_key = secret_key;
	}


let make_criteria ?title ?author ?publisher ?keywords () =
	let filter (k, v) = match v with
		| Some data -> Some (k, data)
		| None -> None in
	let criteria = List.filter_map filter [("Title", title); ("Author", author); ("Publisher", publisher); ("Keywords", keywords)]
	in match criteria with
		| [] -> invalid_arg "make_criteria: no criteria given"
		| xs -> xs


let find_some_books ?(page = 1) ?(service = "AWSECommerceService") ?(version = "2011-08-01") ~credential criteria =
	let (host, path) = endpoint credential.bk_locale
	and pairs =
		[
		("AssociateTag", credential.bk_associate_tag);
		("Service", service);
		("Version", version);
		("AWSAccessKeyId", credential.bk_access_key);
		("Timestamp", Printer.Calendar.sprint "%FT%TZ" (Calendar.now ()));	(* Combined date and time in UTC, as per ISO-8601 *)
		("Operation", "ItemSearch");
		("ItemPage", string_of_int page);
		("SearchIndex", "Books");
		("ResponseGroup", "ItemAttributes,Images,OfferSummary");
		] @ criteria in
	make_request ~host ~path ~secret_key:credential.bk_secret_key pairs >>= fun response ->
	try
		Std.output_file ~filename:"/home/dario/book.xml" ~text:response;
		let xml = Simplexmlparser.xmlparser_string response in
		let items_group = xml <|> "ItemSearchResponse" <|> "Items" in
		let total_results = items_group <!> "TotalResults" |> int_of_string
		and total_pages = items_group <!> "TotalPages" |> int_of_string
		and items = items_group <*> "Item" in
		let make_book item =
			let make_price list_price =
				{
				bk_amount = list_price <!> "Amount" |> int_of_string;
				bk_currency = list_price <!> "CurrencyCode";
				bk_formatted = list_price <!> "FormattedPrice";
				}
			and make_image img =
				{
				bk_url = img <!> "URL" |> XHTML.M.uri_of_string;
				bk_width = img <!> "Width" |> int_of_string;
				bk_height = img <!> "Height" |> int_of_string;
				}
			and item_attributes = item <|> "ItemAttributes"
			and offer_summary = item <|> "OfferSummary" in
			try Some
				{
				bk_isbn = item_attributes <!> "ISBN" |> ISBN.of_string;
				bk_title = item_attributes <!> "Title";
				bk_author = item_attributes <!> "Author";
				bk_publisher = item_attributes <!> "Publisher";
				bk_pubdate = item_attributes <!?> "PublicationDate";
				bk_page = item <!> "DetailPageURL" |> XHTML.M.uri_of_string;
				bk_price_list = item_attributes <|?> "ListPrice" |> maybe make_price;
				bk_price_new = offer_summary <|?> "LowestNewPrice" |> maybe make_price;
				bk_price_used = offer_summary <|?> "LowestUsedPrice" |> maybe make_price;
				bk_price_collectible = offer_summary <|?> "LowestCollectiblePrice" |> maybe make_price;
				bk_price_refurbished = offer_summary <|?> "LowestRefurbishedPrice" |> maybe make_price;
				bk_image_small = item <|?> "SmallImage" |> maybe make_image;
				bk_image_medium = item <|?> "MediumImage" |> maybe make_image;
				bk_image_large = item <|?> "LargeImage" |> maybe make_image;
				}
			with Not_found -> None
		in Lwt.return (total_results, total_pages, List.filter_map make_book items)
	with
		exc -> Lwt.fail exc


let find_all_books ?service ?version ~credential criteria =
	let get_page i = find_some_books ~page:i ?service ?version ~credential criteria in
	get_page 1 >>= fun (total_results, total_pages, books) ->
	if total_pages > 1
	then
		let pages = Array.init (total_pages - 1) (fun i -> i+2) |> Array.to_list in
		Lwt_list.map_p (fun i -> get_page i >>= fun (_, _, xs) -> Lwt.return xs) pages >>= fun results ->
		Lwt.return (books @ (List.concat results))
	else
		Lwt.return books


let book_from_isbn ?service ?version ~credential isbn =
	let criteria = make_criteria ~keywords:(ISBN.to_string isbn) () in
	find_some_books ?service ?version ~credential criteria >>= function
		| (_, _, hd :: _) -> Lwt.return (Some hd)
		| (_, _, [])	  -> Lwt.return None


let book_from_isbn_exn ?service ?version ~credential isbn =
	book_from_isbn ?service ?version ~credential isbn >>= function
		| Some book -> Lwt.return book
		| None	    -> Lwt.fail (No_match isbn)

