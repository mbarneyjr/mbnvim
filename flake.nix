{
  description = "Neovim derivation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    import-tree.url = "github:vic/import-tree";

    fff-nvim = {
      url = "github:dmtrKovalenko/fff.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aws-iam-language-server = {
      url = "github:mbarneyjr/aws-iam-language-server";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    lsplinks-nvim = {
      url = "github:icholy/lsplinks.nvim";
      flake = false;
    };
    nvim-ts-context-commentstring = {
      url = "github:JoosepAlviste/nvim-ts-context-commentstring";
      flake = false;
    };
    cedar = {
      url = "github:cedar-policy/cedar";
      flake = false;
    };
    tree-sitter-tmux = {
      url = "github:Freed-Wu/tree-sitter-tmux";
      flake = false;
    };
    tmux-language-server = {
      url = "github:Freed-Wu/tmux-language-server";
      flake = false;
    };
    actions-languageservices = {
      url = "github:actions/languageservices";
      flake = false;
    };
    cloudformation-languageserver = {
      url = "github:aws-cloudformation/cloudformation-languageserver";
      flake = false;
    };
  };

  outputs =
    inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
