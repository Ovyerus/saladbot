defmodule Salad.Repo.Migrations.QuestRerollCount do
  use Ecto.Migration

  def up do
    alter table(:quest_draws) do
      add(:reroll_count, :integer, null: false, default: 0)
    end

    flush()
    execute("UPDATE quest_draws SET reroll_count = CASE WHEN rerolled THEN 1 ELSE 0 END")

    alter table(:quest_draws) do
      remove(:rerolled)
    end

    create(
      constraint(:quest_draws, :quest_draws_reroll_count_range,
        check: "reroll_count BETWEEN 0 AND 2"
      )
    )
  end

  def down do
    drop(constraint(:quest_draws, :quest_draws_reroll_count_range))

    alter table(:quest_draws) do
      add(:rerolled, :boolean, null: false, default: false)
    end

    flush()
    execute("UPDATE quest_draws SET rerolled = reroll_count > 0")

    alter table(:quest_draws) do
      remove(:reroll_count)
    end
  end
end
