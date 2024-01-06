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
        # Setup
        pkgs = import nixpkgs {inherit system;};
        beam = pkgs.beam.packages.erlang_26;

        elixir = beam.elixir_1_16;
        erlang = beam.erlang;

        nativeBuildInputs = with pkgs;
          []
          ++ (lib.optional stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreFoundation
          ]));

        # Build release
        pname = "salad";
        version = "0.1.0";
        src = ./.;

        mixFodDeps = beam.fetchMixDeps {
          inherit src version elixir erlang;
          pname = "mix-deps-${pname}";
          hash = "sha256-DKnR2V5L76waN+EUDGvIOsgTechr67KAtrWt+CDRpxc=";
        };

        release = beam.mixRelease {
          inherit pname version src elixir erlang mixFodDeps nativeBuildInputs;

          # When running multi-node deploys, set `RELEASE_COOKIE` to override this.
          removeCookie = false;
        };

        docker = pkgs.dockerTools.buildImage {
          name = pname;
          tag = "latest";
          copyToRoot = [release];
          config.Cmd = ["${release}/bin/salad" "start"];
        };
      in
        with pkgs; {
          devShells.default = mkShell {
            inherit nativeBuildInputs;
            buildInputs = [elixir erlang];
          };

          packages = {
            inherit docker release;
            default = release;
          };
        }
    );
}
