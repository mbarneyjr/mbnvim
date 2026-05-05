{
  vimUtils,
  buildGoModule,
}:
let
  cfn-nvim-helper = buildGoModule {
    pname = "cfn-nvim-helper";
    version = "0.0.0";
    src = ./helper;
    vendorHash = "sha256-0avAH6V0+YuzUvL5n2mxT8GkjWr5esvkYUZNY0ENpRI=";
    subPackages = [ "cmd/cfn-nvim-helper" ];
  };
in
vimUtils.buildVimPlugin {
  pname = "cfn.nvim";
  version = "0.0.0";
  src = ./.;
  postInstall = ''
    mkdir -p $out/bin
    cp ${cfn-nvim-helper}/bin/cfn-nvim-helper $out/bin/cfn-nvim-helper
  '';
}
