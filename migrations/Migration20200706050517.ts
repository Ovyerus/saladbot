import { Migration } from "mikro-orm";

export class Migration20200706050517 extends Migration {
  async up(): Promise<void> {
    this.addSql(
      'create table "cheese_touch" ("id" varchar(255) not null, "timestamp" timestamptz(0) not null, "can_transfer" bool not null, "user_id" varchar(255) not null, "guild_id" varchar(255) not null);'
    );
    this.addSql(
      'alter table "cheese_touch" add constraint "cheese_touch_pkey" primary key ("id");'
    );

    this.addSql(
      'create table "guild" ("id" varchar(255) not null, "health_update_channel" varchar(255) not null, "last_health_update" timestamptz(0) null, "cheese_touch_role" varchar(255) not null, "cheese_touch_channel" varchar(255) not null);'
    );
    this.addSql(
      'alter table "guild" add constraint "guild_pkey" primary key ("id");'
    );

    this.addSql('create table "user" ("id" varchar(255) not null);');
    this.addSql(
      'alter table "user" add constraint "user_pkey" primary key ("id");'
    );

    this.addSql(
      'alter table "cheese_touch" add constraint "cheese_touch_user_id_foreign" foreign key ("user_id") references "user" ("id") on update cascade;'
    );
    this.addSql(
      'alter table "cheese_touch" add constraint "cheese_touch_guild_id_foreign" foreign key ("guild_id") references "guild" ("id") on update cascade;'
    );
  }
}
