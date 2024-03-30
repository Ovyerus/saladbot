defmodule Salad.Repo.Migrations.RoleGroupDisplayType do
  use Ecto.Migration

  def change do
    alter table(:role_groups) do
      add :display_type, :text, null: false
    end
  end
end
