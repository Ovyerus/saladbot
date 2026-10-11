defmodule Salad.Repo.Migrations.QuestDraws do
  use Ecto.Migration

  def change do
    create table(:quest_draws) do
      add(:guild_id, references(:guilds, type: :bigint), null: false)
      add(:user_id, :bigint, null: false)
      add(:choice_id, references(:quest_choices, on_delete: :nilify_all))
      add(:drawn_at, :utc_datetime_usec, null: false)
      add(:rerolled, :boolean, null: false, default: false)
      timestamps()
    end

    create(unique_index(:quest_draws, [:guild_id, :user_id]))
  end
end
