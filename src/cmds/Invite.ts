import { Command, Context } from "@erisa/commands";
import { Constants } from "eris";

import { SaladBot } from "../saladbot";

const { Permissions } = Constants;
const INVITE_PERMISSIONS =
  Permissions.sendMessages |
  Permissions.readMessages |
  Permissions.readMessageHistory |
  Permissions.manageChannels |
  Permissions.manageRoles |
  Permissions.manageGuild;

export default class Invite extends Command {
  overview = "Gives bot invite link";
  clientID: string;

  constructor(public bot: SaladBot) {
    super();
  }

  async main(ctx: Context) {
    if (!this.clientID) {
      const { id } = await this.bot.getOAuthApplication();

      this.clientID = id;
    }

    await ctx.send(
      `<https://discordapp.com/api/oauth2/authorize?client_id=${this.clientID}&permissions=${INVITE_PERMISSIONS}&scope=bot>`
    );
  }
}
