{
  description = "A flake for the mbnvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
          buildInputs = [ pkgs.neovim ];

          shellHook = ''
            ln -s $(pwd) ~/.config/mbnvim
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
