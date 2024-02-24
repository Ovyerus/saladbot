{ lib, beamPackages, overrides ? (x: y: {}) }:

let
  buildRebar3 = lib.makeOverridable beamPackages.buildRebar3;
  buildMix = lib.makeOverridable beamPackages.buildMix;
  buildErlangMk = lib.makeOverridable beamPackages.buildErlangMk;

  self = packages // (overrides self packages);

  packages = with beamPackages; with self; {
    bunt = buildMix rec {
      name = "bunt";
      version = "1.0.0";

      src = fetchHex {
        pkg = "bunt";
        version = "${version}";
        sha256 = "dc5f86aa08a5f6fa6b8096f0735c4e76d54ae5c9fa2c143e5a1fc7c1cd9bb6b5";
      };

      beamDeps = [];
    };

    castle = buildMix rec {
      name = "castle";
      version = "0.3.0";

      src = fetchHex {
        pkg = "castle";
        version = "${version}";
        sha256 = "dbdc1c171520c4591101938a3d342dec70d36b7f5b102a5c138098581e35fcef";
      };

      beamDeps = [ forecastle ];
    };

    castore = buildMix rec {
      name = "castore";
      version = "0.1.22";

      src = fetchHex {
        pkg = "castore";
        version = "${version}";
        sha256 = "c17576df47eb5aa1ee40cc4134316a99f5cad3e215d5c77b8dd3cfef12a22cac";
      };

      beamDeps = [];
    };

    certifi = buildRebar3 rec {
      name = "certifi";
      version = "2.12.0";

      src = fetchHex {
        pkg = "certifi";
        version = "${version}";
        sha256 = "ee68d85df22e554040cdb4be100f33873ac6051387baf6a8f6ce82272340ff1c";
      };

      beamDeps = [];
    };

    chacha20 = buildMix rec {
      name = "chacha20";
      version = "1.0.4";

      src = fetchHex {
        pkg = "chacha20";
        version = "${version}";
        sha256 = "2027f5d321ae9903f1f0da7f51b0635ad6b8819bc7fe397837930a2011bc2349";
      };

      beamDeps = [];
    };

    connection = buildMix rec {
      name = "connection";
      version = "1.1.0";

      src = fetchHex {
        pkg = "connection";
        version = "${version}";
        sha256 = "722c1eb0a418fbe91ba7bd59a47e28008a189d47e37e0e7bb85585a016b2869c";
      };

      beamDeps = [];
    };

    cowboy = buildErlangMk rec {
      name = "cowboy";
      version = "2.10.0";

      src = fetchHex {
        pkg = "cowboy";
        version = "${version}";
        sha256 = "3afdccb7183cc6f143cb14d3cf51fa00e53db9ec80cdcd525482f5e99bc41d6b";
      };

      beamDeps = [ cowlib ranch ];
    };

    cowboy_telemetry = buildRebar3 rec {
      name = "cowboy_telemetry";
      version = "0.4.0";

      src = fetchHex {
        pkg = "cowboy_telemetry";
        version = "${version}";
        sha256 = "7d98bac1ee4565d31b62d59f8823dfd8356a169e7fcbb83831b8a5397404c9de";
      };

      beamDeps = [ cowboy telemetry ];
    };

    cowlib = buildRebar3 rec {
      name = "cowlib";
      version = "2.12.1";

      src = fetchHex {
        pkg = "cowlib";
        version = "${version}";
        sha256 = "163b73f6367a7341b33c794c4e88e7dbfe6498ac42dcd69ef44c5bc5507c8db0";
      };

      beamDeps = [];
    };

    credo = buildMix rec {
      name = "credo";
      version = "1.7.4";

      src = fetchHex {
        pkg = "credo";
        version = "${version}";
        sha256 = "9cf776d062c78bbe0f0de1ecaee183f18f2c3ec591326107989b054b7dddefc2";
      };

      beamDeps = [ bunt file_system jason ];
    };

    curve25519 = buildMix rec {
      name = "curve25519";
      version = "1.0.5";

      src = fetchHex {
        pkg = "curve25519";
        version = "${version}";
        sha256 = "0fba3ad55bf1154d4d5fc3ae5fb91b912b77b13f0def6ccb3a5d58168ff4192d";
      };

      beamDeps = [];
    };

    db_connection = buildMix rec {
      name = "db_connection";
      version = "2.6.0";

      src = fetchHex {
        pkg = "db_connection";
        version = "${version}";
        sha256 = "c2f992d15725e721ec7fbc1189d4ecdb8afef76648c746a8e1cad35e3b8a35f3";
      };

      beamDeps = [ telemetry ];
    };

    decimal = buildMix rec {
      name = "decimal";
      version = "2.1.1";

      src = fetchHex {
        pkg = "decimal";
        version = "${version}";
        sha256 = "53cfe5f497ed0e7771ae1a475575603d77425099ba5faef9394932b35020ffcc";
      };

      beamDeps = [];
    };

    ecto = buildMix rec {
      name = "ecto";
      version = "3.11.1";

      src = fetchHex {
        pkg = "ecto";
        version = "${version}";
        sha256 = "ebd3d3772cd0dfcd8d772659e41ed527c28b2a8bde4b00fe03e0463da0f1983b";
      };

      beamDeps = [ decimal jason telemetry ];
    };

    ecto_sql = buildMix rec {
      name = "ecto_sql";
      version = "3.11.1";

      src = fetchHex {
        pkg = "ecto_sql";
        version = "${version}";
        sha256 = "ce14063ab3514424276e7e360108ad6c2308f6d88164a076aac8a387e1fea634";
      };

      beamDeps = [ db_connection ecto postgrex telemetry ];
    };

    ed25519 = buildMix rec {
      name = "ed25519";
      version = "1.4.1";

      src = fetchHex {
        pkg = "ed25519";
        version = "${version}";
        sha256 = "0dacb84f3faa3d8148e81019ca35f9d8dcee13232c32c9db5c2fb8ff48c80ec7";
      };

      beamDeps = [];
    };

    emojix = buildMix rec {
      name = "emojix";
      version = "0.3.1";

      src = fetchHex {
        pkg = "emojix";
        version = "${version}";
        sha256 = "dc2fb9ed109dc7d152ca9f2f6d45557e2f9d3f7cca5879b5542241c84c421bd3";
      };

      beamDeps = [ castore jason mint ];
    };

    equivalex = buildMix rec {
      name = "equivalex";
      version = "1.0.3";

      src = fetchHex {
        pkg = "equivalex";
        version = "${version}";
        sha256 = "46fa311adb855117d36e461b9c0ad2598f72110ad17ad73d7533c78020e045fc";
      };

      beamDeps = [];
    };

    file_system = buildMix rec {
      name = "file_system";
      version = "1.0.0";

      src = fetchHex {
        pkg = "file_system";
        version = "${version}";
        sha256 = "6752092d66aec5a10e662aefeed8ddb9531d79db0bc145bb8c40325ca1d8536d";
      };

      beamDeps = [];
    };

    finch = buildMix rec {
      name = "finch";
      version = "0.18.0";

      src = fetchHex {
        pkg = "finch";
        version = "${version}";
        sha256 = "69f5045b042e531e53edc2574f15e25e735b522c37e2ddb766e15b979e03aa65";
      };

      beamDeps = [ castore mime mint nimble_options nimble_pool telemetry ];
    };

    forecastle = buildMix rec {
      name = "forecastle";
      version = "0.1.2";

      src = fetchHex {
        pkg = "forecastle";
        version = "${version}";
        sha256 = "8efaeb2e7d0fa24c605605e42562e2dbb0ffd11dc1dd99ef77d78884536ce501";
      };

      beamDeps = [];
    };

    gen_stage = buildMix rec {
      name = "gen_stage";
      version = "1.1.2";

      src = fetchHex {
        pkg = "gen_stage";
        version = "${version}";
        sha256 = "9e39af23140f704e2b07a3e29d8f05fd21c2aaf4088ff43cb82be4b9e3148d02";
      };

      beamDeps = [];
    };

    gun = buildRebar3 rec {
      name = "gun";
      version = "2.0.1";

      src = fetchHex {
        pkg = "gun";
        version = "${version}";
        sha256 = "a10bc8d6096b9502205022334f719cc9a08d9adcfbfc0dbee9ef31b56274a20b";
      };

      beamDeps = [ cowlib ];
    };

    hackney = buildRebar3 rec {
      name = "hackney";
      version = "1.20.1";

      src = fetchHex {
        pkg = "hackney";
        version = "${version}";
        sha256 = "fe9094e5f1a2a2c0a7d10918fee36bfec0ec2a979994cff8cfe8058cd9af38e3";
      };

      beamDeps = [ certifi idna metrics mimerl parse_trans ssl_verify_fun unicode_util_compat ];
    };

    hpax = buildMix rec {
      name = "hpax";
      version = "0.1.2";

      src = fetchHex {
        pkg = "hpax";
        version = "${version}";
        sha256 = "2c87843d5a23f5f16748ebe77969880e29809580efdaccd615cd3bed628a8c13";
      };

      beamDeps = [];
    };

    idna = buildRebar3 rec {
      name = "idna";
      version = "6.1.1";

      src = fetchHex {
        pkg = "idna";
        version = "${version}";
        sha256 = "92376eb7894412ed19ac475e4a86f7b413c1b9fbb5bd16dccd57934157944cea";
      };

      beamDeps = [ unicode_util_compat ];
    };

    jason = buildMix rec {
      name = "jason";
      version = "1.4.1";

      src = fetchHex {
        pkg = "jason";
        version = "${version}";
        sha256 = "fbb01ecdfd565b56261302f7e1fcc27c4fb8f32d56eab74db621fc154604a7a1";
      };

      beamDeps = [ decimal ];
    };

    kcl = buildMix rec {
      name = "kcl";
      version = "1.4.2";

      src = fetchHex {
        pkg = "kcl";
        version = "${version}";
        sha256 = "9f083dd3844d902df6834b258564a82b21a15eb9f6acdc98e8df0c10feeabf05";
      };

      beamDeps = [ curve25519 ed25519 poly1305 salsa20 ];
    };

    metrics = buildRebar3 rec {
      name = "metrics";
      version = "1.0.1";

      src = fetchHex {
        pkg = "metrics";
        version = "${version}";
        sha256 = "69b09adddc4f74a40716ae54d140f93beb0fb8978d8636eaded0c31b6f099f16";
      };

      beamDeps = [];
    };

    mime = buildMix rec {
      name = "mime";
      version = "2.0.5";

      src = fetchHex {
        pkg = "mime";
        version = "${version}";
        sha256 = "da0d64a365c45bc9935cc5c8a7fc5e49a0e0f9932a761c55d6c52b142780a05c";
      };

      beamDeps = [];
    };

    mimerl = buildRebar3 rec {
      name = "mimerl";
      version = "1.2.0";

      src = fetchHex {
        pkg = "mimerl";
        version = "${version}";
        sha256 = "f278585650aa581986264638ebf698f8bb19df297f66ad91b18910dfc6e19323";
      };

      beamDeps = [];
    };

    mint = buildMix rec {
      name = "mint";
      version = "1.5.2";

      src = fetchHex {
        pkg = "mint";
        version = "${version}";
        sha256 = "d77d9e9ce4eb35941907f1d3df38d8f750c357865353e21d335bdcdf6d892a02";
      };

      beamDeps = [ castore hpax ];
    };

    nimble_options = buildMix rec {
      name = "nimble_options";
      version = "1.1.0";

      src = fetchHex {
        pkg = "nimble_options";
        version = "${version}";
        sha256 = "8bbbb3941af3ca9acc7835f5655ea062111c9c27bcac53e004460dfd19008a99";
      };

      beamDeps = [];
    };

    nimble_pool = buildMix rec {
      name = "nimble_pool";
      version = "1.0.0";

      src = fetchHex {
        pkg = "nimble_pool";
        version = "${version}";
        sha256 = "80be3b882d2d351882256087078e1b1952a28bf98d0a287be87e4a24a710b67a";
      };

      beamDeps = [];
    };

    oban = buildMix rec {
      name = "oban";
      version = "2.17.3";

      src = fetchHex {
        pkg = "oban";
        version = "${version}";
        sha256 = "452eada8bfe0d0fefd0740ab5fa8cf3ef6c375df0b4a3c3805d179022a04738a";
      };

      beamDeps = [ ecto_sql jason postgrex telemetry ];
    };

    observer_cli = buildMix rec {
      name = "observer_cli";
      version = "1.7.4";

      src = fetchHex {
        pkg = "observer_cli";
        version = "${version}";
        sha256 = "50de6d95d814f447458bd5d72666a74624eddb0ef98bdcee61a0153aae0865ff";
      };

      beamDeps = [ recon ];
    };

    octo_fetch = buildMix rec {
      name = "octo_fetch";
      version = "0.4.0";

      src = fetchHex {
        pkg = "octo_fetch";
        version = "${version}";
        sha256 = "cf8be6f40cd519d7000bb4e84adcf661c32e59369ca2827c4e20042eda7a7fc6";
      };

      beamDeps = [ castore ssl_verify_fun ];
    };

    parse_trans = buildRebar3 rec {
      name = "parse_trans";
      version = "3.4.1";

      src = fetchHex {
        pkg = "parse_trans";
        version = "${version}";
        sha256 = "620a406ce75dada827b82e453c19cf06776be266f5a67cff34e1ef2cbb60e49a";
      };

      beamDeps = [];
    };

    plug = buildMix rec {
      name = "plug";
      version = "1.15.3";

      src = fetchHex {
        pkg = "plug";
        version = "${version}";
        sha256 = "cc4365a3c010a56af402e0809208873d113e9c38c401cabd88027ef4f5c01fd2";
      };

      beamDeps = [ mime plug_crypto telemetry ];
    };

    plug_cowboy = buildMix rec {
      name = "plug_cowboy";
      version = "2.7.0";

      src = fetchHex {
        pkg = "plug_cowboy";
        version = "${version}";
        sha256 = "d85444fb8aa1f2fc62eabe83bbe387d81510d773886774ebdcb429b3da3c1a4a";
      };

      beamDeps = [ cowboy cowboy_telemetry plug ];
    };

    plug_crypto = buildMix rec {
      name = "plug_crypto";
      version = "2.0.0";

      src = fetchHex {
        pkg = "plug_crypto";
        version = "${version}";
        sha256 = "53695bae57cc4e54566d993eb01074e4d894b65a3766f1c43e2c61a1b0f45ea9";
      };

      beamDeps = [];
    };

    poly1305 = buildMix rec {
      name = "poly1305";
      version = "1.0.4";

      src = fetchHex {
        pkg = "poly1305";
        version = "${version}";
        sha256 = "e14e684661a5195e149b3139db4a1693579d4659d65bba115a307529c47dbc3b";
      };

      beamDeps = [ chacha20 equivalex ];
    };

    postgrex = buildMix rec {
      name = "postgrex";
      version = "0.17.4";

      src = fetchHex {
        pkg = "postgrex";
        version = "${version}";
        sha256 = "6458f7d5b70652bc81c3ea759f91736c16a31be000f306d3c64bcdfe9a18b3cc";
      };

      beamDeps = [ db_connection decimal jason ];
    };

    prom_ex = buildMix rec {
      name = "prom_ex";
      version = "1.9.0";

      src = fetchHex {
        pkg = "prom_ex";
        version = "${version}";
        sha256 = "01f3d4f69ec93068219e686cc65e58a29c42bea5429a8ff4e2121f19db178ee6";
      };

      beamDeps = [ ecto finch jason oban octo_fetch plug plug_cowboy telemetry telemetry_metrics telemetry_metrics_prometheus_core telemetry_poller ];
    };

    ranch = buildRebar3 rec {
      name = "ranch";
      version = "1.8.0";

      src = fetchHex {
        pkg = "ranch";
        version = "${version}";
        sha256 = "49fbcfd3682fab1f5d109351b61257676da1a2fdbe295904176d5e521a2ddfe5";
      };

      beamDeps = [];
    };

    recon = buildMix rec {
      name = "recon";
      version = "2.5.4";

      src = fetchHex {
        pkg = "recon";
        version = "${version}";
        sha256 = "e9ab01ac7fc8572e41eb59385efeb3fb0ff5bf02103816535bacaedf327d0263";
      };

      beamDeps = [];
    };

    salsa20 = buildMix rec {
      name = "salsa20";
      version = "1.0.4";

      src = fetchHex {
        pkg = "salsa20";
        version = "${version}";
        sha256 = "745ddcd8cfa563ddb0fd61e7ce48d5146279a2cf7834e1da8441b369fdc58ac6";
      };

      beamDeps = [];
    };

    sentry = buildMix rec {
      name = "sentry";
      version = "8.0.0";

      src = fetchHex {
        pkg = "sentry";
        version = "${version}";
        sha256 = "681cf2f191696709a7878aac6e62cbcd582f92b7d541d4a8b36b3b9e6f24caf5";
      };

      beamDeps = [ hackney jason plug plug_cowboy ];
    };

    ssl_verify_fun = buildRebar3 rec {
      name = "ssl_verify_fun";
      version = "1.1.7";

      src = fetchHex {
        pkg = "ssl_verify_fun";
        version = "${version}";
        sha256 = "fe4c190e8f37401d30167c8c405eda19469f34577987c76dde613e838bbc67f8";
      };

      beamDeps = [];
    };

    telemetry = buildRebar3 rec {
      name = "telemetry";
      version = "1.2.1";

      src = fetchHex {
        pkg = "telemetry";
        version = "${version}";
        sha256 = "dad9ce9d8effc621708f99eac538ef1cbe05d6a874dd741de2e689c47feafed5";
      };

      beamDeps = [];
    };

    telemetry_metrics = buildMix rec {
      name = "telemetry_metrics";
      version = "0.6.2";

      src = fetchHex {
        pkg = "telemetry_metrics";
        version = "${version}";
        sha256 = "9b43db0dc33863930b9ef9d27137e78974756f5f198cae18409970ed6fa5b561";
      };

      beamDeps = [ telemetry ];
    };

    telemetry_metrics_prometheus_core = buildMix rec {
      name = "telemetry_metrics_prometheus_core";
      version = "1.2.0";

      src = fetchHex {
        pkg = "telemetry_metrics_prometheus_core";
        version = "${version}";
        sha256 = "9cba950e1c4733468efbe3f821841f34ac05d28e7af7798622f88ecdbbe63ea3";
      };

      beamDeps = [ telemetry telemetry_metrics ];
    };

    telemetry_poller = buildRebar3 rec {
      name = "telemetry_poller";
      version = "1.0.0";

      src = fetchHex {
        pkg = "telemetry_poller";
        version = "${version}";
        sha256 = "b3a24eafd66c3f42da30fc3ca7dda1e9d546c12250a2d60d7b81d264fbec4f6e";
      };

      beamDeps = [ telemetry ];
    };

    typed_struct = buildMix rec {
      name = "typed_struct";
      version = "0.2.1";

      src = fetchHex {
        pkg = "typed_struct";
        version = "${version}";
        sha256 = "8f5218c35ec38262f627b2c522542f1eae41f625f92649c0af701a6fab2e11b3";
      };

      beamDeps = [];
    };

    tz = buildMix rec {
      name = "tz";
      version = "0.12.0";

      src = fetchHex {
        pkg = "tz";
        version = "${version}";
        sha256 = "f1bf4cb5178e7be2eb5b7df2830ae3e1535141dc06f88b4909f1431db58edbf1";
      };

      beamDeps = [ castore mint ];
    };

    unicode_util_compat = buildRebar3 rec {
      name = "unicode_util_compat";
      version = "0.7.0";

      src = fetchHex {
        pkg = "unicode_util_compat";
        version = "${version}";
        sha256 = "25eee6d67df61960cf6a794239566599b09e17e668d3700247bc498638152521";
      };

      beamDeps = [];
    };
  };
in self

