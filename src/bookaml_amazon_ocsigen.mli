(** Implementation of {!Bookaml_amazon.ENGINE} using Ocsigen's
    [Simplexmlparser] and [Ocsigen_http_client] as backends.
*)
include Bookaml_amazon.ENGINE with type 'a monad = 'a Lwt.t

