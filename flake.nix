{
  inputs = {
    naersk.url = "github:nix-community/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    naersk,
    nixpkgs,
    rust-overlay,
    self,
    utils,
  }:
    utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];
      pkgs = (import nixpkgs) {inherit system overlays;};
      toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      naersk' = pkgs.callPackage naersk {
        cargo = toolchain;
        rustc = toolchain;
        clippy = toolchain;
      };
      buildInputs = with pkgs; lib.optionals stdenv.isDarwin [libiconv darwin.apple_sdk.frameworks.Security];
    in {
      defaultPackage = naersk'.buildPackage ./.;
      devShell = with pkgs;
        mkShell {
          packages = [
            cargo
            rustc
            rustfmt
            # pre-commit
            rustPackages.clippy
            rust-analyzer
          ];
          nativeBuildInputs = [
            pkg-config
          ];
          buildInputs = [
            udev
            alsa-lib
            vulkan-loader
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr # To use the x11 feature
            libxkbcommon
            wayland # To use the wayland feature
          ];
          RUST_SRC_PATH = rustPlatform.rustLibSrc;
        };
    });
}
