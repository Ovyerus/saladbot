{
  beamMinimalPackages,
  lib,
}: let
  # Don't include anything extra like systemd & wxwidgets
  inherit (beamMinimalPackages) elixir erlang fetchMixDeps mixRelease;

  pname = "salad";
  version = "0.1.0";
  # TODO: figure out how to include only the app code so that only
  # relevant changes are caught (fs.toSource/unions doesn't work for
  # some reason)
  src = ./.;
  mixFodDeps = fetchMixDeps {
    pname = "mix-deps-${pname}";
    inherit src version;
    hash = "sha256-kg23ijVyickU/Zb4I0CP5CQNDPRrcs1F9lRAOcGBM84=";
  };
in
  mixRelease {
    inherit pname version src mixFodDeps elixir erlang;
    # When running multi-node deploys, set `RELEASE_COOKIE` to override this.
    removeCookie = false;

    postBuild = ''
      mix sentry.package_source_code --no-deps-check --no-compile --output ./priv/sentry.map
    '';
  }
