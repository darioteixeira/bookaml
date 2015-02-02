(********************************************************************************)
(*	Bookaml_amazon_ocamlnet.mli
	Copyright (c) 2010-2014 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GNU LGPL 2.1
	with OCaml linking exception.  See LICENSE file for full license text.
*)
(********************************************************************************)

(**	Implementation of {!Bookaml_amazon.ENGINE} using Xml-light for XML
	parsing and Ocamlnet's [Http_client] for HTTP requests.
*)
include Bookaml_amazon.ENGINE with type 'a monad_t = 'a

