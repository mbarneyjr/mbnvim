final: prev: {
  vimPlugins = prev.vimPlugins // {
    ts-error-translator = final.vimUtils.buildVimPlugin {
      pname = "ts-error-translator";
      version = "1.2.0";
      src = prev.fetchFromGitHub {
        owner = "dmmulroy";
        repo = "ts-error-translator.nvim";
        rev = "v1.2.0";
        hash = "sha256-fi68jJVNTL2WlTehcl5Q8tijAeu2usjIsWXjcuixkCM=";
      };
    };
  };
}
