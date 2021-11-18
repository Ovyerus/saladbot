defmodule Salad.Repo.RoleGroup do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  alias Ecto.Changeset

  @type t() :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          roles: list(pos_integer()),
          guild_id: pos_integer(),
          guild: Repo.Guild.t() | nil
        }

  @required ~w(guild_id roles name)a
  @optional ~w(description)a
  @all @required ++ @optional

  schema "role_groups" do
    field :name, :string
    field :description, :string
    field :roles, {:array, :integer}
    belongs_to :guild, Repo.Guild, type: :integer

    timestamps()
  end

  def changeset(role_group, params \\ %{}) do
    role_group
    |> Changeset.cast(params, @all)
    |> Changeset.validate_required(@required)
    |> Changeset.unique_constraint([:name, :guild_id], name: "role_groups_unique_name_per_guild")
  end

  def create(name, description, guild_id, roles \\ []) do
    params = %{
      name: name,
      description: description,
      guild_id: guild_id,
      roles: roles
    }

    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  def get(id) do
    __MODULE__
    |> where(id: ^id)
    |> preload(:guild)
    |> Repo.one()
  end
end
