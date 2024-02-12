defmodule Salad.Repo.Guild do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  alias Ecto.Changeset

  @type id() :: pos_integer()
  @type cheese_touch_channel() :: pos_integer() | nil
  @type cheese_touch_role() :: pos_integer() | nil
  @type role_groups() :: list(Repo.RoleGroup.t()) | nil

  @typep repo_result() :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  @type t() :: %__MODULE__{
          id: id(),
          cheese_touch_channel: cheese_touch_channel(),
          cheese_touch_role: cheese_touch_role(),
          role_groups: role_groups()
        }

  @required ~w(id)a
  @optional ~w(cheese_touch_channel cheese_touch_role)a
  @all @required ++ @optional

  @primary_key {:id, :id, autogenerate: false}

  schema "guilds" do
    field :cheese_touch_channel, :integer
    field :cheese_touch_role, :integer
    has_many :role_groups, Repo.RoleGroup
    timestamps()
  end

  def changeset(guild, params \\ %{}) do
    guild
    |> Changeset.cast(params, @all)
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

  def update(%__MODULE__{} = guild, params) do
    guild
    |> changeset(params)
    |> Repo.update()
  end

  # TODO: what was my idea for this...
  def get_all_with_cheese_touch_enabled() do
    []
  end
end
