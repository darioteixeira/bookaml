(********************************************************************************)
(*  Bookaml_amazon_ocsigen.mli
    Copyright (c) 2010-2015 Dario Teixeira <dario.teixeira@nleyten.com>
    This software is distributed under the terms of the GNU GNU LGPL 2.1
    with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

(** Implementation of {!Bookaml_amazon.ENGINE} using Ocsigen's
    [Simplexmlparser] and [Ocsigen_http_client] as backends.
*)
include Bookaml_amazon.ENGINE with type 'a monad = 'a Lwt.t

