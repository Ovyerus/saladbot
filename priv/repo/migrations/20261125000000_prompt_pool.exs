defmodule Salad.Repo.Migrations.PromptPool do
  use Ecto.Migration

  def up do
    alter table(:quest_choices) do
      add(:pool, :string, null: false, default: "quest")
    end

    alter table(:quest_draws) do
      add(:pool, :string, null: false, default: "quest")
    end

    drop(index(:quest_choices, [:guild_id]))
    create(index(:quest_choices, [:guild_id, :pool]))
    drop(unique_index(:quest_draws, [:guild_id, :user_id]))
    create(unique_index(:quest_draws, [:guild_id, :user_id, :pool]))

    for table <- [:quest_choices, :quest_draws] do
      create(constraint(table, "#{table}_pool", check: "pool IN ('quest', 'prompt')"))
    end
  end

  def down do
    # Prompt rows have no meaning to versions of the bot that only know quests.
    execute("DELETE FROM quest_draws WHERE pool = 'prompt'")
    execute("DELETE FROM quest_choices WHERE pool = 'prompt'")

    for table <- [:quest_choices, :quest_draws] do
      drop(constraint(table, "#{table}_pool"))
    end

    drop(unique_index(:quest_draws, [:guild_id, :user_id, :pool]))
    create(unique_index(:quest_draws, [:guild_id, :user_id]))
    drop(index(:quest_choices, [:guild_id, :pool]))
    create(index(:quest_choices, [:guild_id]))

    alter table(:quest_draws) do
      remove(:pool)
    end

    alter table(:quest_choices) do
      remove(:pool)
    end
  end
end
