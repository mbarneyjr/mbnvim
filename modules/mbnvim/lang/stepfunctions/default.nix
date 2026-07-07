{
  flake.overlays.asl-language-server = final: prev: {
    asl-language-server = prev.buildNpmPackage {
      pname = "asl-language-server";
      version = "1.16.1";
      src = ./server;
      npmDepsHash = "sha256-SbfxHtoZRnL/zUJJp1Nih5YklR+sH7Fb/qSwUF3ts20=";
      dontNpmBuild = true;
      meta.mainProgram = "asl-language-server";
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.asl-language-server
      ];
    };
}
