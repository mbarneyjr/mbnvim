final: prev: {
  vimPlugins = prev.vimPlugins // {
    nvim-ts-context-commentstring = prev.vimUtils.buildVimPlugin {
      pname = "nvim-ts-context-commentstring";
      version = "2025-03-26";
      src = prev.fetchFromGitHub {
        owner = "JoosepAlviste";
        repo = "nvim-ts-context-commentstring";
        rev = "a681c2114cbe52e9a6878d09c9d41c35b800ce5a";
        sha256 = "sha256-W213Sr6o7AV0NlsoI00MShkwINn1CP0hhQGZ7ootvPE=";
      };
    };
  };
}
