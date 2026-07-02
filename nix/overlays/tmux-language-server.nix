final: prev: {
  tree-sitter-tmux = prev.python3Packages.buildPythonPackage rec {
    name = "tree-sitter-tmux";
    version = "0.0.4";
    src = prev.fetchFromGitHub {
      owner = "Freed-Wu";
      repo = "tree-sitter-tmux";
      rev = version;
      sha256 = "sha256-8f78qYxqoiOAnl3HzEbF4Rci3rFy0SnELoU+QP7pUlk=";
    };
    pyproject = true;
    disabled = prev.python3Packages.pythonOlder "3.6";
    build-system = [
      prev.python3Packages.setuptools
    ];
  };
  tmux-language-server = prev.python3Packages.buildPythonApplication rec {
    name = "tmux-language-server";
    version = "0.0.17";
    src = prev.fetchFromGitHub {
      owner = "Freed-Wu";
      repo = "tmux-language-server";
      rev = version;
      sha256 = "sha256-FQaSJ+KuwOmsQBHWrsPkHOdwCD8M8pzUfZK6zeMNlLU=";
    };
    pyproject = true;
    disabled = prev.python3Packages.pythonOlder "3.6";
    build-system = [
      prev.python3Packages.setuptools
      prev.python3Packages.setuptools-generate
      prev.python3Packages.setuptools-scm
    ];
    dependencies = [
      prev.python313Packages.lsp-tree-sitter
      final.tree-sitter-tmux
    ];
    pythonImportsCheck = [
      "tmux_language_server"
    ];
  };
}
