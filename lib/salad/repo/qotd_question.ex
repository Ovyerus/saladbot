defmodule Salad.Repo.QotdQuestion do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  alias Ecto.Changeset

  @type id() :: pos_integer()
  @type guild_id() :: pos_integer()
  @type content() :: String.t()

  @typep repo_result() :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  @type t() :: %__MODULE__{
          id: id(),
          guild_id: guild_id(),
          content: content(),
          posted_at: NaiveDateTime.t() | nil
        }

  @required ~w(guild_id content)a
  @optional ~w(posted_at)a
  @all @required ++ @optional

  schema "qotd_questions" do
    field :content, :string
    field :posted_at, :naive_datetime

    belongs_to :guild, Repo.Guild, type: :integer
    timestamps()
  end

  def changeset(question, params \\ %{}) do
    question
    |> Changeset.cast(params, @all)
    |> Changeset.validate_required(@required)
  end

  @spec create(guild_id(), content()) :: repo_result()
  def create(guild_id, content) when is_integer(guild_id) and is_binary(content) do
    %__MODULE__{}
    |> changeset(%{guild_id: guild_id, content: content})
    |> Repo.insert()
  end

  @spec delete(t()) :: repo_result()
  def delete(%__MODULE__{} = question) do
    Repo.delete(question)
  end

  @spec get(id()) :: t() | nil
  def get(id) when is_integer(id) do
    Repo.get(__MODULE__, id)
  end

  @spec get_for_guild(guild_id()) :: list(t())
  def get_for_guild(guild_id) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @spec get_next_unposted(guild_id()) :: t() | nil
  def get_next_unposted(guild_id) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> where([q], is_nil(q.posted_at))
    |> order_by(asc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @spec count_unposted(guild_id()) :: non_neg_integer()
  def count_unposted(guild_id) when is_integer(guild_id) do
    __MODULE__
    |> where(guild_id: ^guild_id)
    |> where([q], is_nil(q.posted_at))
    |> Repo.aggregate(:count)
  end

  @spec mark_posted(t()) :: repo_result()
  def mark_posted(%__MODULE__{} = question) do
    question
    |> changeset(%{posted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)})
    |> Repo.update()
  end

  @spec search_for_guild(guild_id(), String.t()) :: list(t())
  def search_for_guild(guild_id, text) when is_integer(guild_id) and is_binary(text) do
    pattern = "%#{String.replace(text, "%", "\\%")}%"

    __MODULE__
    |> where(guild_id: ^guild_id)
    |> where([q], ilike(q.content, ^pattern))
    |> order_by(asc: :inserted_at)
    |> limit(25)
    |> Repo.all()
  end
end
