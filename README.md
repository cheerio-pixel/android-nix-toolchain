# Android Nix Toolchain

A minimal Nix development shell for Android SDK and emulator tooling. It
provides the Android platform tools needed to build and run emulators without
choosing a language stack or app-specific development tools. Consumers add
those tools in their own flake.

## Included

- Android command-line tools and platform tools
- Android build tools 35.0.0 and platforms 35 and 36
- NDK 26.1.10909125
- Android 35 Google APIs x86_64 system image and emulator
- JDK 17 for Android command-line and build tools
- Mesa graphics libraries and EGL configuration for emulator rendering

Node.js, Ionic, language servers, linters, formatters, `just`, and app-specific
native libraries are intentionally not included.

The pinned upstream Android SDK source still uses deprecated `stdenv.isLinux`
in several Linux platform checks. This flake patches those checks to use
`stdenv.hostPlatform.isLinux` instead.

## Enter the shell

Use the published flake directly:

```sh
nix develop github:cheerio-pixel/android-nix-toolchain
```

Or clone this repository and run `nix develop` from its root. The shell sets
`ANDROID_SDK_ROOT`, `ANDROID_HOME`, `NDK_HOME`, `ANDROID_NDK_ROOT`, and
`JAVA_HOME`, and adds the SDK's platform-tools, emulator, and command-line
utilities to `PATH`.

ADB uses port `5038` to keep this environment's server separate from the host's
default ADB server. Run emulator and `adb` commands from this shell; host-level
ADB clients use a different server and will not see its devices.

## Create and run an emulator

Create an AVD using the included API 35 image:

```sh
avdmanager create avd \
  --force \
  --name android-api-35 \
  --package 'system-images;android-35;google_apis;x86_64' \
  --device pixel_6
```

Start the emulator and check its ADB connection:

```sh
emulator -avd android-api-35
adb devices
```

The shell configures Mesa/EGL paths for graphics. Add host- or
project-specific emulator options as needed.

## Extend it from another flake

Use `inputsFrom` to inherit the Android shell, then add only the packages and
hooks your project requires:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.android-nix-toolchain.url = "github:cheerio-pixel/android-nix-toolchain";

  outputs = { nixpkgs, flake-utils, android-nix-toolchain, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          inputsFrom = [
            android-nix-toolchain.devShells.${system}.default
          ];
          packages = [
            pkgs.just
            pkgs.nodejs_22
          ];
        };
      });
}
```

For example, this adds `just` and Node.js without making them dependencies of
the reusable Android toolchain.
