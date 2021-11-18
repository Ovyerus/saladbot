defmodule Salad.Repo.Migrations.GroupSearch do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute """
    ALTER TABLE role_groups
    ADD COLUMN search_vector tsvector
    GENERATED ALWAYS AS (
      to_tsvector('english', name || ' ' || coalesce(description, ''))
    ) STORED
    """,
    "ALTER TABLE role_groups DROP COLUMN search_vector"

    create index("role_groups", ["search_vector"], name: :role_groups_searchable_idx, using: "GIN")
  end
end
