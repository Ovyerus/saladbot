defmodule Salad.Repo.Migrations.GroupSearch do
  @moduledoc false
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION pg_trgm", "DROP EXTENSION pg_trgm"

    # Creating these manually because I couldn't seem to add the `gin_trgm_ops`
    # required by the index. Maybe there's an obscure thing for it, idk.
    execute "CREATE INDEX role_groups_name_index ON role_groups USING gin (name gin_trgm_ops)",
      "DROP INDEX role_groups_name_index"

    execute "CREATE INDEX role_groups_description_index ON role_groups USING gin (description gin_trgm_ops)",
      "DROP INDEX role_groups_description_index"
  end
end
