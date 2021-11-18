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

  def get_for_guild(guild_id, amount \\ nil) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> limit(^amount)
    |> Repo.all()
  end

  def get_by_name_and_guild(guild_id, name) do
    __MODULE__
    |> where(guild_id: ^guild_id, name: ^name)
    |> Repo.one()
  end

  def search_for_guild(guild_id, text, amount \\ nil) do
    # Sanitise non-word chars out, and do a partial match
    text = String.replace(text, ~r/\W/u, "") <> ":*"

    # TODO: replace with a service like Meilisearch if we need to scale, or need full partial matching
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> where(fragment("search_vector @@ to_tsquery('simple', ?)", ^text))
    |> order_by(fragment("ts_rank(search_vector, to_tsquery('simple', ?)) DESC", ^text))
    |> limit(^amount)
    |> Repo.all()
  end
end
