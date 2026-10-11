defmodule Salad.Repo.QuestChoice do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Ecto.Changeset
  alias Salad.Quest.Template
  alias Salad.Repo

  @type t() :: %__MODULE__{
          id: pos_integer(),
          guild_id: pos_integer(),
          content: String.t()
        }
  @typep repo_result() :: {:ok, t()} | {:error, Changeset.t()}

  @required ~w(guild_id content)a

  schema "quest_choices" do
    field :content, :string
    belongs_to :guild, Repo.Guild, type: :integer
    timestamps()
  end

  def changeset(choice, params \\ %{}) do
    choice
    |> Changeset.cast(params, @required)
    |> Changeset.validate_required(@required)
    |> Changeset.validate_change(:content, fn :content, content ->
      case Template.validate(content) do
        :ok -> []
        {:error, message} -> [content: message]
      end
    end)
    |> Changeset.foreign_key_constraint(:guild_id)
  end

  @spec create(pos_integer(), String.t()) :: repo_result()
  def create(guild_id, content) when is_integer(guild_id) and is_binary(content) do
    %__MODULE__{}
    |> changeset(%{guild_id: guild_id, content: content})
    |> Repo.insert()
  end

  @spec delete(t()) :: repo_result()
  def delete(%__MODULE__{id: id, guild_id: guild_id} = choice) do
    query =
      __MODULE__
      |> where(guild_id: ^guild_id, id: ^id)

    case Repo.delete_all(query) do
      {1, _} -> {:ok, choice}
      {0, _} -> {:error, Changeset.add_error(changeset(choice), :id, "no longer exists")}
    end
  end

  @spec get(pos_integer(), pos_integer()) :: t() | nil
  def get(guild_id, id) when is_integer(guild_id) and is_integer(id) do
    __MODULE__
    |> where(guild_id: ^guild_id, id: ^id)
    |> Repo.one()
  end

  @spec get_for_guild(pos_integer()) :: list(t())
  def get_for_guild(guild_id) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> order_by(asc: :inserted_at, asc: :id)
    |> Repo.all()
  end

  @spec search_for_guild(pos_integer(), String.t()) :: list(t())
  def search_for_guild(guild_id, text) when is_integer(guild_id) and is_binary(text) do
    escaped =
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("%", "\\%")
      |> String.replace("_", "\\_")

    pattern = "%#{escaped}%"

    __MODULE__
    |> where(guild_id: ^guild_id)
    |> where(
      [q],
      ilike(q.content, ^pattern) or ilike(fragment("CAST(? AS TEXT)", q.id), ^pattern)
    )
    |> order_by(asc: :inserted_at, asc: :id)
    |> limit(25)
    |> Repo.all()
  end
end
