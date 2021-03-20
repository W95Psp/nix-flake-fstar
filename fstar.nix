{ stdenv, lib, pkgs, fetchFromGitHub
, ocamlPackages, makeWrapper, z3
  
, src, name, patches ? []
}:
stdenv.mkDerivation rec {
  inherit name src patches;
  
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = with ocamlPackages; [
    z3 ocaml

    # Following F*'s INSTALL.md 
    ocamlbuild findlib batteries stdint
    zarith yojson fileutils pprint menhir
    ppx_deriving ppx_deriving_yojson process
    ocaml-migrate-parsetree

    sedlex_2
  ];
  makeFlags = [ "PREFIX=$(out)" ];
  preBuild = ''echo "echo ${lib.escapeShellArg name}" > src/tools/get_commit
               patchShebangs src/tools
               patchShebangs ulib # for `gen_mllib.sh`
               patchShebangs bin
               makeFlagsArray+=( OTHERFLAGS="--admit_smt_queries true" )
             '';
  postBuild = '''';
  preInstall = ''mkdir -p $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstarlib'';
  installFlags = "-C src/ocaml-output";
  postInstall = ''
          mkdir -p $out/ulib/; cp -rv ./ulib/ $out/
          wrapProgram $out/bin/fstar.exe --prefix PATH ":" "${lib.getBin z3}/bin"
          ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstar-tactics-lib  $out/bin/fstar-tactics-lib
          ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstarlib           $out/bin/fstarlib
          ln -s $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/fstar-compiler-lib $out/bin/fstar-compiler-lib
      '';
}

