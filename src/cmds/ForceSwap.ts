import { Command, GuildContext } from "@erisa/commands";

import { SaladBot } from "../saladbot";

export default class ForceSwap extends Command {
  overview = "Forces a cheese touch swap.";
  guildOnly = true;
  permissions = {
    author: "manageGuild",
  };

  constructor(public bot: SaladBot) {
    super();
  }

  async main(ctx: GuildContext) {
    const guild = await this.bot.db.guilds.findOne(guild.id);

    if (!guild) return ctx.send("This server hasn't been set up.");

    if (
      !ctx.guild.channels.get(guild.cheeseTouchChannel) ||
      !ctx.guild.roles.get(guild.cheeseTouchRole)
    )
      return ctx.send("This server hasn't been set up.");

    await this.bot.doCheeseSwap(ctx.guild, true);
  }
}
