{ inputs, ... }:
{
  flake.overlays.lsplinks = final: prev: {
    vimPlugins = prev.vimPlugins // {
      lsplinks = prev.vimUtils.buildVimPlugin {
        pname = "lsplinks-nvim";
        version = inputs.lsplinks-nvim.shortRev or "unstable";
        src = inputs.lsplinks-nvim;
      };
    };
  };
  flake.overlays.nvim-ts-context-commentstring = final: prev: {
    vimPlugins = prev.vimPlugins // {
      nvim-ts-context-commentstring = prev.vimUtils.buildVimPlugin {
        pname = "nvim-ts-context-commentstring";
        version = inputs.nvim-ts-context-commentstring.shortRev or "unstable";
        src = inputs.nvim-ts-context-commentstring;
      };
    };
  };
  perSystem =
    { pkgs, ... }:
    {
      mbnvim = {
        plugins = with pkgs.vimPlugins; [
          # diagnostics
          trouble-nvim
          # formatting
          conform-nvim
          # linting
          nvim-lint
          # debugging
          nvim-dap
          nvim-dap-view
          nvim-dap-virtual-text
          # treesitter
          pkgs.vimPlugins.nvim-treesitter.withAllGrammars
          # commenting
          comment-nvim
          nvim-ts-context-commentstring
          # lsp
          nvim-lspconfig
          nvim-lsp-file-operations
          lsplinks
          # cmp, snippets
          blink-cmp
          blink-copilot
          luasnip
        ];
        extraPackages = [
          pkgs.tree-sitter
        ];
      };
    };
}
