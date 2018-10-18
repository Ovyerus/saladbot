import {Command, GuildContext} from '@erisa/commands';
import { SaladBot } from '..';
import {ICheeseSettings} from '../types';

export default class ForceSwap extends Command {
    overview = 'Forces a cheese touch swap.';
    guildOnly = true;

    constructor(public bot: SaladBot) {
        super();
    }

    async main(ctx: GuildContext) {
        if (!await this.bot.db.has(ctx.guild.id)) {
            await ctx.send("This server hasn't been set up.");
            return;
        }

        const {
            cheeseChannel,
            cheeseRole,
            lastCheeseSwap
        }: ICheeseSettings = await this.bot.db[ctx.guild.id];

        if (!ctx.guild.channels.get(cheeseChannel) || !ctx.guild.roles.get(cheeseRole)) {
            await ctx.send("This server hasn't been set up.");
            return;
        }

        await this.bot.doCheeseSwap(ctx.guild, true);
    }
}
