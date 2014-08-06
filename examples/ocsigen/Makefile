all: module.cma

module.cma: test.cmo
	ocamlc -a -o $@ $+

test.cmo: test.ml
	ocamlfind ocamlc -thread -package lwt,eliom.server,bookaml.ocsigen -c $<

clean:
	rm -f *.cm[ioax] *.cmx[as] *.[oa]

