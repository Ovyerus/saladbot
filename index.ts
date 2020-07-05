import commands from "@erisa/commands";
import logger from "@erisa/logger";
import { Guild } from "eris";

import { resolve, sep } from "path";

import getConfig from "./src/getConfig";
import { SaladBot, TIMER_INTERVAL } from "./src/saladbot";

const config = getConfig("./config.toml");
const bot = new SaladBot(config.token);

bot.use(logger(bot));
bot.use(
  commands(bot, {
    autoLoad: true,
    commandDirectory: resolve("./src/cmds/") + sep,
    owner: config.owner,
    prefixes: config.prefixes,
    debug: true,
  })
);

bot.use("ready", () => {
  bot.timer = setInterval(async () => {
    const guilds = (await bot.db.guilds.findAll())
      .map(({ id }) => bot.guilds.get(id))
      .filter((g) => g) as Guild[];
    // const guilds: Guild[] = (await bot.db._redis.pkeys("*"))
    //   .map((g) => bot.guilds.get(g))
    //   .filter((g) => g);

    /* eslint-disable no-await-in-loop */
    for (const guild of guilds) {
      await bot.doCheeseSwap(guild);
      await bot.doHealthUpdate(guild);
    }
    /* eslint-enable */

    bot.lastTimerRun = Date.now();
  }, TIMER_INTERVAL);
});

bot.use("error", () => {});

bot.connect();
