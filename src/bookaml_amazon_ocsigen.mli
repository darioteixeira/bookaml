(********************************************************************************)
(*	Bookaml_amazon_ocsigen.mli
	Copyright (c) 2010-2011 Dario Teixeira (dario.teixeira@yahoo.com)
	This software is distributed under the terms of the GNU GPL version 2.
	See LICENSE file for full license text.
*)
(********************************************************************************)

include Bookaml_amazon.S with type 'a monad_t = 'a Lwt.t

