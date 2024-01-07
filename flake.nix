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
        pkgs = import nixpkgs {inherit system;};
        # Don't include anything extra like systemd & wxwidgets
        beam' = pkgs.beam_minimal.packages.erlang_26;

        elixir = beam'.elixir_1_16;
        erlang = beam'.erlang;

        nativeBuildInputs = with pkgs;
          []
          ++ (lib.optional stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreFoundation
          ]));

        # Build release
        pname = "salad";
        version = "0.1.0";
        # TODO: only include app code somehow, otherwise it will change on any non-important change.
        src = ./.;

        mixFodDeps = beam'.fetchMixDeps {
          inherit src version elixir erlang;
          pname = "mix-deps-${pname}";
          hash = "sha256-B3kBc/gpZTIxoOF+Bx9OkO6H4huwFBg+a4T1KGU4wDk=";
        };

        release = beam'.mixRelease {
          inherit pname version src elixir erlang mixFodDeps nativeBuildInputs;

          # When running multi-node deploys, set `RELEASE_COOKIE` to override this.
          removeCookie = false;
        };

        docker = with pkgs;
          if system == "x86_64-linux" || system == "aarch64-linux"
          then
            (dockerTools.buildImage {
              name = pname;
              tag = "latest";
              # Without busybox the container exits immediately with `Protocol 'inet_tcp': register/listen error: econnrefused`
              # TODO: figure out what dependency busybox provides that fixes this
              copyToRoot = [release pkgsStatic.busybox];
              config = {
                Cmd = ["${release}/bin/salad" "start"];
                Entrypoint = ["${pkgsStatic.dumb-init}/bin/dumb-init" "--"];
              };
            })
          else runCommand pname {} "echo 'Docker image is not available to be built on darwin systems. Use a linux remote builder instead.'; exit 1";
      in {
        devShells.default = with pkgs;
          mkShell {
            inherit nativeBuildInputs;
            # Use the full fat BEAM packages as it contains extra things that might be useful during development.
            buildInputs = with beam'; [elixir_1_16 erlang];
          };

        packages = {
          inherit docker release;
          default = release;
        };
      }
    );
}
