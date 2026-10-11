defmodule Salad.Repo.Migrations.QuestPool do
  use Ecto.Migration

  def change do
    create table(:quest_choices) do
      add(:guild_id, references(:guilds, type: :bigint), null: false)
      add(:content, :text, null: false)

      timestamps()
    end

    create(index(:quest_choices, [:guild_id]))
  end
end
