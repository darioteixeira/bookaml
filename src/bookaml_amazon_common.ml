(********************************************************************************)
(*	Bookaml_amazon_common.ml
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

open ExtList


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

