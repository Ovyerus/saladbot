defmodule Salad.Repo.RoleGroup do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  import Ecto.Changeset

  @type id() :: pos_integer()
  @type name() :: String.t()
  @type description() :: String.t() | nil
  @type guild_id() :: pos_integer()
  @type guild() :: Repo.Guild.t() | nil
  @type roles() :: list(Repo.Role.t()) | nil

  @typep repo_result() :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  @type t() :: %__MODULE__{
          id: id(),
          name: name(),
          description: description(),
          guild_id: guild_id(),
          guild: guild(),
          roles: roles()
        }

  @required ~w(guild_id name)a
  @optional ~w(description)a
  @all @required ++ @optional

  schema "role_groups" do
    field :name, :string
    field :description, :string

    belongs_to :guild, Repo.Guild, type: :integer
    has_many :roles, Repo.Role, foreign_key: :group_id

    timestamps()
  end

  def changeset(role_group, params \\ %{}) do
    role_group
    |> cast(params, @all)
    |> validate_required(@required)
    |> unique_constraint([:name, :guild_id], name: "role_groups_unique_name_per_guild")
  end

  @spec create(name(), description(), guild_id()) :: repo_result()
  def create(name, description, guild_id)
      when is_binary(name) and is_binary(description) and is_integer(guild_id) do
    params = %{
      name: name,
      description: description,
      guild_id: guild_id
    }

    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  # def add_role(%__MODULE__{} = group, role_id) do
  #   group
  #   |> changeset(%{roles: [role_id | group.roles]})
  #   |> Repo.update()
  # end

  @spec get(id()) :: t() | nil
  def get(id) when is_integer(id) do
    __MODULE__
    |> where(id: ^id)
    |> preload(:roles)
    |> Repo.one()
  end

  @spec get_for_guild(guild_id(), integer() | nil) :: list(t())
  def get_for_guild(guild_id, amount \\ nil) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> limit(^amount)
    |> preload(:roles)
    |> Repo.all()
  end

  @spec get_by_name_and_guild(name(), guild_id()) :: t() | nil
  def get_by_name_and_guild(name, guild_id) when is_binary(name) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id, name: ^name)
    |> preload(:roles)
    |> Repo.one()
  end

  @spec search_for_guild(guild_id(), String.t(), integer() | nil) :: list(t())
  def search_for_guild(guild_id, text, amount \\ nil)
      when is_integer(guild_id) and is_binary(text) do
    # Sanitise non-word chars out, and do a partial match
    text = text |> String.replace(~r/\W/u, "") |> then(&"%#{&1}%")

    # TODO: replace with a service like Meilisearch if we need to scale, or need full partial matching
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> where(
      [rg],
      ilike(rg.name, ^text) or (not is_nil(rg.description) and ilike(rg.description, ^text))
    )
    |> order_by([rg], fragment("word_similarity(?, ?) DESC", rg.name, ^text))
    |> limit(^amount)
    |> preload(:roles)
    |> Repo.all()
  end
end
