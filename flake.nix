{
  description = "F* flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    fstar-source = {
      url = "github:FStarLang/FStar";
      flake = false;
    };
  };
  
  outputs = { self, nixpkgs, flake-utils, fstar-source }:
    let
      z3b = pkgs: pkgs.z3.overrideAttrs (_: rec {
        version = "4.8.5";
        src = pkgs.fetchFromGitHub {
          owner  = "Z3Prover";
          repo   = "z3";
          rev    = "Z3-${version}";
          sha256 = "11sy98clv7ln0a5vqxzvh6wwqbswsjbik2084hav5kfws4xvklfa";
        };
      });
      ocamlPackages = pkgs: pkgs.ocaml-ng.ocamlPackages_4_12;
      fstar-nixlib = z3: pkgs:
        pkgs.callPackage ./lib.nix {
          mkDerivation = pkgs.stdenv.mkDerivation;
          ocamlPackages = ocamlPackages pkgs;
          inherit z3;
          inherit (pkgs) lib makeWrapper which;
        };
    in
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          z3 =
            if system == "aarch64-linux"
            then builtins.trace ''Warning: F* on aarch64 will use a recent, untested, z3 build.
This probably will result in verification failures.
See https://github.com/FStarLang/FStar/blob/master/INSTALL.md#runtime-dependency-particular-version-of-z3.'' pkgs.z3
            else z3b pkgs;
        in  
          rec {
            packages = {
              fstar = pkgs.callPackage lib.fstar.build {src = fstar-source; name = "fstar-${fstar-source.rev}";};
              fstar-no-ulib = packages.fstar.override {withlibs = false;};
              z3 = z3;
              fstardoc = pkgs.stdenv.mkDerivation {
                name = "fstardoc";
                phases = ["installPhase"];
                installPhase = ''
                mkdir -p $out/bin && cd $out/bin
                ( echo "#! ${pkgs.python3}/bin/python3"
                  cat ${fstar-source}/.scripts/fstardoc/fstardoc.py
                ) > fstardoc
                chmod +x fstardoc
                '';
              };
            };
            lib = {
              fstar = fstar-nixlib z3 pkgs //
                      import ./lib-extra.nix {
                        inherit pkgs;
                        fstar-nixlib = fstar-nixlib z3 pkgs;
                        z3 = z3;
                      } // {
                        ocamlPackages = ocamlPackages pkgs;
                      };
            };
            defaultPackage = packages.fstar;
          }
      ) // {
        overlay = final: prev: {
          fstar = fstar-nixlib (z3b prev) prev {src = fstar-source; name = "fstar-${fstar-source.rev}";};
          z3 = z3b prev;
        };
      };
}
