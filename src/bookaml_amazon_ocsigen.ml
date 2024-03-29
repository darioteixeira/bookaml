open Lwt
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
        include Lwt

        let list_map = Lwt_list.map_p
    end

    let perform_request ~host request =
        Ocsigen_http_client.get ~host ~uri:request () >>= fun frame ->
        match frame.Ocsigen_http_frame.frame_content with
            | Some stream ->
                let buf = Buffer.create 4096 in
                let rec string_of_stream stream = match%lwt Ocsigen_stream.next stream with
                    | Ocsigen_stream.Cont (str, stream)     -> Buffer.add_string buf str; string_of_stream stream
                    | Ocsigen_stream.Finished (Some stream) -> string_of_stream stream
                    | Ocsigen_stream.Finished None          -> Lwt.return (Buffer.contents buf) in
                string_of_stream (Ocsigen_stream.get stream) >>= fun result ->
                Ocsigen_stream.finalize stream `Success >>
                Lwt.return result
            | None ->
                Lwt.fail No_response
end


(********************************************************************************)
(** {1 Public functions and values}                                             *)
(********************************************************************************)

include Make (Xmlhandler) (Httpgetter)

