import TOML from "@iarna/toml";

import { readFileSync, existsSync } from "fs";

interface Config {
  token: string;
  prefixes: string[];
  owner: string;
  database: string;
}
export default (path: string) => {
  const file = existsSync(path) ? readFileSync(path).toString() : "";
  const cfg = TOML.parse(file);

  return {
    token: cfg.token || process.env.SALAD_TOKEN,
    prefixes: cfg.prefixes || [process.env.SALAD_PREFIX],
    owner: cfg.owner || process.env.SALAD_OWNER,
    database: cfg.database || process.env.SALAD_DATABASE,
  } as Config;
};
