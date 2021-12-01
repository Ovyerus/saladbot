defmodule Salad.Repo.RoleGroupMessage do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  import Ecto.Changeset

  @required ~w(message_id channel_id group_id)a

  @primary_key false
  schema "role_group_messages" do
    field :message_id, :integer, primary_key: true
    field :channel_id, :integer, primary_key: true

    belongs_to :role_group, Repo.RoleGroup,
      type: :integer,
      foreign_key: :group_id

    timestamps()
  end

  def changeset(message, params \\ %{}) do
    message
    |> cast(params, @required)
    |> validate_required(@required)
  end

  def create(message_id, channel_id, group_id)
      when is_integer(message_id) and is_integer(channel_id) and is_integer(group_id) do
    params = %{
      message_id: message_id,
      channel_id: channel_id,
      group_id: group_id
    }

    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  def get(message_id, channel_id) when is_integer(message_id) and is_integer(channel_id) do
    __MODULE__
    |> where(message_id: ^message_id, channel_id: ^channel_id)
    |> preload(:role_group)
    |> Repo.one()
  end

  def update(%__MODULE__{} = message) do
    message
    |> change(%{updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)})
    |> Repo.update()
  end
end
