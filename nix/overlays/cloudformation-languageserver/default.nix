inputs: final: prev: {
  cloudformation-languageserver = prev.callPackage ./package.nix {
    src = inputs.cloudformation-languageserver;
  };
}
