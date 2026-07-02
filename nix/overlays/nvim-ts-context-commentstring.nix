inputs: final: prev: {
  vimPlugins = prev.vimPlugins // {
    nvim-ts-context-commentstring = prev.vimUtils.buildVimPlugin {
      pname = "nvim-ts-context-commentstring";
      version = inputs.nvim-ts-context-commentstring.shortRev or "unstable";
      src = inputs.nvim-ts-context-commentstring;
    };
  };
}
