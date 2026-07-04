{ inputs, ... }:
{
  flake.overlays.tmux-language-server = final: prev: {
    tree-sitter-tmux = prev.python3Packages.buildPythonPackage {
      name = "tree-sitter-tmux";
      version = "0+${inputs.tree-sitter-tmux.shortRev or "unstable"}";
      src = inputs.tree-sitter-tmux;
      pyproject = true;
      disabled = prev.python3Packages.pythonOlder "3.6";
      build-system = [
        prev.python3Packages.setuptools
      ];
    };
    tmux-language-server = prev.python3Packages.buildPythonApplication {
      name = "tmux-language-server";
      version = "0+${inputs.tmux-language-server.shortRev or "unstable"}";
      src = inputs.tmux-language-server;
      pyproject = true;
      disabled = prev.python3Packages.pythonOlder "3.6";
      build-system = [
        prev.python3Packages.setuptools
        prev.python3Packages.setuptools-generate
        prev.python3Packages.setuptools-scm
      ];
      dependencies = [
        prev.python3Packages.lsp-tree-sitter
        final.tree-sitter-tmux
      ];
      pythonImportsCheck = [
        "tmux_language_server"
      ];
    };
  };

  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.tmux-language-server
      ];
    };
}
