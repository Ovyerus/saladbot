import { Entity, PrimaryKey, Property, ManyToOne } from "mikro-orm";

import Guild from "./guild";
import User from "./user";

@Entity()
export default class CheeseTouch {
  @PrimaryKey()
  id!: string;

  @Property()
  timestamp: Date = new Date();

  @Property()
  canTransfer = true;

  @ManyToOne({ eager: true })
  user!: User;

  @ManyToOne({ eager: true })
  guild!: Guild;

  constructor(
    id: string,
    user: User,
    guild: Guild,
    { canTransfer, timestamp }: { canTransfer?: boolean; timestamp?: Date } = {}
  ) {
    this.id = id;
    this.user = user;
    this.guild = guild;

    this.canTransfer = canTransfer ?? this.canTransfer;
    this.timestamp = timestamp ?? this.timestamp;
  }
}
