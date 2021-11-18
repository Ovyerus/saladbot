defmodule Salad.Repo.Migrations.Init do
  @moduledoc false
  use Ecto.Migration

  def change do
    create table(:guilds, primary_key: false) do
      add :id, :bigint, primary_key: true
      timestamps()
    end

    create table(:role_groups) do
      add :name, :string, null: false
      add :description, :string, null: true
      add :roles, {:array, :bigint}, default: []
      add :guild_id, references(:guilds)

      timestamps()
    end

    create index("role_groups", [:name, :guild_id], unique: true, name: "role_groups_unique_name_per_guild")
  end
end
