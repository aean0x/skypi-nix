{
  nixpkgs.overlays = [
    (self: super: {
      # Add necessary build tools for cross-compilation
      buildPackages = super.buildPackages // {
        # Ensure we have the correct tools for cross-compiling
        gcc = super.pkgsBuildHost.gcc;
        binutils = super.pkgsBuildHost.binutils;
      };
      
      # Override packages that need special handling for cross-compilation
      unbound = super.unbound.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
          super.buildPackages.bison
          super.buildPackages.flex
          super.buildPackages.perl
        ];
        YACC = "${super.buildPackages.bison}/bin/yacc";
      });
    })
  ];
} 