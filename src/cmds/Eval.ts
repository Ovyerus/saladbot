import { Command, Context } from "@erisa/commands";

import { SaladBot } from "..";

export default class Eval extends Command {
  overview = "Run l33t hackor codes.";
  ownerOnly = true;

  constructor(public bot: SaladBot) {
    super();
  }

  async main(ctx: Context) {
    if (!ctx.suffix) return ctx.send("Gimme code bitch.");

    let content;

    try {
      content = eval(ctx.suffix);
    } catch (err) {
      content = err;
    }

    await ctx.send(content);
  }
}
