(********************************************************************************)
(*  Bookaml_book.mli
    Copyright (c) 2010-2015 Dario Teixeira <dario.teixeira@nleyten.com>
    This software is distributed under the terms of the GNU GNU LGPL 2.1
    with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

(** Basic definitions concerning books.
*)

(********************************************************************************)
(** {1 Type definitions}                                                        *)
(********************************************************************************)

type price =
    {
    amount: int;
    currency: string;
    formatted: string;
    }


type image =
    {
    url: string;
    width: int;
    height: int;
    }


type t =
    {
    isbn: Bookaml_isbn.t;
    title: string;
    author: string option;
    publisher: string option;
    pubdate: string option;
    page: string option;
    list_price: price option;
    price_new: price option;
    price_used: price option;
    price_collectible: price option;
    price_refurbished: price option;
    image_small: image option;
    image_medium: image option;
    image_large: image option;
    }

