(********************************************************************************)
(*  Bookaml_amazon_ocsigen.ml
    Copyright (c) 2010-2015 Dario Teixeira <dario.teixeira@nleyten.com>
    This software is distributed under the terms of the GNU GNU LGPL 2.1
    with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

open Bookaml_amazon

module List = BatList


(********************************************************************************)
(** {1 Private modules}                                                         *)
(********************************************************************************)

module Xmlhandler =
struct
    open Simplexmlparser

    type xml = Simplexmlparser.xml

    let parse = Simplexmlparser.xmlparser_string

    let xfind_all forest tag =
        let is_tag = function
            | Element (x, _, children) when x = tag -> Some children
            | _                                     -> None
        in List.filter_map is_tag forest


    let xfind_one forest tag = match xfind_all forest tag with
        | hd :: _ -> hd
        | []      -> raise Not_found


    let rec xget = function
        | (PCData x) :: [] -> x
        | (PCData x) :: tl -> x ^ (xget tl)
        | _                -> raise Not_found
end


module Httpgetter =
struct
    module Monad =
    struct
        type 'a t = 'a

        let return x = x
        let fail x = raise x
        let bind t f = f t
        let list_map = List.map
    end

    let perform_request ~host request =
        let dst = "http://" ^ host ^ request in
        let pipeline = new Nethttp_client.pipeline in
        let request = new Nethttp_client.get dst in
        let () = pipeline#add request in
        let () = pipeline#run () in
        request#response_body#value
end


(********************************************************************************)
(** {1 Public functions and values}                                             *)
(********************************************************************************)

include Make (Xmlhandler) (Httpgetter)

