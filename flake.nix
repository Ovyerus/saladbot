{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in {
        devShells.default = with pkgs;
          mkShell {
            nativeBuildInputs =
              []
              ++ (lib.optional pkgs.stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
                CoreFoundation
              ]));

            buildInputs = [
              beam.packages.erlang_26.elixir_1_16
              beam.packages.erlang_26.erlang
            ];
          };
      }
    );
}
