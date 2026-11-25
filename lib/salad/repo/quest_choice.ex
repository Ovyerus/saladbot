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
          content: String.t(),
          pool: :quest | :prompt
        }
  @typep repo_result() :: {:ok, t()} | {:error, Changeset.t()}

  @required ~w(guild_id content pool)a
  @page_size 8

  schema "quest_choices" do
    field :content, :string
    field :pool, Ecto.Enum, values: [:quest, :prompt], default: :quest
    belongs_to :guild, Repo.Guild, type: :integer
    timestamps()
  end

  def changeset(choice, params \\ %{}) do
    changeset = Changeset.cast(choice, params, @required)
    pool = Changeset.get_field(changeset, :pool)

    changeset
    |> Changeset.validate_required(@required)
    |> Changeset.validate_change(:content, fn :content, content ->
      case Template.validate(content, pool) do
        :ok -> []
        {:error, message} -> [content: message]
      end
    end)
    |> Changeset.foreign_key_constraint(:guild_id)
  end

  @spec create(pos_integer(), String.t(), :quest | :prompt) :: repo_result()
  def create(guild_id, content, pool \\ :quest)
      when is_integer(guild_id) and is_binary(content) do
    %__MODULE__{}
    |> changeset(%{guild_id: guild_id, content: content, pool: pool})
    |> Repo.insert()
  end

  @spec delete(t()) :: repo_result()
  def delete(%__MODULE__{id: id, guild_id: guild_id, pool: pool} = choice) do
    query =
      __MODULE__
      |> where(guild_id: ^guild_id, id: ^id, pool: ^pool)

    case Repo.delete_all(query) do
      {1, _} -> {:ok, choice}
      {0, _} -> {:error, Changeset.add_error(changeset(choice), :id, "no longer exists")}
    end
  end

  @spec get(pos_integer(), pos_integer(), :quest | :prompt) :: t() | nil
  def get(guild_id, id, pool \\ :quest) when is_integer(guild_id) and is_integer(id) do
    __MODULE__
    |> where(guild_id: ^guild_id, id: ^id, pool: ^pool)
    |> Repo.one()
  end

  @spec get_for_guild(pos_integer(), :quest | :prompt) :: list(t())
  def get_for_guild(guild_id, pool \\ :quest) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id, pool: ^pool)
    |> order_by(asc: :inserted_at, asc: :id)
    |> Repo.all()
  end

  def get_page_for_guild(guild_id, requested_page, pool \\ :quest)
      when is_integer(guild_id) and is_integer(requested_page) do
    pool = from(q in __MODULE__, where: q.guild_id == ^guild_id and q.pool == ^pool)
    total = Repo.aggregate(pool, :count)
    pages = max(div(total + @page_size - 1, @page_size), 1)
    page = requested_page |> max(0) |> min(pages - 1)

    choices =
      pool
      |> order_by(asc: :inserted_at, asc: :id)
      |> limit(@page_size)
      |> offset(^(page * @page_size))
      |> Repo.all()

    %{choices: choices, page: page, pages: pages, total: total}
  end

  @spec search_for_guild(pos_integer(), String.t(), :quest | :prompt) :: list(t())
  def search_for_guild(guild_id, text, pool \\ :quest)
      when is_integer(guild_id) and is_binary(text) do
    escaped =
      text
      |> String.replace("\\", "\\\\")
      |> String.replace("%", "\\%")
      |> String.replace("_", "\\_")

    pattern = "%#{escaped}%"

    __MODULE__
    |> where(guild_id: ^guild_id, pool: ^pool)
    |> where(
      [q],
      ilike(q.content, ^pattern) or ilike(fragment("CAST(? AS TEXT)", q.id), ^pattern)
    )
    |> order_by(asc: :inserted_at, asc: :id)
    |> limit(25)
    |> Repo.all()
  end
end
