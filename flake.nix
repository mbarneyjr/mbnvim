{
  description = "A flake for the mbnvim configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        system = system;
      };
      shell = pkgs.mkShell {
        buildInputs = [ pkgs.neovim ];

        shellHook = ''
          ln -s $(pwd) ~/.config/mbnvim
          export NVIM_APPNAME=mbnvim
        '';
      };
    in
    {
      devShells.aarch64-darwin.default = shell;
      devShells.x86_64-darwin.default = shell;
      devShells.aarch64-linux.default = shell;
      devShells.x86_64-linux.default = shell;
    };
}
