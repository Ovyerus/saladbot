import { Command, GuildContext } from "@erisa/commands";
import { TextChannel, User } from "eris";

import { SaladBot } from "../saladbot";

const badDialogue =
  "Oh yeah? You think you're funny? You blithering, wimpy punk? I'll show you 'funny'." +
  "I'll go back in time and fart on your dad's balls." +
  "You will be eliminated from the gene pool prior to your pitiful conception." +
  "Now THAT is 'funny'.";

export default class Spread extends Command {
  overview = "Spread the cheese touch to someone else.";
  guildOnly = true;

  constructor(public bot: SaladBot) {
    super();
  }

  async main(ctx: GuildContext) {
    const guild = await this.bot.db.guilds.findOne(ctx.guild.id);
    if (!guild) return ctx.send("This server hasn't been set up.");

    if (
      !ctx.guild.channels.get(guild.cheeseTouchChannel) ||
      !ctx.guild.roles.get(guild.cheeseTouchRole)
    )
      return ctx.send("This server hasn't been set up.");

    const currentCheese = await this.bot.db.cheeseTouchs.findOne({
      guild: { id: guild.id },
    });

    // This shouldn't ever happen
    if (!currentCheese)
      return ctx.send(
        "I couldn't get the latest cheese touch for some reason. Yell at ovy."
      );

    // const currentUser = findCheese(ctx.guild, guild.cheeseTouchRole)!;
    const currentUser = ctx.guild.members.get(currentCheese.user.id)!;
    const possibleTouchee = ctx.mentions[0] as User | undefined;

    if (currentUser.id !== ctx.member!.id) return ctx.send("Nice try, a-hole.");
    else if (!currentCheese.canTransfer)
      return ctx.send("You are unable to spread the cheese touch further!");
    else if (!possibleTouchee || !ctx.guild.members.get(possibleTouchee.id))
      return ctx.send("I have no idea who the fuck that is.");
    else if (possibleTouchee.id === currentUser.id)
      return ctx.send(badDialogue);
    else if (possibleTouchee.bot) return ctx.send(badDialogue);

    const newCheese = ctx.guild.members.get(possibleTouchee.id)!;
    const channel = ctx.guild.channels.get(
      guild.cheeseTouchChannel
    ) as TextChannel;

    await currentUser.removeRole(guild.cheeseTouchRole, "Cheese touch spread");
    await newCheese.addRole(guild.cheeseTouchRole, "Cheese touch spread");

    await this.bot.db[ctx.guild.id].lastCheeseSwap.set(Date.now());
    await this.bot.db[ctx.guild.id].canTransferCheese.set(false);

    await channel.createMessage(
      `${currentUser.mention} spread the cheese touch to ${newCheese.mention}.`
    );
  }
}
