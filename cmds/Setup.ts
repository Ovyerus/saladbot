import {Command, GuildContext} from '@erisa/commands';
import {Constants, TextChannel} from 'eris';
import {SaladBot} from '..';

const {Permissions} = Constants;
const CHEESE_EVERYONE_ALLOW = Permissions.readMessages;
const CHEESE_EVERYONE_DENY = Permissions.sendMessages;
const CHEESE_SELF_ALLOW = CHEESE_EVERYONE_DENY;
const CHEESE_ROLE_ALLOW = Permissions.readMessages | Permissions.sendMessages;
const CHEESE_ROLE_EVERYWHERE_DENY = Permissions.sendMessages;

const HEALTH_SELF_ALLOW = CHEESE_ROLE_ALLOW;
const HEALTH_EVERYONE_DENY = CHEESE_EVERYONE_DENY;

interface IInitialSaladSettings {
    cheeseRole?: string;
    cheeseChannel?: string;
    healthChannel?: string;
}

export default class Setup extends Command {
    overview = 'Sets up special shit.';
    guildOnly = true;
    permissions = {
        self: ['manageRoles', 'manageChannels', 'sendMessages'],
        author: 'manageGuild'
    };
    bot: SaladBot;

    constructor(bot: SaladBot) {
        super();

        this.bot = bot;
    }

    async main(ctx: GuildContext) {
        await ctx.send('Please wait...');
        let {cheeseRole, cheeseChannel, healthChannel}: IInitialSaladSettings = {};

        if (await this.bot.db.has(ctx.guild.id)) {
            ({cheeseRole, cheeseChannel, healthChannel} = await this.bot.db[ctx.guild.id]);

            if (cheeseRole && cheeseChannel && healthChannel
                && ctx.guild.roles.get(cheeseRole)
                && ctx.guild.channels.get(cheeseChannel)
                && ctx.guild.channels.get(healthChannel)) return ctx.send('Server already set up.');
        }

        if (!cheeseRole || !ctx.guild.roles.get(cheeseRole)) {
            const msg = await ctx.send('Cheese touch role not found, creating...');
            let role;

            try {
                role = await ctx.guild.createRole({
                    name: 'Cheese Touch',
                    color: 0xEA931C
                }, 'Setup: cheese touch role');
            } catch (err) {
                console.log(err);
                await msg.edit(`Can't create role: ${err.message}`);
                await ctx.send('Aborting setup. Failed to create cheese touch role.');
                return;
            }

            cheeseRole = role.id;
            await msg.edit(`Successfully created ${role.mention}. Make sure to put this role high enough so that it can give people the colour.`);
        }

        if (!cheeseChannel || !ctx.guild.channels.get(cheeseChannel)) {
            const msg = await ctx.send('Cheese touch channel not found, creating...');
            let channel: TextChannel;

            try {
                channel = await ctx.guild.createChannel('cheese-touch', '0', 'Setup: cheese touch channel') as TextChannel;
            } catch (err) {
                console.log(err);
                await msg.edit(`Can't create channel: ${err.message}`);
                await ctx.send('Aborting setup. Failed to create cheese touch channel.');
                return;
            }

            try {
                await channel.editPermission(ctx.me.id, CHEESE_SELF_ALLOW, 0, 'member', 'Setup: cheese touch channel permissions');
                await channel.editPermission(ctx.guild.id, CHEESE_EVERYONE_ALLOW, CHEESE_EVERYONE_DENY, 'role', 'Setup: cheese touch channel permissions');
                await channel.editPermission(cheeseRole as string, CHEESE_ROLE_ALLOW, 0, 'role', 'Setup: cheese touch channel permissions');
            } catch (err) {
                console.log(err);
                await msg.edit(`Can't setup channel permissions: ${err.message}`);
                await ctx.send('Aborting setup. Failed to set permissions for channels.');
                return;
            }

            try {
                const channelsToPerm = ctx.guild.channels.filter(c => c.id !== channel.id && c.permissionsOf(ctx.me.id).has('manageChannels'));

                for (const chan of channelsToPerm)
                    await chan.editPermission(cheeseRole as string, 0, CHEESE_ROLE_EVERYWHERE_DENY, 'role', 'Setup: cheese role permissions');
            } catch (err) {
                console.log(err);
                await msg.edit(`Can't set permissions for cheese touch role: ${err.message}`);
                await ctx.send('Aborting setup. Failed to set cheese touch role permissions for all channels.');
                return;
            }

            cheeseChannel = channel.id;
            await msg.edit(`Successfully created ${channel.mention} and set up required permissions.`);
        }

        if (!healthChannel || !ctx.guild.channels.get(healthChannel)) {
            const msg = await ctx.send('Health updates channel not found, creating...');
            let channel: TextChannel;

            try {
                channel = await ctx.guild.createChannel('xxxtentacions-health-updates', '0', 'Setup: health updates channel') as TextChannel;
            } catch (err) {
                console.log(err);
                await msg.edit(`Can't create channel: ${err.message}`);
                await ctx.send('Aborting setup. Failed to create health updates channel.');
                return;
            }

            try {
                await channel.editPermission(ctx.me.id, HEALTH_SELF_ALLOW, 0, 'member', 'Setup: health updates permissions');
                await channel.editPermission(ctx.guild.id, 0, HEALTH_EVERYONE_DENY, 'role', 'Setup: health updates permissions');
            } catch (err) {
                console.log(err);
                await msg.edit(`Can't set permissions for health updates channel: ${err.message}`);
                await ctx.send('Aborting setup. Failed to set permissions for the health updates channel.');
                return;
            }

            healthChannel = channel.id;
            await msg.edit(`Successfully created ${channel.mention} and set up required permissions.`);
        }

        await this.bot.db[ctx.guild.id].set({
            cheeseRole,
            cheeseChannel,
            healthChannel,
            canTransferCheese: true,
            lastCheeseSwap: 0,
            lastHealthUpdate: 0
        });

        await this.bot.doCheeseSwap(ctx.guild);
        await this.bot.doHealthUpdate(ctx.guild);
    }
}
