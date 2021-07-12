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
  installPhase = ''
    mkdir -p $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstarlib
    mkdir -p $out/ulib/ $out/bin/
    cp bin/fstar.exe $out/bin/fstar.exe
    cp -rv ./ulib/ ${if keep_src then "./src/" else ""} $out/
    wrapProgram $out/bin/fstar.exe --prefix PATH ":" "${lib.getBin z3}/bin"
    ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstar-tactics-lib  $out/bin/fstar-tactics-lib
    ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstarlib           $out/bin/fstarlib
    ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstar-compiler-lib $out/bin/fstar-compiler-lib
  '';
  buildOCaml = with-ulib: src: stdenv.mkDerivation rec {
    inherit name src patches nativeBuildInputs buildInputs installPhase;
    
    buildPhase = ''${preBuild}
                   make ${if with-ulib then "" else "1"} -j6'';
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
buildOCaml true (extractFStar (if isNull bootstrap-with then buildOCaml false src else bootstrap-with))

