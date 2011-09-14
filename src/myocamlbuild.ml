(********************************************************************************)
(* Ocamlbuild plugin for Bookaml project.					*)
(********************************************************************************)

open Ocamlbuild_plugin


let _ = dispatch begin function

	| After_rules ->

		flag ["ocaml"; "pack"] (S[A"-I"; A"lib"]);

		flag ["ocaml"; "use_thread"; "compile"] (S[A "-thread"]);
		flag ["ocaml"; "use_thread"; "link"] (S[A "-thread"]);
		flag ["ocaml"; "use_thread"; "infer_interface"] (S[A "-thread"])

	| _ -> ()
end

