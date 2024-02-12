defmodule Salad.Repo.Migrations.RolesTable do
  @moduledoc false
  use Ecto.Migration

  import Ecto.Query
  alias Ecto.Multi
  alias Salad.Repo

  def up do
    roles_to_insert =
      "role_groups"
      |> select([rg], {rg.id, rg.roles})
      |> Repo.all()
      |> Enum.flat_map(fn {group_id, roles} ->
        Enum.map(roles, fn role_id ->
          %{
            id: role_id,
            group_id: group_id,
            icon: %{
              id: nil,
              name: "❓"
            },
            inserted_at: NaiveDateTime.utc_now(),
            updated_at: NaiveDateTime.utc_now()
          }
        end)
      end)

    # Create a `roles` table containing role_id, icon (a JSON map), and a reference to the `role_groups` table called `group_id`.
    create table(:roles, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :group_id, references(:role_groups), primary_key: true
      add :icon, :map

      timestamps()
    end

    alter table(:role_groups) do
      remove :roles
    end

    flush()

    Repo.insert_all("roles", roles_to_insert)
  end

  def down do
    roles =
      "roles"
      |> select([r], {r.id, r.group_id})
      |> Repo.all()
      |> Enum.group_by(fn {_, group_id} -> group_id end, fn {id, _} -> id end)

    drop table(:roles)

    alter table(:role_groups) do
      add :roles, {:array, :bigint}, default: []
    end

    flush()

    Enum.each(roles, fn {group_id, role_ids} ->
      "role_groups"
      |> where(id: ^group_id)
      |> Repo.one()
      |> Ecto.Changeset.change(roles: role_ids)
      |> Repo.update()
    end)
  end
end
