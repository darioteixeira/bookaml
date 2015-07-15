(********************************************************************************)
(*  Bookaml_isbn.mli
    Copyright (c) 2010-2015 Dario Teixeira <dario.teixeira@nleyten.com>
    This software is distributed under the terms of the GNU GNU LGPL 2.1
    with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

(** Module encapsulating ISBNs.  It takes advantage of the check digit to make
    sure that any given ISBN is correct.  It supports both 10 and 13-digit ISBNs.
*)

(********************************************************************************)
(** {1 Exceptions}                                                              *)
(********************************************************************************)

exception Bad_ISBN_length of string
exception Bad_ISBN_checksum of string
exception Bad_ISBN_character of char


(********************************************************************************)
(** {1 Type definitions}                                                        *)
(********************************************************************************)

(** The type of valid ISBN numbers.
*)
type t with sexp


(********************************************************************************)
(** {1 Public functions and values}                                             *)
(********************************************************************************)

(********************************************************************************)
(** {2 Conversion to/from strings}                                              *)
(********************************************************************************)

(** Converts a string into an ISBN, represented by type {!t}.  Raises
    an exception if the string cannot be converted into a valid ISBN.
    Both 10 and 13-digit ISBNs are accepted.  Moreover, the string may
    contain dashes, which are automatically removed if present.
*)
val of_string: string -> t

(** Returns a string representation of the ISBN.  The same type of ISBN
    (10 or 13-digit) originally used to construct the value is returned,
    but without any dashes.
*)
val to_string: t -> string

(** Returns a string with the 10-digit ISBN representation of {!t}.
    Since it is not always possible to construct a 10-digit ISBN from
    a 13-digit one, the function may return [None].
*)
val to_string10: t -> string option

(** Returns a string with the 13-digit ISBN representation of {!t}.
    Note that it is always possible to build a 13-digit ISBN.
*)
val to_string13: t -> string


(********************************************************************************)
(** {2 Validity checks}                                                         *)
(********************************************************************************)

(** Does the given string represent a valid ISBN number?  Both 10 and 13-digit
    ISBNs are accepted.  Moreover, the string may contain dashes, which are
    automatically removed if present.
*)
val is_valid: string -> bool

(** Does the given string represent a valid 10-digit ISBN number?
    The string may contain dashes, which are automatically removed if present.
*)
val is_valid10: string -> bool

(** Does the given string represent a valid 13-digit ISBN number?
    The string may contain dashes, which are automatically removed if present.
*)
val is_valid13: string -> bool

