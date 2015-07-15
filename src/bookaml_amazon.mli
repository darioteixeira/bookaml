(********************************************************************************)
(*  Bookaml_amazon.mli
    Copyright (c) 2010-2015 Dario Teixeira <dario.teixeira@nleyten.com>
    This software is distributed under the terms of the GNU LGPL 2.1
    with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

(** Module providing facilities for finding information about books.
    It works by invoking the Amazon Product Advertising API, and therefore
    most of its functions require the associate tag, access key, and secret
    key available to registered users of Amazon Web Services.
*)

(********************************************************************************)
(** {1 Exceptions}                                                              *)
(********************************************************************************)

exception No_response
exception No_match of Bookaml_isbn.t


(********************************************************************************)
(** {1 Inner modules}                                                           *)
(********************************************************************************)

(** Definition of the various supported Amazon locales.
*)
module Locale:
sig
    type t =
        [ `BR   (** Brazil *)
        | `CA   (** Canada *)
        | `CN   (** China *)
        | `DE   (** Germany *)
        | `ES   (** Spain *)
        | `FR   (** France *)
        | `IN   (** India *)
        | `IT   (** Italy *)
        | `JP   (** Japan *)
        | `UK   (** United Kingdom *)
        | `US   (** United States *)
        ] with sexp

    val of_string: string -> t
    val to_string: t -> string
end


(********************************************************************************)
(** {1 Type definitions}                                                        *)
(********************************************************************************)

(** Credential for Amazon Web Services.
*)
type credential_t =
    {
    locale: Locale.t;
    associate_tag: string;
    access_key: string;
    secret_key: string;
    } with sexp


(** Search criteria expected by some {!ENGINE} functions.  The search criteria
    must be created beforehand by function {!make_criteria}.
*)
type criteria_t with sexp


(********************************************************************************)
(** {1 Public functions and values}                                             *)
(********************************************************************************)

(** Constructs the AWS credential that is required for {!ENGINE} functions.
*)
val make_credential:
    locale: Locale.t ->
    associate_tag: string ->
    access_key: string ->
    secret_key: string ->
    credential_t


(** Constructs the search criteria that may be given to {!ENGINE} functions.
    The search criteria may consist of any combination of [title], [author],
    [publisher], or generic [keywords].  If none are specified, exception
    [Invalid_arg] is raised.
*)
val make_criteria:
    ?title:string ->
    ?author:string ->
    ?publisher:string ->
    ?keywords:string ->
    unit ->
    criteria_t


(********************************************************************************)
(** {1 Public module types}                                                     *)
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
    (** It makes sense to wrap in a monadic system such as [Lwt] those functions
        that may take some time to complete.  If that is the case, then any module
        that implements this signature should be declared as having module type
        [Bookaml_amazon.ENGINE with type 'a monad_t = 'a Lwt.t].  Nevertheless,
        for the sake of flexibility we do not actually mandate that [Lwt] be used,
        and hence why this abstract type ['a monad_t] exists.  It is in fact possible
        for the implementation to use no monad-based system at all, in which case the
        identity monad may be declared: [Bookaml_amazon.ENGINE with type 'a monad_t = 'a].
    *)
    type 'a monad_t


    (** Finds some of the books that match the given search criteria.  The result
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
        credential:credential_t ->
        criteria_t ->
        (int * int * Bookaml_book.t list) monad_t


    (** Finds all the books that match the given search criteria.  Note that if
        the given search criteria are not particularly stringent, this function
        can easily return hundreds of results and require several independent
        requests to Amazon's servers.  If you are only interested in the most
        relevant results, then function {!find_some_books} is more appropriate.
    *)
    val find_all_books:
        credential:credential_t ->
        criteria_t ->
        Bookaml_book.t list monad_t


    (** Returns the book that matches the given ISBN.  Note that it actually
        returns [Some book] if the book was retrievable and [None] otherwise.
    *)
    val book_from_isbn:
        credential:credential_t ->
        Bookaml_isbn.t ->
        Bookaml_book.t option monad_t


    (** Similar to {!book_from_isbn}, but raises an exception if the book
        was not found or if an error occurred during the operation.
    *)
    val book_from_isbn_exn:
        credential:credential_t ->
        Bookaml_isbn.t ->
        Bookaml_book.t monad_t
end


(********************************************************************************)
(** {1 Public functors}                                                         *)
(********************************************************************************)

module Make:
    functor (Xmlhandler: XMLHANDLER) ->
    functor (Httpgetter: HTTPGETTER) ->
    ENGINE with type 'a monad_t = 'a Httpgetter.Monad.t

