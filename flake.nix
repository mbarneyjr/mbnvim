{
  description = "A flake for the mbnvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { nixpkgs, ... }:
    let
      shell = { system }:
        let
          pkgs = import nixpkgs {
            system = system;
          };
        in
        pkgs.mkShell {
          buildInputs = [
            pkgs.neovim
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
