import { Options } from "mikro-orm";

import getConfig from "./getConfig";

const config = getConfig("../config.toml");

export default {
  entitiesDirs: ["./dist/entities"],
  entitiesDirsTs: ["./src/entities"],
  clientUrl: config.database,
} as Options;
