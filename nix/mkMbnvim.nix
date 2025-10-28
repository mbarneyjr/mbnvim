{ system, inputs }:

let
  gh-actions-language-service-overlay = import ./overlays/gh-actions-language-server;
  cedar-language-server = import ./overlays/cedar-language-server.nix;
  cfn-lint-overlay = import ./overlays/cfn-lint.nix;
  cfn-lsp-extra-overlay = import ./overlays/cfn-lsp-extra.nix {
    cfn-lsp-extra = inputs.cfn-lsp-extra;
  };
  twoslash-queries-overlay = import ./overlays/twoslash-queries.nix {
    twoslash-queries-src = inputs.twoslash-queries-src;
  };
  ts-error-translator-overlay = import ./overlays/ts-error-translator.nix {
    ts-error-translator-src = inputs.ts-error-translator-src;
  };
  pkgs = import inputs.nixpkgs {
    system = system;
    config = {
      allowUnfree = true;
    };
    overlays = [
      cfn-lint-overlay
      cfn-lsp-extra-overlay
      twoslash-queries-overlay
      ts-error-translator-overlay
      gh-actions-language-service-overlay
      cedar-language-server
    ];
  };
  mkNeovim = pkgs.callPackage ./mkNeovim.nix { };
in

mkNeovim {
  plugins = with pkgs.vimPlugins; [
    # notify
    nvim-notify
    # fold
    nvim-ufo
    # colorscheme
    tokyonight-nvim
    # lualine
    lualine-nvim
    # which-key
    which-key-nvim
    # file handling
    bigfile-nvim
    hex-nvim
    # tmux
    vim-tmux-navigator
    # treesitter
    nvim-treesitter.withAllGrammars
    nvim-treesitter-textobjects
    nvim-ts-autotag
    # nvim-tree
    nvim-tree-lua
    nvim-web-devicons
    mini-icons
    # comment
    comment-nvim
    nvim-ts-context-commentstring
    # undotree
    undotree
    # telescope
    telescope-nvim
    telescope-fzf-native-nvim
    fzf-lua
    # harpoon
    harpoon2
    # images
    image-nvim
    # git
    vim-fugitive
    vim-rhubarb
    gitsigns-nvim
    vim-flog
    # code
    trouble-nvim
    nvim-coverage
    nvim-dap
    nvim-dap-view
    nvim-nio
    nvim-dap-virtual-text
    conform-nvim
    nvim-lint
    # language-specific tools
    tsc-nvim
    ts-error-translator
    # cmp, snippets
    blink-cmp
    blink-copilot
    luasnip
    # lsp
    nvim-lspconfig
    nvim-lsp-file-operations
    twoslash-queries
    # ai
    copilot-lua
    avante-nvim
    codecompanion-nvim
  ];
  extraPackages = [
    pkgs.sqlite
    pkgs.pngpaste
    pkgs.tree-sitter
    pkgs.imagemagick
    pkgs.lynx
    pkgs.terraform
    pkgs.fzf
    pkgs.stylua
    pkgs.nodePackages.prettier
    pkgs.black
    pkgs.usort
    pkgs.actionlint
    pkgs.tflint
    pkgs.terraform-ls
    pkgs.nixfmt-rfc-style
    pkgs.vscode-js-debug
    pkgs.typescript-language-server
    pkgs.biome
    pkgs.vscode-langservers-extracted
    pkgs.go
    pkgs.gopls
    pkgs.golangci-lint
    pkgs.lua-language-server
    pkgs.docker-language-server
    pkgs.dockerfile-language-server
    pkgs.docker-compose-language-service
    pkgs.dot-language-server
    pkgs.pyright
    pkgs.templ
    pkgs.nil
    pkgs.nixd
    pkgs.bash-language-server
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.tailwindcss-language-server
    pkgs.glsl_analyzer
    pkgs.python3Packages.cfn-lsp-extra
    pkgs.gh-actions-language-service
    pkgs.cedar-language-server
  ];
  extraLuaPackages =
    luaPkgs: with luaPkgs; [
      magick
      tiktoken_core
      fzf-lua
    ];
}
