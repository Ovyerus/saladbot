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
        fs = pkgs.lib.fileset;

        elixir = beam'.elixir_1_16;
        erlang = beam'.erlang;

        mixFiles = [./mix.exs ./mix.lock];
        nativeBuildInputs = with pkgs;
          []
          ++ (lib.optional stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreFoundation
          ]));

        # Build release
        pname = "salad";
        version = "0.1.0";

        mixFodDeps = beam'.fetchMixDeps {
          inherit version elixir erlang;
          pname = "mix-deps-${pname}";
          src = fs.toSource {
            root = ./.;
            fileset = fs.unions mixFiles;
          };
          hash = "sha256-DKnR2V5L76waN+EUDGvIOsgTechr67KAtrWt+CDRpxc";
        };

        release = beam'.mixRelease {
          inherit pname version elixir erlang mixFodDeps nativeBuildInputs;

          # TODO: figure out how to include only the app code so that only
          # relevant changes are caught (fs.toSource/unions doesn't work for
          # some reason)
          src = ./.;
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
                Entrypoint = ["${dumb-init}/bin/dumb-init" "--"];
                # Some random containerd change set OPEN_MAX to infinity, which
                # causes BEAM to inhale RAM like it's Kirby.
                Env = ["ERL_MAX_PORTS=1024"];
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
