final: prev: {
  cedar-language-server = prev.pkgs.rustPlatform.buildRustPackage {
    pname = "cedar";
    version = "0.10.0";
    src = prev.pkgs.fetchFromGitHub {
      owner = "cedar-policy";
      repo = "cedar";
      rev = "1d81204095e1c8d830b07555028e6a2dee301799";
      sha256 = "sha256-JAvQlVOs6GHikh8jZt/y4CBU7fDHC899HZKC7xzFeY8=";
    };
    cargoHash = "sha256-uJdjTDLcHkoSh4EMI1SLfS/iRPM0FpKzWtdLZLAkLv4=";
    buildAndTestSubdir = "cedar-language-server";
  };
}
