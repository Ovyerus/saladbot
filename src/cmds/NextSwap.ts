import { Command, GuildContext } from "@erisa/commands";

import { INTERVAL, SaladBot, TIMER_INTERVAL } from "../saladbot";

function timeFormat(ms: number) {
  const time = ms / 1000;
  const all = [
    time / 60 / 60, // hours
    (time / 60) % 60, // minutes
    time % 60, // seconds
  ].map((v) => {
    v = Math.floor(v);
    return v > 10 ? `0${v}` : v;
  });

  return all.join(":");
}

export default class NextSwap extends Command {
  overview = "Checks when the next cheese touch swap is.";
  guildOnly = true;

  constructor(public bot: SaladBot) {
    super();
  }

  async main(ctx: GuildContext) {
    const guild = await this.bot.db.guilds.findOne(ctx.guild.id);

    if (!guild) return ctx.send("This server hasn't been set up.");

    const lastCheeseTouch = await this.bot.db.cheeseTouchs.findOne({
      guild: { id: ctx.guild.id },
    });
    const time = Date.now() - (lastCheeseTouch!.timestamp.getTime() + INTERVAL);

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
