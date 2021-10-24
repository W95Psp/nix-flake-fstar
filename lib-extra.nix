{ fstar-nixlib, pkgs, z3 }:

{
#   build-compiler-lib-cmxs =
#     { src, name
#     , keep_src ? false, patches ? []
#     , existing-fstar ? fstar-nixlib.binary-of-ml-snapshot {inherit src name; keep_src = true; withlibs = false;}
#     }:
#     let
#       makefile-patch = pkgs.writeText "makefile-patch" ''
# COMPILER_LIB_INCLUDES=src/ocaml-output \
# 	src/basic/ml \
# 	src/parser/ml \
# 	src/fstar/ml \
# 	src/extraction/ml \
# 	src/prettyprint/ml \
# 	src/tactics/ml \
# 	src/tests/ml \
# 	ulib/ml/extracted \
# 	ulib/ml 
# 	# ulib/experimental/ml \

# COMPILER_LIB_INCLUDES_FLAGS := $(addprefix -I , $(COMPILER_LIB_INCLUDES))

# fstar-compiler-lib.mllib: $(FSTAR_MAIN_NATIVE)
# 	../../ulib/gen_mllib.sh . $(addprefix ../../, $(COMPILER_LIB_INCLUDES)) | sed '/FStar_Main/d' | sed '/FStar_Tests/d' | sed '/FStar_Tactics_Load/d' > fstar-compiler-lib.mllib

# compiler-lib-cmx: $(FSTAR_MAIN_NATIVE) fstar-compiler-lib.mllib
# 	rm ../../ulib/ml/extracted/FStar_Pervasives.* || true
# 	# mv ../../src/tactics/ml/FStar_Tactics_Load.ml ../../src/tactics/ml/FStar_Tactics_Load.ml.hidden
# 	# mv ../../src/tactics/ml/FStar_Tactics_Load.ml ../../src/tactics/ml/FStar_Tactics_Load.ml.hidden
# 	# mv ../../src/fstar/ml/main.ml ../../src/fstar/ml/main.ml.hidden
# 	# rm ../../src/fstar/ml/main.ml
# 	rm ../../src/fstar/ml/main.ml
# 	rm get_branch.ml
# 	rm parse.mly
# 	rm FStar_Main.ml
# 	$(OCAMLBUILD) $(COMPILER_LIB_INCLUDES_FLAGS) fstar-compiler-lib.a fstar-compiler-lib.cma fstar-compiler-lib.cmxs fstar-compiler-lib.cmxa
# 	# mv ../../src/tactics/ml/FStar_Tactics_Load.ml.hidden ../../src/tactics/ml/FStar_Tactics_Load.ml
# 	# mv ../../src/fstar/ml/main.ml.hidden ../../src/fstar/ml/main.ml

# install-compiler-lib-patched: $(FSTAR_MAIN_NATIVE) compiler-lib-cmx
# 	mkdir -p ../../bin/fstar-compiler-lib/
# 	@# VD: forcing the recompilation of modules in ulib/tactics_ml whenever the compiler is rebuilt
# 	@# in order to avoid inconsistent assumption errors between fstartaclib and compiler-lib
# 	$(FIND) ../../ulib/tactics_ml \( -name '*.cmi' -or -name '*.cmx' \) -exec rm {} \;
# 	$(FIND) . \( -name '*.cmi' -or -name '*.cmx' -or -name '*.a' -or -name '*.cma' -or -name '*.cmxs' -or -name '*.cmxa' \) -exec cp {} ../../bin/fstar-compiler-lib/ \;
# 	sed "s/__FSTAR_VERSION__/$$(cat ../../version.txt)/" <../../ulib/ml/fstar-compiler-lib-META >../../bin/fstar-compiler-lib/META
# 	touch $@
#       '';
#     in
#       pkgs.stdenv.mkDerivation {
#         name = "${name}-with-compiler-lib-cmxs";
#         src = (fstar-nixlib.build {inherit src name existing-fstar patches; keep_src = true;}).overrideAttrs (_: {
#           withlibs = true;
#           installPhase = "mkdir $out; cp -r --no-preserve=mode . $out";
#         });
#         buildPhase = "true";
#         buildInputs = fstar-nixlib.buildInputs ++ [pkgs.makeWrapper];
#         installPhase = ''
#           chmod +x ulib/gen_mllib.sh
#           cd src/ocaml-output
#           cat ${makefile-patch} >> Makefile
#           make install-compiler-lib-patched
#           cd ../..
          
#           echo 'archive(byte) = "fstartaclib.cma"' >> bin/fstar-tactics-lib/META
#           echo 'archive(native) = "fstartaclib.cmxa"' >> bin/fstar-tactics-lib/META
          
#           echo 'name="fstar-compiler-lib"' > bin/fstar-compiler-lib/META
#           echo 'version="__FSTAR_VERSION__"' >> bin/fstar-compiler-lib/META
#           echo 'description="FStar compiler"' >> bin/fstar-compiler-lib/META
#           echo 'requires="batteries,compiler-libs,compiler-libs.common,dynlink,pprint,stdint,yojson,zarith,ppxlib,ppx_deriving_yojson,ppx_deriving_yojson.runtime,menhirLib"' >> bin/fstar-compiler-lib/META
          
#           echo 'archive(byte) = "fstar-compiler-lib.cma"' >> bin/fstar-compiler-lib/META
#           echo 'archive(native) = "fstar-compiler-lib.cmxa"' >> bin/fstar-compiler-lib/META

#           chmod +x bin/fstar.exe
#           ${fstar-nixlib.binary-installPhase {inherit keep_src; withlibs = true;}}
#         '';
#       };
}

  # prefer-debug-bytecode = sd-cli: der:
  #   der.overrideAttrs ({preBuild, ...}:
  #     { preBuild = ''
  #         ${sd-cli}/bin/sd -s '.native' '.d.byte' src/ocaml-output/Makefile
  #         ${preBuild}
  #       '';
  #     });
