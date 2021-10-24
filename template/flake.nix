{
  description = "F* flake";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    fstar-flake.url = "github:W95Psp/nix-flake-fstar";
  };

  outputs = { self, nixpkgs, flake-utils, fstar-flake }:
    flake-utils.lib.eachSystem [ "x86_64-darwin" "x86_64-linux" "aarch64-linux"]
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          fstar = fstar-flake.defaultPackage.${system};
          fstar-lib = fstar-flake.lib.${system}.fstar;
        in
          {
            packages = rec {
		          fstar-with-patches = fstar-lib.build {
                name = "fstar-patched";
                src = fstar-pinned-commit.src;
                patches = [ ./Example.patch ];
              };
	            fstar-pinned-commit =
				        fstar.override { name = "fstar-pinned";
                                 src = pkgs.fetchFromGitHub {
                                   owner = "FStarLang";
                                   repo = "FStar";
                                   rev = "6a6a43d623d9ec13984f2d8dc2fe1b117a6fffa5";
                                   sha256 = "sha256-bJdlJJ/3GjXaRa1fgp2xK0WJ2gvGTVw2db8dffRIZg0=";
		                             };
                               };
            };
          }
      );
}
