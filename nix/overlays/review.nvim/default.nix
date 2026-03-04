final: prev: {
  review-nvim-mcp =
    let
      nodejs = prev.nodejs_24;
      pkg = prev.buildNpmPackage {
        name = "review-nvim-mcp";
        version = "1.0.0";
        src = ../../../packages/review.nvim;
        inherit nodejs;
        npmDepsHash = "sha256-0bwp9EPoQK/9jg7unQSx5WxCnWL+G/gBkc0qYHG1xqM=";
        dontNpmBuild = true;
        postInstall = ''
          mv $out/lib/node_modules/review.nvim $out/lib/review-nvim
          rmdir $out/lib/node_modules
        '';
      };
    in
    prev.writeShellScriptBin "review-nvim-mcp" ''
      exec ${nodejs}/bin/node ${pkg}/lib/review-nvim/src/index.ts "$@"
    '';

  vimPlugins = prev.vimPlugins // {
    review-nvim = prev.vimUtils.buildVimPlugin {
      pname = "review.nvim";
      version = "1.0.0";
      src = ../../../packages/review.nvim;
    };
  };
}
