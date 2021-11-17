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

  @required ~w(id guild_id roles name)a

  schema "role_groups" do
    field :name, :string
    field :roles, {:array, :integer}
    belongs_to :guild, Repo.Guild, type: :integer

    timestamps()
  end

  def changeset(role_group, params \\ %{}) do
    role_group
    |> Changeset.cast(params, @required)
    |> Changeset.validate_required(@required)
    |> Changeset.validate_length(:roles, min: 1)
  end

  def get(id) do
    __MODULE__
    |> where(id: ^id)
    |> preload(:guild)
    |> Repo.one()
  end
end
