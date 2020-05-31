import { Command, GuildContext } from "@erisa/commands";
import { INTERVAL, SaladBot, TIMER_INTERVAL } from "..";
import { ICheeseSettings } from "../types";

export default class NextSwap extends Command {
  overview = "Checks when the next cheese touch swap is.";
  guildOnly = true;

  constructor(public bot: SaladBot) {
    super();
  }

  async main(ctx: GuildContext) {
    if (!(await this.bot.db.has(ctx.guild.id)))
      return ctx.send("This server hasn't been set up.");

    const {
      cheeseChannel,
      cheeseRole,
      lastCheeseSwap,
    }: ICheeseSettings = await this.bot.db[ctx.guild.id];

    if (
      !ctx.guild.channels.get(cheeseChannel) ||
      !ctx.guild.roles.get(cheeseRole)
    )
      return ctx.send("This server hasn't been set up.");

    const time = Date.now() - (lastCheeseSwap + INTERVAL);

    // Last swap was over 24 hours ago, probably still waiting on the timer to happen.
    if (time >= INTERVAL) {
      const probableTime =
        Date.now() - (this.bot.lastTimerRun + TIMER_INTERVAL);

      await ctx.send(
        `Next cheese touch swap will probably happen in ${timeFormat(
          probableTime
        )}`
      );
    } else
      await ctx.send(
        `Next cheese touch will happen in about ${timeFormat(time)}`
      );
  }
}

function timeFormat(ms: number) {
  const time = ms / 1000;
  const all = [
    time / 60 / 60, // hours
    (time / 60) % 60, // minutes
    time % 60, // seconds
  ].map((v) => {
    v = Math.floor(v);
    return v > 10 ? "0" + v : v;
  });

  return all.join(":");
}
