import { Entity, PrimaryKey, OneToMany, Collection } from "mikro-orm";

import CheeseTouch from "./cheese-touch";

@Entity()
export default class User {
  @PrimaryKey()
  id!: string;

  @OneToMany(() => CheeseTouch, (cheeseTouch) => cheeseTouch.user, {
    eager: true,
  })
  cheeseTouchs = new Collection<CheeseTouch>(this);

  constructor(id: string) {
    this.id = id;
  }
}
