import { Command, GuildContext } from "@erisa/commands";
import { Constants, TextChannel, Role } from "eris";

import Guild from "../entities/guild";
import { SaladBot } from "../saladbot";

const { Permissions } = Constants;
const CHEESE_EVERYONE_ALLOW = Permissions.readMessages;
const CHEESE_EVERYONE_DENY = Permissions.sendMessages;
const CHEESE_SELF_ALLOW = CHEESE_EVERYONE_DENY;
const CHEESE_ROLE_ALLOW = Permissions.readMessages | Permissions.sendMessages;

const HEALTH_SELF_ALLOW = CHEESE_ROLE_ALLOW;
const HEALTH_EVERYONE_DENY = CHEESE_EVERYONE_DENY;

// interface IInitialSaladSettings {
//   cheeseRole?: string;
//   cheeseChannel?: string;
//   healthChannel?: string;
// }

export default class Setup extends Command {
  overview = "Sets up special shit.";
  guildOnly = true;
  permissions = {
    self: ["manageRoles", "manageChannels", "sendMessages"],
    author: "manageGuild",
  };

  bot: SaladBot;

  constructor(bot: SaladBot) {
    super();

    this.bot = bot;
  }

  async main(ctx: GuildContext) {
    await ctx.send("Please wait...");
    // const guild = new Guild(ctx.guild.id);
    const guild =
      (await this.bot.db.guilds.findOne({
        id: ctx.guild.id,
      })) ?? new Guild(ctx.guild.id);

    if (
      guild.cheeseTouchChannel &&
      guild.cheeseTouchRole &&
      guild.healthUpdateChannel &&
      ctx.guild.roles.get(guild.cheeseTouchRole) &&
      ctx.guild.channels.get(guild.cheeseTouchChannel) &&
      ctx.guild.channels.get(guild.healthUpdateChannel)
    )
      return ctx.send("Server already set up.");

    if (!guild.cheeseTouchRole || !ctx.guild.roles.get(guild.cheeseTouchRole)) {
      const msg = await ctx.send("Cheese touch role not found, creating...");
      let role: Role;

      try {
        role = await ctx.guild.createRole(
          {
            name: "Cheese Touch",
            color: 0xea931c,
          },
          "Setup: cheese touch role"
        );
      } catch (err) {
        console.log(err);
        await msg.edit(`Can't create role: ${err.message as string}`);
        await ctx.send("Aborting setup. Failed to create cheese touch role.");
        return;
      }

      guild.cheeseTouchRole = role.id;
      await msg.edit(
        `Successfully created ${role.mention}. Make sure to put this role high enough so that it can give people the colour.`
      );
    }

    if (
      !guild.cheeseTouchChannel ||
      !ctx.guild.channels.get(guild.cheeseTouchChannel)
    ) {
      const msg = await ctx.send("Cheese touch channel not found, creating...");
      let channel: TextChannel;

      try {
        channel = (await ctx.guild.createChannel(
          "cheese-touch",
          "0",
          "Setup: cheese touch channel"
        )) as TextChannel;
      } catch (err) {
        console.log(err);
        await msg.edit(`Can't create channel: ${err.message as string}`);
        await ctx.send(
          "Aborting setup. Failed to create cheese touch channel."
        );
        return;
      }

      try {
        await channel.editPermission(
          ctx.me.id,
          CHEESE_SELF_ALLOW,
          0,
          "member",
          "Setup: cheese touch channel permissions"
        );
        await channel.editPermission(
          ctx.guild.id,
          CHEESE_EVERYONE_ALLOW,
          CHEESE_EVERYONE_DENY,
          "role",
          "Setup: cheese touch channel permissions"
        );
        await channel.editPermission(
          guild.cheeseTouchRole,
          CHEESE_ROLE_ALLOW,
          0,
          "role",
          "Setup: cheese touch channel permissions"
        );
      } catch (err) {
        console.log(err);
        await msg.edit(
          `Can't setup channel permissions: ${err.message as string}`
        );
        await ctx.send(
          "Aborting setup. Failed to set permissions for channels."
        );
        return;
      }

      guild.cheeseTouchChannel = channel.id;
      await msg.edit(
        `Successfully created ${channel.mention} and set up required permissions.`
      );
    }

    if (
      !guild.healthUpdateChannel ||
      !ctx.guild.channels.get(guild.healthUpdateChannel)
    ) {
      const msg = await ctx.send(
        "Health updates channel not found, creating..."
      );
      let channel: TextChannel;

      try {
        channel = (await ctx.guild.createChannel(
          "xxxtentacions-health-updates",
          "0",
          "Setup: health updates channel"
        )) as TextChannel;
      } catch (err) {
        console.log(err);
        await msg.edit(`Can't create channel: ${err.message as string}`);
        await ctx.send(
          "Aborting setup. Failed to create health updates channel."
        );
        return;
      }

      try {
        await channel.editPermission(
          ctx.me.id,
          HEALTH_SELF_ALLOW,
          0,
          "member",
          "Setup: health updates permissions"
        );
        await channel.editPermission(
          ctx.guild.id,
          0,
          HEALTH_EVERYONE_DENY,
          "role",
          "Setup: health updates permissions"
        );
      } catch (err) {
        console.log(err);
        await msg.edit(
          `Can't set permissions for health updates channel: ${
            err.message as string
          }`
        );
        await ctx.send(
          "Aborting setup. Failed to set permissions for the health updates channel."
        );
        return;
      }

      guild.healthUpdateChannel = channel.id;
      await msg.edit(
        `Successfully created ${channel.mention} and set up required permissions.`
      );
    }

    await this.bot.db.orm.em.flush();

    await this.bot.doCheeseSwap(ctx.guild);
    await this.bot.doHealthUpdate(ctx.guild);
  }
}
