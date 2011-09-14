#
# Makefile for Bookaml
#

PKG_NAME=bookaml
SRC_DIR=src
LIB_DIR=src/_build
OCAMLBUILD_OPTS=-no-links -use-ocamlfind

LIB_FILES=bookaml.cma bookaml.cmxa bookaml.cmxs bookaml.a
COMPONENTS=ISBN bookaml_amazon

COMPONENTS_MLI=$(foreach ELEM, $(COMPONENTS), $(ELEM).mli)
COMPONENTS_CMI=$(foreach ELEM, $(COMPONENTS), $(ELEM).cmi)
COMPONENTS_CMO=$(foreach ELEM, $(COMPONENTS), $(ELEM).cmo)
COMPONENTS_CMX=$(foreach ELEM, $(COMPONENTS), $(ELEM).cmx)
COMPONENTS_OBJ=$(foreach ELEM, $(COMPONENTS), $(ELEM).o)

LIB_TARGETS=$(LIB_FILES) $(COMPONENTS_CMI) $(COMPONENTS_CMO) $(COMPONENTS_CMX) $(COMPONENTS_OBJ)
SRC_TARGETS=$(COMPONENTS_MLI)
FQ_LIB_TARGETS=$(foreach TARGET, $(LIB_TARGETS), $(LIB_DIR)/$(TARGET))
FQ_SRC_TARGETS=$(foreach TARGET, $(SRC_TARGETS), $(SRC_DIR)/$(TARGET))
TARGETS= $(FQ_LIB_TARGETS) $(FQ_SRC_TARGETS)


#
# Rules
#

all: lib

lib:
	cd $(SRC_DIR) && ocamlbuild $(OCAMLBUILD_OPTS) bookaml.otarget

apidoc:
	cd $(SRC_DIR) && ocamlbuild $(OCAMLBUILD_OPTS) bookaml.docdir/index.html

install: lib
	ocamlfind install $(PKG_NAME) META $(TARGETS)

uninstall:
	ocamlfind remove $(PKG_NAME)

reinstall:
	ocamlfind remove $(PKG_NAME)
	ocamlfind install $(PKG_NAME) META $(TARGETS)

clean:
	cd $(SRC_DIR) && ocamlbuild $(OCAMLBUILD_OPTS) -clean

