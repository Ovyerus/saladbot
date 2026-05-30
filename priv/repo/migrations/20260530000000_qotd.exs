defmodule Salad.Repo.Migrations.Qotd do
  use Ecto.Migration

  def change do
    alter table(:guilds) do
      add :qotd_channel, :bigint
      add :qotd_time, :time
    end

    create table(:qotd_questions) do
      add :guild_id, references(:guilds, type: :bigint), null: false
      add :content, :text, null: false
      add :posted_at, :naive_datetime

      timestamps()
    end

    create index(:qotd_questions, [:guild_id])
  end
end
