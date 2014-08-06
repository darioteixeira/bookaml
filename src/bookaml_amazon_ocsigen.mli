(********************************************************************************)
(*	Bookaml_amazon_ocsigen.mli
	Copyright (c) 2010-2014 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

(**	Implementation of {!Bookaml_amazon.ENGINE} using Ocsigen's
	[Simplexmlparser] and [Ocsigen_http_client] as backends.
*)
include Bookaml_amazon.ENGINE with type 'a monad_t = 'a Lwt.t

