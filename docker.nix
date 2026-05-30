{
  dockerTools,
  busybox,
  salad,
  dumb-init,
}:
dockerTools.buildLayeredImage {
  name = "salad";
  tag = "latest";

  # Without busybox the container exits immediately with `Protocol 'inet_tcp': register/listen error: econnrefused`
  # TODO: figure out what dependency busybox provides that fixes this
  contents = [salad busybox];
  config = {
    Cmd = ["${salad}/bin/salad" "start"];
    Entrypoint = ["${dumb-init}/bin/dumb-init" "--"];
    # Some random containerd change set OPEN_MAX to infinity, which
    # causes BEAM to inhale RAM like it's Kirby.
    Env = ["ERL_MAX_PORTS=1024"];
  };
}
