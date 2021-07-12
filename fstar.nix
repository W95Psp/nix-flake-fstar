{ stdenv, lib, pkgs, fetchFromGitHub
, ocamlPackages, makeWrapper, z3

, enable_sedlex ? true
, keep_src ? false
, bootstrap-with ? null

, src, name, patches ? []
}:

let
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = with ocamlPackages; [
    z3 ocaml

    # Following F*'s INSTALL.md 
    ocamlbuild findlib batteries stdint
    zarith yojson fileutils pprint menhir
    ppx_deriving ppx_deriving_yojson process
    ocaml-migrate-parsetree
  ] ++ (if enable_sedlex then [sedlex_2] else [ulex camlp4]);
  preBuild = ''
    echo "echo ${lib.escapeShellArg name}" > src/tools/get_commit
    patchShebangs src/tools
    patchShebangs ulib # for `gen_mllib.sh`
    patchShebangs bin'';
  installLibs = ''
    cp -rv bin/fstar-tactics-lib  $out/bin/fstar-tactics-lib
    cp -rv bin/fstarlib           $out/bin/fstarlib
    cp -rv bin/fstar-compiler-lib $out/bin/fstar-compiler-lib
    ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstar-tactics-lib  $out/bin/fstar-tactics-lib
    ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstarlib           $out/bin/fstarlib
    ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstar-compiler-lib $out/bin/fstar-compiler-lib
  '';
  installPhase = ''
    mkdir -p $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstarlib
    mkdir -p $out/ulib/ $out/bin/
    cp bin/fstar.exe $out/bin/fstar.exe
    cp -rv ./ulib/ ${if keep_src then "./src/" else ""} $out/
    wrapProgram $out/bin/fstar.exe --prefix PATH ":" "${lib.getBin z3}/bin"
  '';
  buildOCaml = withlibs: src: stdenv.mkDerivation {
    inherit name src patches nativeBuildInputs buildInputs;
    
    buildPhase = ''${preBuild}
                   make ${if withlibs then "" else "1"} -j6'';

    installPhase = ''${installPhase}${if withlibs then installLibs else ""}'';
  };
  extractFStar = existing-fstar: stdenv.mkDerivation {
    inherit name src patches nativeBuildInputs; # buildInputs;

    buildInputs = buildInputs ++ [pkgs.which];
    
    buildPhase = ''echo "#!/usr/bin/env bash" > bin/fstar-any.sh
                   echo "\"${existing-fstar}/bin/fstar.exe\" \"\$@\"" >> bin/fstar-any.sh
                   ${preBuild}
                   make ocaml -C src -j6'';

    installPhase = ''cp -r . $out'';
  };
in
# buildOCaml false src
buildOCaml true (extractFStar (if isNull bootstrap-with then buildOCaml false src else bootstrap-with))

