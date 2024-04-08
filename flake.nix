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
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.neovim ];

        shellHook = ''
          ln -s $(pwd) ~/.config/mbnvim
          export NVIM_APPNAME=mbnvim
        '';
      };
    };
}
