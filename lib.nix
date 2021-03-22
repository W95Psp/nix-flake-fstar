{
  prefer-debug-bytecode = sd-cli: der:
    der.overrideAttrs ({preBuild, ...}:
      { preBuild = ''
          ${sd-cli}/bin/sd -s '.native' '.d.byte' src/ocaml-output/Makefile
          ${preBuild}
        '';
      });
  perform-fstar-to-ocaml = fstarBinary: der:
    der.overrideAttrs ({preBuild, postBuild, ...}:
      { preBuild = ''${preBuild}
          cp --no-preserve=mode ${fstarBinary}/bin/fstar.exe ./bin/fstar.exe
          chmod +x ./bin/fstar.exe
          make -C src clean_extracted OTHERFLAGS="--admit_smt_queries true"
          make -C src fstar-ocaml OTHERFLAGS="--admit_smt_queries true"
        '';
        postBuild = ''${postBuild}
          make -C ulib install-fstarlib OTHERFLAGS="--admit_smt_queries true"
          make -C ulib install-fstar-tactics OTHERFLAGS="--admit_smt_queries true"
        '';
      });
  use-ulex = nixpkgs: pkgs: der:
    let
      ocaml = import "${nixpkgs}/pkgs/development/compilers/ocaml/4.08.nix"
        { inherit (pkgs) stdenv fetchurl ncurses buildEnv libunwind;
          libX11 = pkgs.xorg.libX11;
          xorgproto = pkgs.xorg.xorgproto;
        };
      ocamlPackages = pkgs.ocamlPackages.overrideScope' (self': super: {
        ocaml = ocaml;
      });
    in
      der.override {
        inherit ocamlPackages;
        enable_sedlex = false;
      };

  # run-script-with-revision = revision
}
