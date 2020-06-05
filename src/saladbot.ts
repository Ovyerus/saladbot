import { Guild as ErisGuild, TextChannel, Member } from "eris";
import { Erisa } from "erisa";
import { MikroORM, EntityRepository } from "mikro-orm";
import { simpleflake } from "simpleflakes";

import CheeseTouch from "./entities/cheese-touch";
import Guild from "./entities/guild";
import User from "./entities/user";

function sample<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

interface SaladDB {
  orm: MikroORM;
  guilds: EntityRepository<Guild>;
  users: EntityRepository<User>;
  cheeseTouchs: EntityRepository<CheeseTouch>;
}

export const INTERVAL = 1000 * 60 * 60 * 24;
export const TIMER_INTERVAL = 1000 * 60 * 60;

export const findCheese = (
  guild: ErisGuild,
  cheeseRole: string
): Member | undefined =>
  guild.members.find((m) => m.roles.includes(cheeseRole));

export class SaladBot extends Erisa {
  db: SaladDB;
  timer: NodeJS.Timer;
  lastTimerRun: number;

  async doCheeseSwap(guild: ErisGuild, force?: boolean) {
    const dbGuild = await this.db.guilds.findOne(guild.id);
    if (!dbGuild) return;

    const lastSwap = await this.db.cheeseTouchs.findOne({
      guild: { id: guild.id },
    });

    if (
      force ||
      !lastSwap ||
      Date.now() - lastSwap.timestamp.getTime() >= INTERVAL
    ) {
      const channel = guild.channels.get(dbGuild.cheeseTouchChannel) as
        | TextChannel
        | undefined;

      if (!channel) return;

      const currentCheese = findCheese(guild, dbGuild.cheeseTouchRole);
      const eligable = guild.members.filter(
        (m) =>
          (currentCheese ? m.id !== currentCheese.id : true) &&
          !m.bot &&
          !!m.roles.length
      );
      const newCheese = sample<Member | undefined>(eligable);

      if (!newCheese) {
        await channel.createMessage(
          "No eligable person found to give the cheese touch to."
        );
        return;
      }

      if (currentCheese)
        await currentCheese.removeRole(
          dbGuild.cheeseTouchRole,
          "Cheese touch swap"
        );
      await newCheese.addRole(dbGuild.cheeseTouchRole, "Cheese touch swap");

      const cheeseTouchUser =
        (await this.db.users.findOne({ id: newCheese.id })) ??
        new User(newCheese.id);
      const newCheeseTouch = new CheeseTouch(
        simpleflake().toString(),
        cheeseTouchUser,
        dbGuild,
        { canTransfer: true, timestamp: new Date() }
      );

      this.db.orm.em.persist(newCheeseTouch);
      dbGuild.cheeseTouchs.add(newCheeseTouch);
      await this.db.orm.em.flush();

      await channel.createMessage(`${newCheese.mention} has the cheese touch!`);
    }
  }

  async doHealthUpdate(guild: ErisGuild) {
    const dbGuild = await this.db.guilds.findOne(guild.id);
    if (!dbGuild) return;

    if (
      !dbGuild.lastHealthUpdate ||
      Date.now() - dbGuild.lastHealthUpdate.getTime() >= INTERVAL
    ) {
      const channel = guild.channels.get(dbGuild.cheeseTouchChannel) as
        | TextChannel
        | undefined;

      if (!channel) return;

      dbGuild.lastHealthUpdate = new Date();

      await this.db.orm.em.flush();
      await channel.createMessage("He dead.");
    }
  }

  async start() {
    const orm = await MikroORM.init();
    const guilds = orm.em.getRepository(Guild);
    const users = orm.em.getRepository(User);
    const cheeseTouchs = orm.em.getRepository(CheeseTouch);
    this.db = { orm, guilds, users, cheeseTouchs };

    await this.connect();
  }
}
