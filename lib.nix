{ ocamlPackages, mkDerivation, lib, makeWrapper, z3, which }:

let
  # TODO: we don't need z3 all the time
  buildInputs = with ocamlPackages; [
    z3 ocaml

    # Following F*'s INSTALL.md 
    ocamlbuild findlib batteries stdint zarith yojson fileutils pprint
    menhir ppx_deriving ppx_deriving_yojson process ocaml-migrate-parsetree
    sedlex_2
  ];
  preBuild = {name}: ''
    echo "echo ${lib.escapeShellArg name}" > src/tools/get_commit
    patchShebangs src/tools
    patchShebangs ulib # for `gen_mllib.sh`
    patchShebangs bin'';
  installLibs = ''
    mkdir -p $out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib
    for lib in fstar-tactics-lib fstarlib fstar-compiler-lib; do
        cp -r "bin/$lib" "$out/bin/$lib"
        ln -s "$out/bin/$lib" "$out/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib/$lib"
    done
  '';
  binary-installPhase = { keep_src ? false, withlibs ? true}: ''
    mkdir -p $out/ulib/ $out/bin/
    cp bin/fstar.exe $out/bin/fstar.exe
    cp -r ./ulib/ ${if keep_src then "./src/" else ""} $out/
    wrapProgram $out/bin/fstar.exe --prefix PATH ":" "${lib.getBin z3}/bin"
    ${if withlibs then installLibs else ""}
  '';
  binary-of-ml-snapshot =
    { src, name, keep_src ? false, withlibs ? true
    }: mkDerivation {
      inherit name src buildInputs;
      nativeBuildInputs = [ makeWrapper ];
      
      buildPhase = ''${preBuild {inherit name;}}
                     make ${if withlibs then "" else "1"} -j6'';
      installPhase = binary-installPhase {inherit keep_src withlibs;};
      meta.mainProgram = "fstar.exe";
    };
  ocaml-from-fstar = { src, name, existing-fstar, patches ? []
                     }: mkDerivation {
                       inherit name src patches;
                       
                       buildInputs = buildInputs ++ [which];
                   
                       buildPhase = ''
                         cd bin
                         test -f fstar-any.sh && { 
                             # we are before commit 6dbcdc1bce
                             rm fstar-any.sh
                             ln -s '${existing-fstar}/bin/fstar.exe' fstar-any.sh
                         }
                         ln -s '${existing-fstar}/bin/fstar.exe' fstar.exe
                         cd ..
                         ${preBuild {inherit name;}}
                         make ocaml -C src -j6
                       '';
                   
                       installPhase = ''cp -r . $out'';
                     };
  build =
    { src, name
    , keep_src ? false, withlibs ? true, patches ? []
    , existing-fstar ? binary-of-ml-snapshot {inherit src; name = "${name}-bin-from-snapshot"; keep_src = true; withlibs = false;}
    }:
    binary-of-ml-snapshot {
      inherit keep_src withlibs name;
      src = ocaml-from-fstar {name = "${name}-extracted-fstar"; inherit src existing-fstar patches;};
    } // {passthru = {inherit ocamlPackages;};};
in
{
  inherit build ocaml-from-fstar binary-of-ml-snapshot buildInputs
    binary-installPhase installLibs;
}

