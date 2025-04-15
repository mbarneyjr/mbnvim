{
  description = "A flake for the mbnvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = { nixpkgs, nixpkgs-unstable, ... }:
    let
      shell = { system }:
        let
          pkgs = import nixpkgs {
            system = system;
          };
          unstable = import nixpkgs-unstable {
            system = system;
          };
        in
        pkgs.mkShell {
          buildInputs = [
            unstable.neovim
            pkgs.gnumake
            pkgs.nodejs_20
            pkgs.python311Full
            pkgs.go
            pkgs.gopls
            pkgs.cargo
            pkgs.fzf
            pkgs.coreutils
            pkgs.readline
          ];

          shellHook = ''
            if ! test -d ~/.config/mbnvim; then
              ln -s $(pwd) ~/.config/mbnvim
            fi
            export NVIM_APPNAME=mbnvim
          '';
        };
    in
    {
      devShells.aarch64-darwin.default = shell { system = "aarch64-darwin"; };
      devShells.x86_64-darwin.default = shell { system = "x86_64-darwin"; };
      devShells.aarch64-linux.default = shell { system = "aarch64-linux"; };
      devShells.x86_64-linux.default = shell { system = "x86_64-linux"; };
    };
}
