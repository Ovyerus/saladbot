import { Command, GuildContext } from "@erisa/commands";
import { SaladBot } from "..";
import { ICheeseSettings } from "../types";

export default class Casino extends Command {
    overview = "👀";
    guildOnly = true;

    constructor(public bot: SaladBot) {
        super();
    }

    async main(ctx: GuildContext) {
        if (
            !(await this.bot.db.has(ctx.guild.id)) ||
            ctx.author.id !== ctx.guild.ownerID
        )
            return;

        const { aprilFools }: ICheeseSettings = await this.bot.db[ctx.guild.id];

        await this.bot.db[ctx.guild.id].aprilFools.set(!aprilFools);
        await ctx.send("👍");
    }
}
