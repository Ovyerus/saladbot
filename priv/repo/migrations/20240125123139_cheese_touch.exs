defmodule Salad.Repo.Migrations.CheeseTouch do
  use Ecto.Migration

  def change do
    alter table(:guilds) do
      add :cheese_touch_channel, :bigint
      add :cheese_touch_role, :bigint
    end

    create table(:cheese_touch_history) do
      add :user_id, :bigint, null: false
      add :reason, :string, null: false
      add :guild_id, references(:guilds, type: :bigint), null: false

      timestamps()
    end
  end
end
