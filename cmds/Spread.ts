import {Command, GuildContext} from '@erisa/commands';
import {TextChannel} from 'eris';
import {findCheese, SaladBot} from '..';
import {ICheeseSettings} from '../types';

const badDialogue = "Oh yeah? You think you're funny? You blithering, wimpy punk? I'll show you 'funny'. I'll go back in time and fart on your dad's balls. You will be eliminated from the gene pool prior to your pitiful conception. Now THAT is 'funny'.";

export default class Spread extends Command {
    overview = 'Spread the cheese touch to someone else.';
    guildOnly = true;

    constructor(public bot: SaladBot) {
        super();
    }

    async main(ctx: GuildContext) {
        if (!await this.bot.db.has(ctx.guild.id))
            return ctx.send("This serrver hasn't been set up.");

        const {
            cheeseChannel,
            cheeseRole,
            canTransferCheese
        }: ICheeseSettings = await this.bot.db[ctx.guild.id];

        if (!ctx.guild.channels.get(cheeseChannel) || !ctx.guild.roles.get(cheeseRole))
            return ctx.send("This server hasn't been set up.");

        const currentCheese = findCheese(ctx.guild, cheeseRole);
        const possibleTouchee = ctx.mentions[0]

        // TODO: can probably do just an equality check
        if (currentCheese.id !== ctx.member!.id)
            return ctx.send('You need to be the current cheese touch to spread it!');
        else if (!canTransferCheese)
            return ctx.send('You are unable to spread the cheese touch further!');
        else if (!possibleTouchee || !ctx.guild.members.get(possibleTouchee.id))
            return ctx.send('I have no idea who the fuck that is.');
        else if (possibleTouchee.id === currentCheese.id)
            return ctx.send(badDialogue);
        else if (possibleTouchee.bot)
            return ctx.send(badDialogue);

        const newCheese = ctx.guild.members.get(possibleTouchee.id)!;
        const channel = ctx.guild.channels.get(cheeseChannel) as TextChannel;

        await currentCheese.removeRole(cheeseRole, 'Cheese touch spread');
        await newCheese.addRole(cheeseRole, 'Cheese touch spread');

        await this.bot.db[ctx.guild.id].lastCheeseSwap.set(Date.now());
        await this.bot.db[ctx.guild.id].canTransferCheese.set(false);

        await channel.createMessage(`${currentCheese.mention} spread the cheese touch to ${newCheese.mention}.`);
    }
}
