(********************************************************************************)
(*	Bookaml_amazon.ml
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

open ExtList
open ExtString
open CalendarLib


(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception No_response
exception No_match of Bookaml_ISBN.t


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
	locale: Locale.t;
	associate_tag: string;
	access_key: string;
	secret_key: string;
	}


type criteria_t = (string * string) list


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

let make_credential ~locale ~associate_tag ~access_key ~secret_key =
	{locale; associate_tag; access_key; secret_key}


let make_criteria ?title ?author ?publisher ?keywords () =
	let filter (k, v) = match v with
		| Some data -> Some (k, data)
		| None	    -> None in
	let criteria = List.filter_map filter [("Title", title); ("Author", author); ("Publisher", publisher); ("Keywords", keywords)]
	in match criteria with
		| [] -> invalid_arg "make_criteria: no criteria given"
		| xs -> xs


(********************************************************************************)
(**	{1 Private functions and values}					*)
(********************************************************************************)

let (|>) x f = f x


let maybe f = function
	| Some x -> Some (f x)
	| None	 -> None


let get_endpoint locale =
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


let get_common_pairs ~page ~service ~version ~credential =
	[
	("AssociateTag", credential.associate_tag);
	("Service", service);
	("Version", version);
	("AWSAccessKeyId", credential.access_key);
	("Timestamp", Printer.Calendar.sprint "%FT%TZ" (Calendar.now ()));	(* Combined date and time in UTC, as per ISO-8601 *)
	("Operation", "ItemSearch");
	("ItemPage", string_of_int page);
	("SearchIndex", "Books");
	("ResponseGroup", "ItemAttributes,Images,OfferSummary");
	]


let encode_request ~host ~path ~credential pairs =
	let pathstr = "/" ^ (String.join "/" path)
	and base_request =
		pairs |>
		List.sort ~cmp:(fun (k1, _) (k2, _) -> Pervasives.compare k1 k2) |>	(* Sort items by key *)
		List.map (fun (k, v) -> (k, Netencoding.Url.encode ~plus:false v)) |>	(* URL-encode values. Note: we do not use '+' for spaces! *)
		List.map (fun (k, v) -> k ^ "=" ^ v) |>					(* Merge keys and values *)
		String.join "&"								(* Join all pairs with ampersand *)
	and base64enc = Cryptokit.Base64.encode_multiline ()
	and hmac = Cryptokit.MAC.hmac_sha256 credential.secret_key in
	let payload = "GET\n" ^ host ^ "\n" ^ pathstr ^ "\n" ^ base_request in
	let signature =
		hmac#add_string payload;
		base64enc#put_string hmac#result;
		base64enc#finish;
		base64enc#get_string |>
		String.rchop in
	let query = base_request ^ "&Signature=" ^ (Netencoding.Url.encode ~plus:false signature) in
	pathstr ^ "?" ^ query



(********************************************************************************)
(**	{1 Public module types}							*)
(********************************************************************************)

module type XMLPARSER =
sig
	type xml

	val parse: string -> xml list
	val xfind_all: xml list -> string -> xml list list
	val xfind_one: xml list -> string -> xml list
	val xget: xml list -> string
end


module type HTTPGETTER =
sig
	type 'a monad

	val return: 'a -> 'a monad
	val fail: exn -> 'a monad
	val bind: 'a monad -> ('a -> 'b monad) -> 'b monad
	val list_map: ('a -> 'b monad) -> 'a list -> 'b list monad

	val perform_request: host:string -> string -> string monad
end


module type ENGINE =
sig
	type 'a monad

	val find_some_books:
		?page:int ->
		?service:string ->
		?version:string ->
		credential:credential_t ->
		criteria_t ->
		(int * int * Bookaml_book.t list) monad

	val find_all_books:
		?service:string ->
		?version:string ->
		credential:credential_t ->
		criteria_t ->
		Bookaml_book.t list monad

	val book_from_isbn:
		?service:string ->
		?version:string ->
		credential:credential_t ->
		Bookaml_ISBN.t ->
		Bookaml_book.t option monad

	val book_from_isbn_exn:
		?service:string ->
		?version:string ->
		credential:credential_t ->
		Bookaml_ISBN.t ->
		Bookaml_book.t monad
end


(********************************************************************************)
(**	{1 Public functors}							*)
(********************************************************************************)

module Make (Xmlparser: XMLPARSER) (Httpgetter: HTTPGETTER) =
struct
	open Bookaml_book


	(************************************************************************)
	(**	{1 Type definitions}						*)
	(************************************************************************)

	type 'a monad = 'a Httpgetter.monad


	(************************************************************************)
	(**	{1 Private functions and values}				*)
	(************************************************************************)

	let (>>=) t f = Httpgetter.bind t f

	let (<*>) = Xmlparser.xfind_all

	let (<|>) = Xmlparser.xfind_one

	let (<|?>) xml tag =
		try Some (Xmlparser.xfind_one xml tag)
		with Not_found -> None

	let (<!>) xml tag = Xmlparser.xfind_one xml tag |> Xmlparser.xget

	let (<!?>) xml tag =
		try Some (Xmlparser.xfind_one xml tag |> Xmlparser.xget)
		with Not_found -> None


	(************************************************************************)
	(**	{1 Public functions and values}					*)
	(************************************************************************)

	let find_some_books ?(page = 1) ?(service = "AWSECommerceService") ?(version = "2011-08-01") ~credential criteria =
		let pairs = criteria @ (get_common_pairs ~page ~service ~version ~credential) in
		let (host, path) = get_endpoint credential.locale in
		let request = encode_request ~host ~path ~credential pairs in
		Httpgetter.perform_request ~host request >>= fun response ->
		try
			let xml = Xmlparser.parse response in
			let items_group = xml <|> "ItemSearchResponse" <|> "Items" in
			let total_results = items_group <!> "TotalResults" |> int_of_string
			and total_pages = items_group <!> "TotalPages" |> int_of_string
			and items = items_group <*> "Item" in
			let make_book item =
				let make_price list_price =
					{
					amount = list_price <!> "Amount" |> int_of_string;
					currency = list_price <!> "CurrencyCode";
					formatted = list_price <!> "FormattedPrice";
					}
				and make_image img =
					{
					url = img <!> "URL";
					width = img <!> "Width" |> int_of_string;
					height = img <!> "Height" |> int_of_string;
					}
				and item_attributes = item <|> "ItemAttributes"
				and offer_summary = item <|> "OfferSummary" in
				try Some
					{
					isbn = item_attributes <!> "ISBN" |> Bookaml_ISBN.of_string;
					title = item_attributes <!> "Title";
					author = item_attributes <!> "Author";
					publisher = item_attributes <!> "Publisher";
					pubdate = item_attributes <!?> "PublicationDate";
					page = item <!?> "DetailPageURL";
					price_list = item_attributes <|?> "ListPrice" |> maybe make_price;
					price_new = offer_summary <|?> "LowestNewPrice" |> maybe make_price;
					price_used = offer_summary <|?> "LowestUsedPrice" |> maybe make_price;
					price_collectible = offer_summary <|?> "LowestCollectiblePrice" |> maybe make_price;
					price_refurbished = offer_summary <|?> "LowestRefurbishedPrice" |> maybe make_price;
					image_small = item <|?> "SmallImage" |> maybe make_image;
					image_medium = item <|?> "MediumImage" |> maybe make_image;
					image_large = item <|?> "LargeImage" |> maybe make_image;
					}
				with Not_found -> None
			in Httpgetter.return (total_results, total_pages, List.filter_map make_book items)
		with
			exc -> Httpgetter.fail exc


	let find_all_books ?service ?version ~credential criteria =
		let get_page i = find_some_books ~page:i ?service ?version ~credential criteria in
		get_page 1 >>= fun (total_results, total_pages, books) ->
		if total_pages > 1
		then
			let pages = Array.init (total_pages - 1) (fun i -> i+2) |> Array.to_list in
			Httpgetter.list_map (fun i -> get_page i >>= fun (_, _, xs) -> Httpgetter.return xs) pages >>= fun results ->
			Httpgetter.return (books @ (List.concat results))
		else
			Httpgetter.return books


	let book_from_isbn ?service ?version ~credential isbn =
		let criteria = make_criteria ~keywords:(Bookaml_ISBN.to_string isbn) () in
		find_some_books ?service ?version ~credential criteria >>= function
			| (_, _, hd :: _) -> Httpgetter.return (Some hd)
			| (_, _, [])	  -> Httpgetter.return None


	let book_from_isbn_exn ?service ?version ~credential isbn =
		book_from_isbn ?service ?version ~credential isbn >>= function
			| Some book -> Httpgetter.return book
			| None	    -> Httpgetter.fail (No_match isbn)
end

