(** Implementation of {!Bookaml_amazon.ENGINE} using Xml-light for XML
    parsing and Ocamlnet's [Http_client] for HTTP requests.
*)
include Bookaml_amazon.ENGINE with type 'a monad = 'a

