defmodule Salad.Repo.Guild do
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  alias Ecto.Changeset

  @type t() :: %__MODULE__{
          id: pos_integer(),
          role_groups: list(Repo.RoleGroup.t())
        }

  @required ~w(id)a
  @primary_key {:id, :id, autogenerate: false}

  schema "guild" do
    has_many :role_groups, Repo.RoleGroup
    timestamps()
  end

  def changeset(guild, params \\ %{}) do
    guild
    |> Changeset.cast(params, @required)
    |> Changeset.validate_required(@required)
  end

  def get(id) do
    __MODULE__
    |> where(id: ^id)
    |> preload(:role_groups)
    |> Repo.one()
  end
end
