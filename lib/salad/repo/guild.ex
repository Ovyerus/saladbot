defmodule Salad.Repo.Guild do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  alias Ecto.Changeset

  @type id() :: pos_integer()
  @type role_groups() :: list(Repo.RoleGroup.t()) | nil

  @typep repo_result() :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  @type t() :: %__MODULE__{
          id: id(),
          role_groups: role_groups()
        }

  @required ~w(id)a
  @primary_key {:id, :id, autogenerate: false}

  schema "guilds" do
    has_many :role_groups, Repo.RoleGroup
    timestamps()
  end

  def changeset(guild, params \\ %{}) do
    guild
    |> Changeset.cast(params, @required)
    |> Changeset.validate_required(@required)
  end

  @spec get(id()) :: t() | nil
  def get(id) when is_integer(id) do
    __MODULE__
    |> where(id: ^id)
    |> preload(:role_groups)
    |> Repo.one()
  end

  @spec create(id()) :: repo_result()
  def create(id) when is_integer(id) do
    %__MODULE__{}
    |> changeset(%{id: id})
    |> Repo.insert()
  end
end
