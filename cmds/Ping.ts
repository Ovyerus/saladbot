import { Command, Context } from "@erisa/commands";

export default class Ping extends Command {
  overview = "Ping commands";

  async main(ctx: Context) {
    const msg = await ctx.send("Pong");
    const time = msg.timestamp - ctx.timestamp;

    await msg.edit(`Pong \`${time}ms\``);
  }
}
