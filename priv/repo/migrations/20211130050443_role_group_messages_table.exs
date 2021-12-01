defmodule Salad.Repo.Migrations.RoleGroupMessagesTable do
  @moduledoc false
  use Ecto.Migration

  def up do
    create table(:role_group_messages, primary_key: false) do
      add :message_id, :bigint, primary_key: true
      add :channel_id, :bigint, primary_key: true
      add :group_id, references(:role_groups, on_delete: :delete_all)

      timestamps()
    end

    drop constraint(:roles, "roles_group_id_fkey")

    alter table(:roles) do
      modify :group_id, references(:role_groups, on_delete: :delete_all)
    end
  end

  def down do
    drop table(:role_group_messages)
    drop constraint(:roles, "roles_group_id_fkey")

    alter table(:roles) do
      modify :group_id, references(:role_groups, on_delete: :nothing)
    end
  end
end
