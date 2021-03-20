# Nix Flake for F*

## Get a shell with F*
`nix develop "github:W95Psp/nix-flake-fstar"`

## Custom version F* or with custom patches
TODO check the following + add input instead of fetchFromGithub
```nix
{
  description = "F* flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
    fstar-flake.url = "github:W95Psp/nix-flake-fstar";
  };
  
  outputs = { self, nixpkgs, flake-utils, fstar-flake }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux"]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fstar = fstar-flake.defaultPackage.${system};
          tools = fstar-flake.lib.${system}.fstar;
          lib = pkgs.lib;
        in  
          rec {
            packages = {
		      fstar-master = fstar;
		      fstar-with-patches =
                tools.perform-fstar-to-ocaml fstar (
                    master.overrideAttrs 
                      (o: {patches = [
                             ./patches/restore-unicode.patch
                             ./patches/reflect-ranges.diff
                           ];
                          })
                );
	          fstar-pinned-commit =
				  fstar.override ({ name = "fstar-${fstar-source.rev}";
                                    src = pkgs.fetchFromGithub ({
                                      rev = "6e4674bd15bdb0fb89a12b1f5c1f6e3d5939f84e";
                                      sha256 = "14rgfy66pjyhsibiwv83kb2p9iwhv5wcbdgjwmk0yqsipkw16n09";
		                            });
                                  });
            };
            defaultPackage = packages.fstar;
          }
      );
}
```

