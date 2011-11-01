(********************************************************************************)
(*	Bookaml_amazon_ocamlnet.mli
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

(**	Implementation of {!Bookaml_amazon.ENGINE} using Xml-light for XML
	parsing and Ocamlnet's [Http_client] for HTTP requests.
*)
include Bookaml_amazon.ENGINE with type 'a monad = 'a

