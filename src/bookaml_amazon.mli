(********************************************************************************)
(*	Bookaml_amazon.mli
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

(**	This module provides facilities for finding information about books.
	It works by invoking the Amazon Product Advertising API, and therefore
	most of its functions require the associate tag, access key, and secret
	key available to registered users of Amazon Web Services.
*)


(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception No_response
exception No_match of ISBN.t


(********************************************************************************)
(**	{1 Inner modules}							*)
(********************************************************************************)

(**	Definition of the various supported Amazon locales.
*)
module Locale:
sig
	type t =
		[ `CA	(** Canada *)
		| `CN	(** China *)
		| `DE	(** Germany *)
		| `ES	(** Spain *)
		| `FR	(** France *)
		| `IT	(** Italy *)
		| `JP	(** Japan *)
		| `UK	(** United Kingdom *)
		| `US	(** United States *)
		]

	val of_string: string -> t
	val to_string: t -> string
end


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

(**	Credential for Amazon Web Services.
*)
type credential_t =
	{
	locale: Locale.t;
	associate_tag: string;
	access_key: string;
	secret_key: string;
	}


(**	Information about a book's price.
*)
type price_t =
	{
	amount: int;
	currency_code: string;
	formatted_price: string;
	}


(**	Information about a book image.
*)
type image_t =
	{
	url: XHTML.M.uri;
	width: int;
	height: int;
	}


(**	Information about a book.
*)
type book_t =
	{
	title: string;
	author: string;
	publisher: string;
	pubdate: string;
	isbn: ISBN.t;
	page: XHTML.M.uri;
	price: price_t;
	image_small: image_t;
	image_medium: image_t;
	image_large: image_t;
	}


(**	Search criteria expected by functions {!find_some_books} and {!find_all_books}.
	The search criteria must be created beforehand by function {!make_criteria}.
*)
type criteria_t


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

(**	Constructs the AWS credential that is required for functions {!find_some_books},
	{!find_all_books}, {!book_from_isbn}, and {!book_from_isbn_exn}.
*)
val make_credential:
	locale: Locale.t ->
	associate_tag: string ->
	access_key: string ->
	secret_key: string ->
	credential_t


(**	Constructs the search criteria that may later be given to functions
	{!find_some_books} or {!find_all_books}.  The search criteria may
	consist of any combination of [title], [author], [publisher], or
	generic [keywords].  If none are specified, exception [Invalid_arg]
	is raised.
*)
val make_criteria:
	?title:string ->
	?author:string ->
	?publisher:string ->
	?keywords:string ->
	unit ->
	criteria_t


(**	Finds some of the books that match the given search criteria.  The result
	is a 3-tuple consisting of the total number of books matching the critera,
	the total number of result pages, and a list of books for the current page.
	Note that only one page of results (consisting of a maximum of 10 books)
	can be obtained per invocation of this function.  By default, the first
	page of results is returned.  If you wish to obtain a different result
	page, then set parameter [page] with the corresponding page number.  If
	you wish to obtain all books from all result pages, then consult function
	{!find_all_books}.
*)
val find_some_books:
	?page:int ->
	?service:string ->
	?version:string ->
	credential:credential_t ->
	criteria_t ->
	(int * int * book_t list) Lwt.t


(**	Finds all the books that match the given search criteria.  Note that if
	the given search criteria are not particularly stringent, this function
	can easily return hundreds of results and require several independent
	requests to Amazon's servers.  If you are only interested in the most
	relevant results, then function {!find_some_books} is more appropriate.
*)
val find_all_books:
	?service:string ->
	?version:string ->
	credential:credential_t ->
	criteria_t ->
	book_t list Lwt.t


(**	Returns the book that matches the given ISBN.  Note that it actually
	returns [Some book] if the book was retrievable and [None] otherwise.
*)
val book_from_isbn:
	?service:string ->
	?version:string ->
	credential:credential_t ->
	ISBN.t ->
	book_t option Lwt.t


(**	Similar to {!book_from_isbn}, but raises an exception if the book
	was not found or if an error occurred during the operation.
*)
val book_from_isbn_exn:
	?service:string ->
	?version:string ->
	credential:credential_t ->
	ISBN.t ->
	book_t Lwt.t

