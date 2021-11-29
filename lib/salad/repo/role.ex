defmodule Salad.Repo.Role do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query
  alias Salad.Repo
  import Ecto.Changeset

  @type id() :: pos_integer()
  @type group_id() :: pos_integer()
  @type icon() :: __MODULE__.Icon.t()
  @type raw_icon() :: __MODULE__.Icon.raw_t()

  @typep repo_result :: {:ok, t()} | {:error, Ecto.Changeset.t()}

  @type t() :: %__MODULE__{
          id: id(),
          group_id: group_id(),
          icon: icon()
        }

  @required ~w(id group_id)a
  @icon_fields ~w(id name)a

  @primary_key false
  schema "roles" do
    field :id, :integer, primary_key: true

    belongs_to :role_group, Repo.RoleGroup,
      type: :integer,
      foreign_key: :group_id,
      primary_key: true

    timestamps()

    embeds_one :icon, Icon, primary_key: false do
      @derive Jason.Encoder

      @type t() :: %__MODULE__{
              id: String.t() | nil,
              name: String.t(),
              animated: boolean()
            }
      @type raw_t() :: %{
              id: String.t() | nil,
              name: String.t(),
              animated: boolean()
            }

      field :id, :string, default: nil
      field :name, :string
      field :animated, :boolean, default: false

      defimpl String.Chars, for: __MODULE__ do
        def to_string(%{id: nil, name: emoji}), do: emoji

        def to_string(%{animated: animated, id: id, name: name}),
          do: "<#{if animated, do: "a"}:#{name}:#{id}>"
      end
    end
  end

  def changeset(role, params \\ %{}) do
    role
    |> cast(params, @required)
    |> cast_embed(:icon, with: &icon_changeset/2)
  end

  defp icon_changeset(schema, params) do
    schema
    |> cast(params, @icon_fields)
    |> validate_required([:name])
  end

  @spec create(id(), group_id(), raw_icon()) :: repo_result()
  def create(id, group_id, icon) do
    params = %{
      id: id,
      group_id: group_id,
      icon: icon
    }

    %__MODULE__{}
    |> changeset(params)
    |> Repo.insert()
  end

  @spec delete(t()) :: repo_result()
  def delete(%__MODULE__{} = role) do
    Repo.delete(role)
  end

  # @spec delete(id(), group_id()) :: repo_result()
  # def delete(id, group_id) do
  #   __MODULE__
  #   |> where(id: ^id, group_id: ^group_id)
  #   |> Repo.one()
  #   |> case do
  #     nil -> {:ok, nil}
  #     x -> Repo.delete(x)
  #   end
  # end
end
