{ lib
, pkgsBuildTarget
, pkgsBuildBuild
, pkgsBuildHost
, fetchFromGitHub
, fetchpatch
, formats
, rust
, rustPlatform
, llvmPackages_z80
, python3
}: {

  packages.stable = rec {
    rustc = (rust.override {
      llvm_16 = llvmPackages_z80.libllvm;
      pkgsBuildTarget = pkgsBuildTarget // { llvmPackages_16 = pkgsBuildTarget.llvmPackages_z80; };
      pkgsBuildBuild = pkgsBuildBuild // { llvmPackages_16 = pkgsBuildBuild.llvmPackages_z80; };
      pkgsBuildHost = pkgsBuildHost // { llvmPackages_16 = pkgsBuildHost.llvmPackages_z80; };
    }).packages.stable.rustc.overrideAttrs (old: rec {
      pname = "rustc-z80";
      version = "1.80.0.1";
      src = fetchFromGitHub {
        owner = "esp-rs";
        repo = "rust";
        rev = "${version}";
        fetchSubmodules = true;
      };
      configureFlags = old.configureFlags
        ++ [
          "--experimental-targets=z80"
          # "--release-channel=nightly"
          "--enable-extended"
          "--tools=clippy,cargo,rustfmt"
          # "--enable-lld"
        ];

      prePatch = ''
        cp -r ../.cargo .cargo
        ln -s $cargoDepsCopy vendor
      '';
      # TODO replace this with something custom? Apparently rustc isn't really made for using fetchCargoTarball
      cargoDeps = rust.packages.stable.rustPlatform.fetchCargoTarball {
        inherit pname;
        inherit src;
        sourceRoot = null;
        srcs = null;
        patches = [ ];
        extraCargoVendorArgs = "--sync ./src/tools/rust-analyzer/Cargo.toml --sync ./compiler/rustc_codegen_cranelift/Cargo.toml --sync ./src/bootstrap/Cargo.toml";
        sha256 = "sha256-oBFrgOB6PLvvCEWHbLZKSLMz3TQ58u/3jzKklUr6g3Q=";
        nativeBuildInputs = [ python3 ];
      };
      nativeBuildInputs = old.nativeBuildInputs ++ [ rustPlatform.cargoSetupHook ];
      # postConfigure = ''
      #   ${old.postConfigure}
      #   unpackFile "$cargoDeps"
      #   mv $(stripHash $cargoDeps) vendor
      # '';
      meta.maintainers = with lib.maintainers; [ erictapen ];
    });

    cargo = (rust.packages.stable.cargo.override {
      inherit rustc;
    }).overrideAttrs (old: rec {
      pname = "cargo-z80";
      inherit (rustc) cargoDeps;
      postConfigure = ''
        ${old.postConfigure or ""}
        unpackFile "$cargoDeps"
        mv $(stripHash $cargoDeps) vendor
      '';
    });

  };
}
