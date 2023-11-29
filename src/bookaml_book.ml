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

