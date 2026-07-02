inputs: [
  (import ./cedar-language-server.nix inputs)
  (import ./cfn-lint.nix inputs)
  (import ./cloudformation-languageserver inputs)
  (import ./gh-actions-language-server inputs)
  (import ./lsplinks.nix inputs)
  (import ./nvim-ts-context-commentstring.nix inputs)
  (import ./tmux-language-server.nix inputs)
]
