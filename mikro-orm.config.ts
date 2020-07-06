import { Options } from "mikro-orm";

import getConfig from "./src/getConfig";

const config = getConfig("./config.toml");

export default {
  entitiesDirs: ["./dist/entities"],
  entitiesDirsTs: ["./src/entities"],
  type: "postgresql",
  clientUrl: config.database,
  baseDir: __dirname,
} as Options;
