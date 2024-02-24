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

        mixFiles = [./mix.exs ./mix.lock];
        nativeBuildInputs = with pkgs;
          []
          ++ (lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
            CoreFoundation
          ]));

        # Build release
        pname = "salad";
        version = "0.1.0";

        mixNixDeps = import ./mix.nix {
          lib = pkgs.lib;
          beamPackages = beam';

          # TODO: problem with deps not being included?
          overrides = final: prev: {
            nostrum = beam'.buildMix {
              name = "nostrum";
              version = "0.9.0-alpha2";
              enableDebugInfo = true;

              src = pkgs.fetchFromGitHub {
                owner = "Kraigie";
                repo = "nostrum";
                rev = "d2daf4941927bc4452a4e79acbef4a574ce32f57";
                hash = "sha256-W+aJ1+rDtLpURAa9h19gm6GUOZytDZ5TGCD4mJ5wJe0=";
              };

              # Trying to build in nix with `:appup` as a compiler results in
              # that compiler not being found for some reason. Tried a little
              # debugging but decided yeeting it entirely is just the easiest
              # solution for now.
              patches = [./no-appup.patch];
              beamDeps = with final; [jason gun certifi kcl mime castle];
            };
          };
        };

        release = beam'.mixRelease {
          inherit pname version elixir erlang mixNixDeps nativeBuildInputs;

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
            buildInputs = [elixir_1_16 erlang];
          };

        packages = {
          inherit docker release;
          default = release;
        };
      }
    );
}
