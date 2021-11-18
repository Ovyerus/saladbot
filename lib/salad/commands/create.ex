defmodule Salad.Commands.Create do
  @moduledoc false
  use Bitwise
  use Salad.CommandSystem.Command
  require Logger
  alias Salad.Repo

  def description, do: "Create a new role group for your server"

  def predicates,
    do: [
      guild_only(),
      permissions([:manage_guild]),
      guild_setup()
    ]

  def options,
    do: [
      %Option{
        name: "name",
        type: Option.Type.string(),
        description: "The name of the new role group",
        required: true
      },
      %Option{
        name: "description",
        type: Option.Type.string(),
        description: "The description for the group"
      },
      %Option{
        name: "initial_role",
        type: Option.Type.role(),
        description: "The first role to add to the group"
      }
    ]

  @spec run(Context.t()) :: any()
  def run(ctx) do
    %{"name" => %{value: name}} = ctx.options
    description = Map.get(ctx.options, "description", %{value: nil})

    initial_role =
      case Map.get(ctx.options, "initial_role") do
        nil -> []
        %{value: value} -> [value.id]
      end

    case Repo.RoleGroup.create(name, description.value, ctx.guild_id, initial_role) do
      {:ok, group} ->
        reply(ctx, %{
          type: 4,
          data: %{
            # TODO: extra line when role provided
            content:
              "Successfully made group `#{group.name}`. You can now run `/add #{group.name}` to add some roles to the group.",
            flags: 1 <<< 6
          }
        })

      {:error, %Ecto.Changeset{errors: [name: {"has already been taken", _}]}} ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "A role group with that name already exists. Try something else.",
            flags: 1 <<< 6
          }
        })

      {:error, err} ->
        Logger.error("Failed to create role group: #{inspect(err)}",
          guild_id: ctx.guild_id,
          interaction_id: ctx.id,
          user_id: ctx.member.user.id
        )

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Failed to create role group. Sorry.",
            flags: 1 <<< 6
          }
        })
    end
  end
end
