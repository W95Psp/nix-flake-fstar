{
  description = "F* flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    fstar-master-source = {
      url = "github:FStarLang/FStar";
      flake = false;
    };
  };
  
  outputs = { self, nixpkgs, flake-utils, fstar-master-source }:
    let
      fstar-master = pkgs:
        pkgs.callPackage ./. {
          src = fstar-master-source;
          name = "fstar-master";
          z3 = pkgs.z3.overrideAttrs (_: rec {
            version = "4.8.5";
            src = pkgs.fetchFromGitHub {
              owner  = "Z3Prover";
              repo   = "z3";
              rev    = "Z3-${version}";
              sha256 = "11sy98clv7ln0a5vqxzvh6wwqbswsjbik2084hav5kfws4xvklfa";
            };
          });
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
              fstar = fstar-master pkgs;
            };
            defaultPackage = packages.fstar;
          }
      ) // {
        overlay = final: prev: {
          fstar = fstar-master prev;
        } // import ./tools final;
      };
}