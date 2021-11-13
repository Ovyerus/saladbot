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
      add :roles, {:array, :bigint}, default: []
      add :guild_id, references(:guilds)

      timestamps()
    end
  end
end
