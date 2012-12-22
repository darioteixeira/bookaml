(********************************************************************************)
(*	Bookaml_ISBN.mli
	Copyright (c) 2010-2012 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

(**	Module encapsulating ISBNs.  It makes sure that any given ISBN is
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
type +'a t constraint 'a = [< `ISBN10 | `ISBN13 ]


(**	The PGOCAML-compatible type used for (de)serialising values of type {!t}
*)
type pg_t = string


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

(********************************************************************************)
(**	{2 Conversion to/from strings}						*)
(********************************************************************************)

(**	Converts a string into an ISBN, represented by type {!t}.  Raises
	[Invalid_arg] if the string cannot be converted into a valid ISBN.
	Both 10 and 13-digit ISBNs are accepted.  Moreover, the string may
	contain dashes, which are automatically removed if present.
*)
val of_string: string -> [> `ISBN10 | `ISBN13 ] t


(**	Converts a string containing a 10-digit ISBN into {!t}.
*)
val of_string10: string -> [> `ISBN10 ] t


(**	Converts a string containing a 13-digit ISBN into {!t}.
*)
val of_string13: string -> [> `ISBN13 ] t


(**	Converts a {!t} (representing an ISBN) into a string.
*)
val to_string: [< `ISBN10 | `ISBN13 ] t -> string


(********************************************************************************)
(**	{2 Conversion to/from 10 and 13-digit ISBNs}				*)
(********************************************************************************)

(**	Converts a given {!t} into a 10-digit ISBN.  If the supplied ISBN is
	already a 10-digit ISBN then it's returned unchanged.  If the supplied
	ISBN is a backwards-compatible 13-digit ISBN (it starts with "978"),
	then it is converted.  Otherwise, the conversion is not possible and
	[None] is returned.
*)
val to_10: [< `ISBN10 | `ISBN13 ] t -> [> `ISBN10 ] t option


(**	Converts a given {!t} into a 13-digit ISBN.  If the supplied ISBN is
	already a 13-digit ISBN then it's returned unchanged.  If the supplied
	ISBN is a 10-digit ISBN then it's converted by prepending a "978" and
	recomputing the check digit.
*)
val to_13: [< `ISBN10 | `ISBN13 ] t -> [> `ISBN13 ] t


(********************************************************************************)
(**	{2 Conversion to/from strings}						*)
(********************************************************************************)

(**	Deserialises from a PGOCAML-compatible format.
*)
val of_pg: pg_t -> [> `ISBN10 | `ISBN13 ] t


(**	Deserialises from a PGOCAML-compatible format.
	Should only be used for 10-digit ISBNs.
*)
val of_pg10: pg_t -> [> `ISBN10 ] t


(**	Deserialises from a PGOCAML-compatible format.
	Should only be used for 13-digit ISBNs.
*)
val of_pg13: pg_t -> [> `ISBN13 ] t


(**	Serialises into a PGOCAML-compatible format.
*)
val to_pg: [< `ISBN10 | `ISBN13 ] t -> pg_t


(********************************************************************************)
(**	{2 Validity checks}							*)
(********************************************************************************)

(**	Does the given string represent a valid ISBN number?  Both 10 and 13-digit
	ISBNs are accepted.  Moreover, the string may contain dashes, which are
	automatically removed if present.
*)
val is_valid: string -> bool


(**	Does the given string represent a valid 10-digit ISBN number?
*)
val is_valid10: string -> bool


(**	Does the given string represent a valid 13-digit ISBN number?
*)
val is_valid13: string -> bool


(********************************************************************************)
(**	{2 Identity checks}							*)
(********************************************************************************)

(**	Is the given {!t} a 10-digit ISBN?
*)
val is_10: [< `ISBN10 | `ISBN13 ] t -> bool


(**	Is the given {!t} a 13-digit ISBN?
*)
val is_13: [< `ISBN10 | `ISBN13 ] t -> bool

