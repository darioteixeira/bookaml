(********************************************************************************)
(*	Bookaml_amazon.ml
	Copyright (c) 2010 Dario Teixeira (dario.teixeira@yahoo.com)
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
exception No_match


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

type image_t =
	{
	url: XHTML.M.uri;
	width: int;
	height: int;
	description: string;
	}


type book_t =
	{
	title: string;
	author: string;
	publisher: string;
	page: XHTML.M.uri;
	images: (string * image_t list) list;
	}


type locale_t = CA | CN | DE | FR | IT | JP | UK | US


type criteria_t = (string * string) list


(********************************************************************************)
(**	{1 Private functions and values}					*)
(********************************************************************************)

let (|>) x f = f x


let endpoint locale =
	let host_prefix1 = "ecs.amazonaws."
	and host_prefix2 = "webservices.amazon." in
	let host = match locale with
		| CA -> host_prefix1 ^ "ca"
		| CN -> host_prefix2 ^ "cn"
		| DE -> host_prefix1 ^ "de"
		| FR -> host_prefix1 ^ "fr"
		| IT -> host_prefix2 ^ "it"
		| JP -> host_prefix1 ^ "jp"
		| UK -> host_prefix1 ^ "co.uk"
		| US -> host_prefix1 ^ "com"
	in (host, ["onca"; "xml"])


let xfind_all forest tag =
	let is_tag = function
		| Element (x, _, children) when x = tag -> Some children
		| _					-> None
	in List.filter_map is_tag forest


let xfind_one forest tag = match xfind_all forest tag with
	| hd :: _ -> hd
	| []	  -> raise Not_found


let xget = function
	| [PCData x] -> x
	| _          -> raise Not_found


let (|>) x f = f x


let (<*>) = xfind_all


let (<|>) = xfind_one


let (<!>) xml tag = xfind_one xml tag |> xget


let (<?>) xml tag =
	try Some (xfind_one xml tag)
	with Not_found -> None


let make_image description img =
	{
	url = img <!> "URL" |> XHTML.M.uri_of_string;
	width = img <!> "Width" |> int_of_string;
	height = img <!> "Height" |> int_of_string;
	description = description;
	}


let parse_image = function
	| Element (tag, _, children) when String.ends_with tag "Image" ->
		Some (make_image (String.slice ~last:(-5) tag) children)
	| _ ->
		None


let parse_image_set = function
	| Element ("ImageSet", [("Category", category)], children) ->
		Some (category, List.filter_map parse_image children)
	| _ ->
		None


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

let make_criteria ?title ?author ?publisher ?keywords () =
	let filter (k, v) = match v with
		| Some data -> Some (k, data)
		| None -> None in
	let criteria = List.filter_map filter [("Title", title); ("Author", author); ("Publisher", publisher); ("Keywords", keywords)]
	in match criteria with
		| [] -> invalid_arg "make_criteria: no criteria given"
		| xs -> xs


let find_some_books ?(page = 1) ?(service = "AWSECommerceService") ?(version = "2011-08-01") ~associate_tag ~access_key ~secret_key ~locale criteria =
	let (host, path) = endpoint locale
	and pairs =
		[
		("AssociateTag", associate_tag);
		("Service", service);
		("Version", version);
		("AWSAccessKeyId", access_key);
		("Timestamp", Printer.Calendar.sprint "%FT%TZ" (Calendar.now ()));	(* Combined date and time in UTC, as per ISO-8601 *)
		("Operation", "ItemSearch");
		("ItemPage", string_of_int page);
		("SearchIndex", "Books");
		("ResponseGroup", "ItemAttributes,Images");
		] @ criteria in
	make_request ~host ~path ~secret_key pairs >>= fun response ->
	try
		let xml = Simplexmlparser.xmlparser_string response in
		let items_group = xml <|> "ItemSearchResponse" <|> "Items" in
		let total_results = items_group <!> "TotalResults" |> int_of_string
		and total_pages = items_group <!> "TotalPages" |> int_of_string
		and items = items_group <*> "Item" in
		let make_book item =
			let images =
				try item <|> "ImageSets" |> List.filter_map parse_image_set
				with Not_found -> []
			and attributes = item <|> "ItemAttributes" in
			try Some
				{
				title = attributes <!> "Title";
				author = attributes <!> "Author";
				publisher = attributes <!> "Publisher";
				page = item <!> "DetailPageURL" |> XHTML.M.uri_of_string;
				images = images;
				}
			with Not_found -> None
		in Lwt.return (total_results, total_pages, List.filter_map make_book items)
	with
		exc -> Lwt.fail exc


let find_all_books ?service ?version ~associate_tag ~access_key ~secret_key ~locale criteria =
	let get_page i = find_some_books ~page:i ?service ?version ~associate_tag ~access_key ~secret_key ~locale criteria in
	get_page 1 >>= fun (total_results, total_pages, books) ->
	if total_pages > 1
	then
		let pages = Array.init (total_pages - 1) (fun i -> i+2) |> Array.to_list in
		Lwt_list.map_p (fun i -> get_page i >>= fun (_, _, xs) -> Lwt.return xs) pages >>= fun results ->
		Lwt.return (books @ (List.concat results))
	else
		Lwt.return books


let book_from_isbn ?service ?version ~associate_tag ~access_key ~secret_key ~locale isbn =
	let criteria = make_criteria ~keywords:(Isbn.to_string isbn) () in
	find_some_books ?service ?version ~associate_tag ~access_key ~secret_key ~locale criteria >>= function
		| (_, _, hd :: _) -> Lwt.return (Some hd)
		| (_, _, [])	  -> Lwt.return None


let book_from_isbn_exn ?service ?version ~associate_tag ~access_key ~secret_key ~locale isbn =
	book_from_isbn ?service ?version ~associate_tag ~access_key ~secret_key ~locale isbn >>= function
		| Some book -> Lwt.return book
		| None	    -> Lwt.fail No_match

