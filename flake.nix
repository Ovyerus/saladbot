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
        elixir = pkgs.beam.packages.erlang_26.elixir_1_16;
        erlang = pkgs.beam.packages.erlang_26.erlang;
      in {
        devShells.default = with pkgs;
          mkShell {
            nativeBuildInputs =
              []
              ++ (lib.optional pkgs.stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
                CoreFoundation
              ]));

            buildInputs = [elixir erlang];
          };

        packages.default = let
          beam = pkgs.beamPackages;

          pname = "salad";
          version = "0.1.0";
          src = ./.;

          mixFodDeps = beam.fetchMixDeps {
            inherit src version elixir erlang;
            pname = "mix-deps-${pname}";
            hash = "sha256-DKnR2V5L76waN+EUDGvIOsgTechr67KAtrWt+CDRpxc=";
          };
          # Set RELEASE_DISTRIBUTION=none by default?
        in
          beam.mixRelease {
            inherit pname version src elixir erlang mixFodDeps;

            # When running multi-node deploys, set `RELEASE_COOKIE` to override this.
            removeCookie = false;
          };
      }
    );
}
