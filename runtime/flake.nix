{
  description = "NV editor runtime: Neovim, build tools, and language package runtimes";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              neovim git curl gnutar gzip unzip stdenv.cc
              nodejs python3 go tree-sitter ripgrep
            ];
            NV_RUNTIME_READY = "1";
          };
        });
    };
}
