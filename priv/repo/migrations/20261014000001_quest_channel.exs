defmodule Salad.Repo.Migrations.QuestChannel do
  use Ecto.Migration

  def change do
    alter table(:guilds) do
      add(:quest_channel, :bigint)
    end
  end
end
