{
  perSystem =
    { pkgs, ... }:
    {
      mbnvim.extraPackages = [
        pkgs.vscode-langservers-extracted
        pkgs.tailwindcss-language-server
        pkgs.prettier
      ];
    };
}
