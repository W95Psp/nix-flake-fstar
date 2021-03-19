pkgs: {
  prefer-debug-bytecode = der:
    der.overrideAttrs ({preBuild, ...}:
      { preBuild = ''
          ${pkgs.sd}/bin/sd -s '.native' '.d.byte' src/ocaml-output/Makefile
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
}
