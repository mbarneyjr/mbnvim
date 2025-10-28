final: prev: {
  vimPlugins = prev.vimPlugins // {
    twoslash-queries = final.vimUtils.buildVimPlugin {
      name = "twoslash-queries";
      src = prev.fetchFromGitHub {
        owner = "marilari88";
        repo = "twoslash-queries.nvim";
        rev = "1262c20cad5abd6e89995dc4bc0eaab0e2e4e0b9";
        hash = "sha256-btmSEZ1rTIcp3bOxoY8UakC5A9rHErnnQTiCKAaXiwE=";
      };
    };
  };
}
