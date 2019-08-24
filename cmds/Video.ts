import {Command, GuildContext} from '@erisa/commands';

export default class Video extends Command {
    overview = 'Give a link to the current voice channel for video.';
    guildOnly = true;

    async main(ctx: GuildContext) {
        const {voiceState: {channelID}} = ctx.member!;

        if (!channelID) return ctx.send('You need to join a voice channel to use this.');

        await ctx.send(`Click this link while in **<#${channelID}>** to switch to video: <https://discordapp.com/channels/${ctx.guild.id}/${channelID}>`);
    }
}
