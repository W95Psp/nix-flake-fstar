{
  description = "F* flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    fstar-source = {
      url = "github:FStarLang/FStar";
      flake = false;
    };
  };
  
  outputs = { self, nixpkgs, flake-utils, fstar-source, nixpkgs-unstable }:
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
      fstar = z3: pkgs:
        pkgs.callPackage ./fstar.nix {
          src = fstar-source;
          name = "fstar-${fstar-source.rev}";
          inherit z3;
        };
    in
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          unstable = nixpkgs-unstable.legacyPackages.${system};
          lib = pkgs.lib;
          z3 =
            if system == "aarch64-linux"
            then builtins.trace ''Warning: F* on aarch64 will use a recent, untested, z3 build.
This probably will result in verification failures.
See https://github.com/FStarLang/FStar/blob/master/INSTALL.md#runtime-dependency-particular-version-of-z3.'' unstable.z3
            else z3b pkgs;
        in  
          rec {
            packages = {
              fstar = fstar z3 pkgs;
              z3 = z3;
            };
            lib = {
              fstar = import ./lib.nix;
            };
            defaultPackage = packages.fstar;
          }
      ) // {
        overlay = final: prev: {
          fstar = fstar (z3b prev) prev;
          z3 = z3b prev;
        };
      };
}
