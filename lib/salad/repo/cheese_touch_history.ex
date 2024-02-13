defmodule Salad.Repo.CheeseTouchHistory do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  alias Ecto.Changeset

  @type user_id() :: integer()
  @type reason() :: :automatic | :transfer
  @type guild() :: Repo.Guild.t()

  @type t() :: %__MODULE__{
          user_id: user_id(),
          reason: reason(),
          guild: guild()
        }

  @required ~w(user_id reason guild_id)a

  schema "cheese_touch_history" do
    field :user_id, :integer
    field :reason, Ecto.Enum, values: [:automatic, :transfer, :admin_reroll]

    belongs_to :guild, Repo.Guild, type: :integer
    timestamps()
  end

  def changeset(history, params \\ %{}) do
    history
    |> Changeset.cast(params, @required)
    |> Changeset.validate_required(@required)
  end

  def create(guild_id, user_id, reason) when is_integer(guild_id) and is_integer(user_id) do
    %__MODULE__{}
    |> changeset(%{guild_id: guild_id, user_id: user_id, reason: reason})
    |> Repo.insert()
  end

  def get_last_n_for_guild(guild_id, amt \\ 5) do
    __MODULE__
    |> select([c], c.user_id)
    |> where(guild_id: ^guild_id)
    |> order_by(desc: :inserted_at)
    |> limit(^amt)
    |> Repo.all()
  end

  def get_last_for_guild(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end
end
