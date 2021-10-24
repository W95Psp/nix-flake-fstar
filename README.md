# Build [F*](https://github.com/FStarLang/FStar/) in an easy and reproducible way
> Nix is a cross-platform package manager that utilizes a purely functional deployment model where software is installed into unique directories generated through cryptographic hashes. [...] A package's hash takes into account the dependencies, which is claimed to eliminate dependency hell.[2] This package management model advertises more reliable, reproducible, and portable packages. ~[Wikipedia](https://en.wikipedia.org/wiki/Nix_package_manager)

This repository is a [Nix](https://nixos.org/manual/nix/stable/) [flake](https://nixos.wiki/wiki/Flakes) that provides a simple and flexible way to declaratively build F* binaries from various sources.

## Prerequisite: Nix with flake support
 1. Install Nix: `curl -L https://nixos.org/nix/install | sh` ([more information](https://nixos.org/download.html#nix-quick-install));
 2. Install the nix binary with flake support: `nix-env -iA nixpkgs.nixFlakes`;
 3. Enable flake support: `echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf`.

## Basic usage
### Default F* revision
 - To get a shell with F* available, run:  
`nix shell 'github:W95Psp/nix-flake-fstar'`  
*This command will drop you in a shell from which an F\* binary is available.*

 - To build an F* binary, run:  
`nix build 'github:W95Psp/nix-flake-fstar'`  
*This command will build F\*, and create the symblink `./result`, containing the build output.*

 - To run directly F*:
`nix run 'github:W95Psp/nix-flake-fstar' somemodule.fst`  
`nix run 'github:W95Psp/nix-flake-fstar' any F* flags`  
 

### Custom F* source
Adding the flag `--override-input fstar-source SOURCE` to any of the `nix shell`, `nix build` or `nix run` commands above allows to set the F* sources to be built.
`SOURCE` is an [URL-like representation](https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#examples) pointing to the F* source wanted.

For example:
 - `nix build 'github:W95Psp/nix-flake-fstar' --override-input fstar-source 'github:FStarLang/FStar?rev=6a6a43d623d9ec13984f2d8dc2fe1b117a6fffa5'` builds the F* sources of the GitHub repository https://github.com/FStarLang/FStar/ at revision `6a6a43d623d9ec13984f2d8dc2fe1b117a6fffa5`;
 - `nix build 'github:W95Psp/nix-flake-fstar' --override-input fstar-source 'github:owner/repo?rev=REV'` builds the F* sources of the GitHub repository https://github.com/owner/repo/ at revision `REV`;
 - `nix build 'github:W95Psp/nix-flake-fstar' --override-input fstar-source 'path:/some/path'` builds the F* sources present at path `/some/path` at revision `REV`.

### Latest commit in F*'s master
Using the flag `override-input`, with `github:FStarLang/FStar` as source will pull the latest commit.

`nix build 'github:W95Psp/nix-flake-fstar' --override-input fstar-source 'github:FStarLang/FStar'`


## Flake usage
Clone a ready-to-use template with a few examples of usage:
`nix init -t 'github:W95Psp/nix-flake-fstar'`

## Documentation
F* binaries are built in three steps as described in F*'s [INSTALL.md](https://github.com/FStarLang/FStar/blob/master/INSTALL.md).

This flake provides the following attributes:
 - `lib.SYSTEM.fstar`: (with `SYSTEM` being `"x86_64-darwin"`, `"x86_64-linux"` or `"aarch64-linux"`)
   - `build`: builds a specific F* binary from given F* sources 
      + **Input is expected to be an set with the following attributes:** 
        - **`src`**: the sources to build (e.g. a path or a derivation);
        - **`name`**: the name of the derivation (e.g. `"my-fstar-build"`);
  	  - *(optional attributes)*
  	    + `keep_src` *(defaults to `false`)*: whether the `src` folder is kept or not;
          + `withlibs` *(defaults to `true`)*: whether `ulib` is built or not;
          + `patches` *(defaults to `[]`)*: list of patches to apply (list of paths);
          + `existing-fstar` *(defaults to OCaml snapshot)*: which F* binary should be used for extracting sources of F* to OCaml.
      + **Ouputs** a derivation that builds an F* binary.
   - `ocaml-from-fstar`: extracts OCaml from given F* sources
      + **Input is expected to be an set with the following attributes:** 
        - **`src`**: the sources to build (e.g. a path or a derivation);
        - **`name`**: the name of the derivation (e.g. `"my-fstar-build"`);
  	  - **`existing-fstar`**: the F* binary to be used for extracting sources of F* to OCaml;
  	  - *(optional attributes)*
          + `patches` *(defaults to `[]`)*: list of patches to apply (list of paths).
      + **Ouputs** a derivation with an up-to-date OCaml snapshot.
   - `binary-of-ml-snapshot`: builds the OCaml snapshot of a given F* source, producing an ready-to-use F* binary
      + **Input is expected to be an set with the following attributes:** 
        - **`src`**: the sources to build (e.g. a path or a derivation);
        - **`name`**: the name of the derivation (e.g. `"my-fstar-build"`);
  	  - *(optional attributes)*
  	    + `keep_src` *(defaults to `false`)*: whether the `src` folder is kept or not;
          + `withlibs` *(defaults to `true`)*: whether `ulib` is built or not.
      + **Ouputs** a derivation with an up-to-date OCaml snapshot.
   - `buildInputs`: is the list of OCaml dependencies required to build F*.
 - `packages.SYSTEM`: (with `SYSTEM` being `"x86_64-darwin"`, `"x86_64-linux"` or `"aarch64-linux"`) 
   + `fstar`: default F* binary;
   + `z3`: [Z3](https://github.com/Z3Prover/z3) binary.

