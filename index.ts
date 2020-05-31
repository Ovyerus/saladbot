import commands from "@erisa/commands";
import logger from "@erisa/logger";
import { Message, Guild, TextChannel } from "eris";
import { Erisa } from "erisa";
import { Redite } from "redite";

import { resolve, sep } from "path";

import { token, prefixes, owner, dbURL } from "./config.json";
import { ICheeseSettings, IHealthSettings } from "./types";

export const INTERVAL = 1000 * 60 * 60 * 24;
export const TIMER_INTERVAL = 1000 * 60 * 60;
// const INTERVAL = 1000 * 10;

function sample<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

export const findCheese = (guild: Guild, cheeseRole: string) =>
  guild.members.find((m) => m.roles.includes(cheeseRole));

export class SaladBot extends Erisa {
  db: Redite = new Redite({ url: dbURL });
  timer: NodeJS.Timer;
  lastTimerRun: number;

  async doCheeseSwap(guild: Guild, force?: boolean) {
    if (!(await this.db.has(guild.id))) return;

    const {
      cheeseRole,
      cheeseChannel,
      lastCheeseSwap,
    }: ICheeseSettings = await this.db[guild.id];

    if (force || !lastCheeseSwap || Date.now() - lastCheeseSwap >= INTERVAL) {
      const channel: TextChannel | undefined = guild.channels.get(
        cheeseChannel
      ) as TextChannel | undefined;

      if (!channel) return;

      const currentCheese = findCheese(guild, cheeseRole);
      const eligable = guild.members.filter(
        (m) =>
          (currentCheese ? m.id !== currentCheese.id : true) &&
          !m.bot &&
          !!m.roles.length
      );
      const newCheese = sample(eligable);

      if (!newCheese) {
        await channel.createMessage(
          "No eligable person found to give the cheese touch to."
        );
        return;
      }

      if (currentCheese)
        await currentCheese.removeRole(cheeseRole, "Cheese touch swap");
      await newCheese.addRole(cheeseRole, "Cheese touch swap");

      await this.db[guild.id].lastCheeseSwap.set(Date.now());
      await this.db[guild.id].canTransferCheese.set(true);

      await channel.createMessage(`${newCheese.mention} has the cheese touch!`);
    }
  }

  async doHealthUpdate(guild: Guild) {
    if (!(await this.db.has(guild.id))) return;

    const { healthChannel, lastHealthUpdate }: IHealthSettings = await this.db[
      guild.id
    ];

    if (!lastHealthUpdate || Date.now() - lastHealthUpdate >= INTERVAL) {
      const channel: TextChannel | undefined = guild.channels.get(
        healthChannel
      ) as TextChannel | undefined;

      if (!channel) return;

      await channel.createMessage("He dead.");
      await this.db[guild.id].lastHealthUpdate.set(Date.now());
    }
  }
}

const bot = new SaladBot(token);

bot.use(logger(bot));
bot.use(
  commands(bot, {
    autoLoad: true,
    commandDirectory: resolve("./cmds/") + sep,
    owner,
    prefixes,
    debug: true,
  })
);

bot.use("ready", () => {
  bot.timer = setInterval(async () => {
    const guilds: Guild[] = (await bot.db._redis.pkeys("*"))
      .map((g) => bot.guilds.get(g))
      .filter((g) => g);

    for (const guild of guilds) {
      await bot.doCheeseSwap(guild);
      await bot.doHealthUpdate(guild);
    }

    bot.lastTimerRun = Date.now();
  }, TIMER_INTERVAL);
});

bot.use("messageCreate", async (_, msg: Message) => {
  if (
    !(msg.channel instanceof TextChannel) ||
    !(await bot.db.has(msg.channel.guild.id)) ||
    msg.member?.permission.has("manageGuild")
  )
    return;

  if (!msg.content.toLowerCase().includes("casino"))
    try {
      const dm = await msg.author.getDMChannel();

      await msg.delete();
      await dm.createMessage(
        "I think your message stinks so I deleted it. Try sending something nice about our lord Casino instead."
      );
    } catch {}
});

bot.use("error", () => {});

bot.connect();
