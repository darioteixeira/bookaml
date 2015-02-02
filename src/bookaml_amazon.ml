(********************************************************************************)
(*	Bookaml_amazon.ml
	Copyright (c) 2010-2014 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

open CalendarLib

module List = BatList
module String = BatString


(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception No_response
exception No_match of [ `ISBN10 | `ISBN13 ] Bookaml_ISBN.t


(********************************************************************************)
(**	{1 Inner modules}							*)
(********************************************************************************)

module Locale =
struct
	type t = [ `BR | `CA | `CN | `DE | `ES | `FR | `IN | `IT | `JP | `UK | `US ]

	type pg_t = string

	let of_string = function
		| "BR" | "br" -> `BR
		| "CA" | "ca" -> `CA
		| "CN" | "cn" -> `CN
		| "DE" | "de" -> `DE
		| "ES" | "es" -> `ES
		| "FR" | "fr" -> `FR
		| "IN" | "in" -> `IN
		| "IT" | "it" -> `IT
		| "JP" | "jp" -> `JP
		| "UK" | "uk" -> `UK
		| "US" | "us" -> `US
		| x 	      -> invalid_arg ("Locale.of_string: " ^ x)

	let to_string = function
		| `BR -> "BR"
		| `CA -> "CA"
		| `CN -> "CN"
		| `DE -> "DE"
		| `ES -> "ES"
		| `FR -> "FR"
		| `IN -> "IN"
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
	let host_prefix = "webservices.amazon." in
	let host = match locale with
		| `BR -> host_prefix ^ "com.br"
		| `CA -> host_prefix ^ "ca"
		| `CN -> host_prefix ^ "cn"
		| `DE -> host_prefix ^ "de"
		| `ES -> host_prefix ^ "es"
		| `FR -> host_prefix ^ "fr"
		| `IN -> host_prefix ^ "in"
		| `IT -> host_prefix ^ "it"
		| `JP -> host_prefix ^ "co.jp"
		| `UK -> host_prefix ^ "co.uk"
		| `US -> host_prefix ^ "com" in
	(host, ["onca"; "xml"])


let get_common_pairs ~page ~credential =
	[
	("Service", "AWSECommerceService");
	("Operation", "ItemSearch");
	("AWSAccessKeyId", credential.access_key);
	("AssociateTag", credential.associate_tag);
	("SearchIndex", "Books");
	("Timestamp", Printer.Calendar.sprint "%FT%TZ" (Calendar.now ()));	(* Combined date and time in UTC, as per ISO-8601 *)
	("ItemPage", string_of_int page);
	("ResponseGroup", "ItemAttributes,Images,OfferSummary");
	]


let encode_request ~host ~path ~credential pairs =
	let pathstr = "/" ^ (String.join "/" path)
	and base_request =
		pairs |>
		List.sort (fun (k1, _) (k2, _) -> String.compare k1 k2) |>		(* Sort items by key *)
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

module type XMLHANDLER =
sig
	type xml

	val parse: string -> xml list
	val xfind_all: xml list -> string -> xml list list
	val xfind_one: xml list -> string -> xml list
	val xget: xml list -> string
end


module type HTTPGETTER =
sig
	module Monad:
	sig
		type 'a t

		val return: 'a -> 'a t
		val fail: exn -> 'a t
		val bind: 'a t -> ('a -> 'b t) -> 'b t
		val list_map: ('a -> 'b t) -> 'a list -> 'b list t
	end

	val perform_request: host:string -> string -> string Monad.t
end


module type ENGINE =
sig
	type 'a monad_t

	val find_some_books:
		?page:int ->
		credential:credential_t ->
		criteria_t ->
		(int * int * Bookaml_book.t list) monad_t

	val find_all_books:
		credential:credential_t ->
		criteria_t ->
		Bookaml_book.t list monad_t

	val book_from_isbn:
		credential:credential_t ->
		[< `ISBN10 | `ISBN13 ] Bookaml_ISBN.t ->
		Bookaml_book.t option monad_t

	val book_from_isbn_exn:
		credential:credential_t ->
		[< `ISBN10 | `ISBN13 ] Bookaml_ISBN.t ->
		Bookaml_book.t monad_t
end


(********************************************************************************)
(**	{1 Public functors}							*)
(********************************************************************************)

module Make (Xmlhandler: XMLHANDLER) (Httpgetter: HTTPGETTER) =
struct
	open Bookaml_book
	open Xmlhandler
	open Httpgetter


	(************************************************************************)
	(**	{1 Type definitions}						*)
	(************************************************************************)

	type 'a monad_t = 'a Monad.t


	(************************************************************************)
	(**	{1 Private functions and values}				*)
	(************************************************************************)

	let (>>=) t f = Monad.bind t f

	let (<*>) = xfind_all

	let (<|>) = xfind_one

	let (<|?>) xml tag =
		try Some (xfind_one xml tag)
		with Not_found -> None

	let (<!>) xml tag = xfind_one xml tag |> xget

	let (<!?>) xml tag =
		try Some (xfind_one xml tag |> xget)
		with Not_found -> None


	(************************************************************************)
	(**	{1 Public functions and values}					*)
	(************************************************************************)

	let find_some_books ?(page = 1) ~credential criteria =
		let pairs = criteria @ (get_common_pairs ~page ~credential) in
		let (host, path) = get_endpoint credential.locale in
		let request = encode_request ~host ~path ~credential pairs in
		Httpgetter.perform_request ~host request >>= fun response ->
		try
			let xml = Xmlhandler.parse response in
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
				let isbn = item_attributes <!> "ISBN" |> Bookaml_ISBN.of_string in
				try Some
					{
					isbn10 = Bookaml_ISBN.to_10 isbn;
					isbn13 = Bookaml_ISBN.to_13 isbn;
					title = item_attributes <!> "Title";
					author = item_attributes <!> "Author";
					publisher = item_attributes <!> "Publisher";
					pubdate = item_attributes <!?> "PublicationDate";
					page = item <!?> "DetailPageURL";
					list_price = item_attributes <|?> "ListPrice" |> maybe make_price;
					price_new = offer_summary <|?> "LowestNewPrice" |> maybe make_price;
					price_used = offer_summary <|?> "LowestUsedPrice" |> maybe make_price;
					price_collectible = offer_summary <|?> "LowestCollectiblePrice" |> maybe make_price;
					price_refurbished = offer_summary <|?> "LowestRefurbishedPrice" |> maybe make_price;
					image_small = item <|?> "SmallImage" |> maybe make_image;
					image_medium = item <|?> "MediumImage" |> maybe make_image;
					image_large = item <|?> "LargeImage" |> maybe make_image;
					}
				with Not_found -> None
			in Monad.return (total_results, total_pages, List.filter_map make_book items)
		with
			exc -> Monad.fail exc


	let find_all_books ~credential criteria =
		let get_page i = find_some_books ~page:i ~credential criteria in
		get_page 1 >>= fun (total_results, total_pages, books) ->
		if total_pages > 1
		then
			let pages = Array.init (total_pages - 1) (fun i -> i+2) |> Array.to_list in
			Monad.list_map (fun i -> get_page i >>= fun (_, _, xs) -> Monad.return xs) pages >>= fun results ->
			Monad.return (books @ (List.concat results))
		else
			Monad.return books


	let book_from_isbn ~credential isbn =
		let criteria = make_criteria ~keywords:(Bookaml_ISBN.to_string isbn) () in
		find_some_books ~credential criteria >>= function
			| (_, _, hd :: _) -> Monad.return (Some hd)
			| (_, _, [])	  -> Monad.return None


	let book_from_isbn_exn ~credential isbn =
		book_from_isbn ~credential isbn >>= function
			| Some book -> Monad.return book
			| None	    -> Monad.fail (No_match (isbn :> [ `ISBN10 | `ISBN13] Bookaml_ISBN.t))
end

