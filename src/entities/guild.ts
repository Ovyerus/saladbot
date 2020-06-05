import { Entity, PrimaryKey, Property, OneToMany, Collection } from "mikro-orm";

import CheeseTouch from "./cheese-touch";

@Entity()
export default class Guild {
  @PrimaryKey()
  id!: string;

  @Property()
  healthUpdateChannel: string;

  @Property()
  lastHealthUpdate?: Date;

  @Property()
  cheeseTouchRole: string;

  @Property()
  cheeseTouchChannel: string;

  @OneToMany(() => CheeseTouch, (cheeseTouch) => cheeseTouch.guild, {
    eager: true,
  })
  cheeseTouchs = new Collection<CheeseTouch>(this);

  constructor(
    id: string,
    cheeseTouchRole?: string,
    cheeseTouchChannel?: string,
    healthUpdateChannel?: string,
    lastHealthUpdate?: Date
  ) {
    this.id = id;
    this.cheeseTouchRole = cheeseTouchRole!;
    this.cheeseTouchChannel = cheeseTouchChannel!;
    this.healthUpdateChannel = healthUpdateChannel!;
    this.lastHealthUpdate = lastHealthUpdate;
  }
}
