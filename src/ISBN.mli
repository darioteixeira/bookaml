(********************************************************************************)
(*	ISBN.mli
	Copyright (c) 2010 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

(**	This module encapsulates ISBNs.  It makes sure that any given ISBN is
	correct, taking advantage of the check digit present in every ISBN.
	It supports both 10 and 13-digit ISBNs.
*)

(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception Bad_ISBN_length of string
exception Bad_ISBN_checksum of string
exception Bad_ISBN_character of char


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

(**	The type of valid ISBN numbers.
*)
type t with sexp


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

(**	Converts a string into an ISBN, represented by type {!t}.  Raises
	[Invalid_arg] if the string cannot be converted into a valid ISBN.
	Both 10 and 13-digit ISBNs are accepted.  Moreover, the string may
	contain dashes, which are automatically removed if present.
*)
val of_string: string -> t


(**	Converts a {!t} (representing an ISBN) into a string.
*)
val to_string: t -> string


(**	Does the given string represent a valid ISBN number?  Both 10 and 13-digit
	ISBNs are accepted.  Moreover, the string may contain dashes, which are
	automatically removed if present.
*)
val is_valid: string -> bool

