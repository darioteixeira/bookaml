(********************************************************************************)
(*	Bookaml_ISBN.ml
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

open ExtList
open ExtString


(********************************************************************************)
(**	{1 Exceptions}								*)
(********************************************************************************)

exception Bad_ISBN_length of string
exception Bad_ISBN_checksum of string
exception Bad_ISBN_character of char


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

type t = string

type pg_t = string


(********************************************************************************)
(**	{1 Private functions and values}					*)
(********************************************************************************)

(**	Returns the integer value corresponding to a given digit (as a character).
	Note that the "digits" 'X' and 'x' represent number 10.
*)
let value =
	let base = int_of_char '0' in
	function
		| '0' .. '9' as x -> (int_of_char x) - base
		| 'X' | 'x'	  -> 10
		| x		  -> raise (Bad_ISBN_character x)


(**	Checks whether a 10-digit ISBN is correct.  Note that
	this function expects to be given a 10 digit list.
*)
let check10 digits =
	let sum = List.fold_left (+) 0 (List.mapi (fun i x -> (10 - i) * (value x)) digits)
	in sum mod 11 = 0


(**	Checks whether a 13-digit ISBN is correct.  Note that
	this function expects to be given a 13 digit list.
*)
let check13 digits =
	let sum = List.fold_left (+) 0 (List.mapi (fun i x -> (if i mod 2 = 1 then 3 else 1) * (value x)) digits)
	in sum mod 10 = 0


(********************************************************************************)
(**	{1 Public functions and values}						*)
(********************************************************************************)

let of_string str =
	let digits = List.filter ((<>) '-') (String.explode str) in
	let checker = match List.length digits with
		| 10 -> check10
		| 13 -> check13
		| _  -> raise (Bad_ISBN_length str) in
	if checker digits
	then String.implode digits
	else raise (Bad_ISBN_checksum str)


external to_string: t -> string = "%identity"


external of_pg: pg_t -> t = "%identity"


external to_pg: t -> pg_t = "%identity"


let is_valid str =
	try ignore (of_string str); true
	with _ -> false

