(********************************************************************************)
(*	Bookaml_book.ml
	Copyright (c) 2010-2015 Dario Teixeira <dario.teixeira@nleyten.com>
	This software is distributed under the terms of the GNU GNU LGPL 2.1
	with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)


(********************************************************************************)
(**	{1 Type definitions}							*)
(********************************************************************************)

type price_t =
	{
	amount: int;
	currency: string;
	formatted: string;
	}


type image_t =
	{
	url: string;
	width: int;
	height: int;
	}


type t =
	{
	isbn10: [ `ISBN10 ] Bookaml_ISBN.t option;
	isbn13: [ `ISBN13 ] Bookaml_ISBN.t;
	title: string;
	author: string option;
	publisher: string option;
	pubdate: string option;
	page: string option;
	list_price: price_t option;
	price_new: price_t option;
	price_used: price_t option;
	price_collectible: price_t option;
	price_refurbished: price_t option;
	image_small: image_t option;
	image_medium: image_t option;
	image_large: image_t option;
	}

