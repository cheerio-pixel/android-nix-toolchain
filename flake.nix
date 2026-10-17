{
  description = "Reusable Android build and emulator development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };
  inputs.android-nixpkgs = {
    url = "github:tadfisher/android-nixpkgs/stable";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, flake-utils, android-nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        androidSdk = android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
          cmdline-tools-latest
          platform-tools
          build-tools-35-0-0
          platforms-android-35
          platforms-android-36
          ndk-26-1-10909125
          system-images-android-35-google-apis-x86-64
          emulator
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nodejs_22
            pkgs.ionic-cli
            pkgs.typescript-language-server
            pkgs.vscode-langservers-extracted
            pkgs.eslint
            pkgs.prettier
            pkgs.just
            pkgs.pkg-config
            pkgs.dbus
            pkgs.dbus.dev
            pkgs.gtk3
            pkgs.webkitgtk_4_1
            pkgs.librsvg
            pkgs.openssl
            pkgs.mesa
            pkgs.jdk17
            androidSdk
          ];
          shellHook = ''
            export ANDROID_SDK_ROOT="${androidSdk}/share/android-sdk"
            export ANDROID_HOME="$ANDROID_SDK_ROOT"
            # Keep this emulator's server separate from host-level ADB clients.
            export ANDROID_ADB_SERVER_PORT=5038
            export NDK_HOME="$ANDROID_SDK_ROOT/ndk/26.1.10909125"
            export ANDROID_NDK_ROOT="$NDK_HOME"
            export JAVA_HOME="${pkgs.jdk17}"
            export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
              pkgs.gtk3
              pkgs.webkitgtk_4_1
              pkgs.libsoup_3
              pkgs.glib
              pkgs.cairo
              pkgs.pango
              pkgs.gdk-pixbuf
              pkgs.atk
              pkgs.dbus
              pkgs.librsvg
              pkgs.mesa
            ]}:$LD_LIBRARY_PATH"
            export __EGL_VENDOR_LIBRARY_FILENAMES="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
            export LIBGL_DRIVERS_PATH="${pkgs.mesa}/lib/dri"
          '';
        };
      });
}
