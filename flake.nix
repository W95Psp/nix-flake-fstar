{
  description = "F* flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    fstar-source = {
      url = "github:FStarLang/FStar";
      flake = false;
    };
  };
  
  outputs = { self, nixpkgs, flake-utils, fstar-source }:
    let
      z3 = pkgs: pkgs.z3.overrideAttrs (_: rec {
        version = "4.8.5";
        src = pkgs.fetchFromGitHub {
          owner  = "Z3Prover";
          repo   = "z3";
          rev    = "Z3-${version}";
          sha256 = "11sy98clv7ln0a5vqxzvh6wwqbswsjbik2084hav5kfws4xvklfa";
        };
      });
      fstar = pkgs:
        pkgs.callPackage ./fstar.nix {
          src = fstar-source;
          name = "fstar-${fstar-source.rev}";
          z3 = z3 pkgs;
        };
    in
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux"]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          lib = pkgs.lib;
        in  
          rec {
            packages = {
              fstar = fstar pkgs;
              z3 = z3 pkgs;
            };
            lib = {
              fstar = import ./lib.nix;
            };
            defaultPackage = packages.fstar;
          }
      ) // {
        overlay = final: prev: {
          fstar = fstar prev;
          z3 = z3 prev;
        };
      };
}
