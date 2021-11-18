defmodule Salad.Commands.Create do
  @moduledoc false
  use Bitwise
  use Salad.CommandSystem.Command
  require Logger
  alias Salad.Repo

  @impl true
  def description, do: "Create a new role group for your server"

  @impl true
  def predicates,
    do: [
      guild_only(),
      permissions([:manage_guild]),
      guild_setup()
    ]

  @impl true
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
      }
    ]

  @impl true
  def run(ctx) do
    %{"name" => %{value: name}} = ctx.options
    description = Map.get(ctx.options, "description", %{value: nil})

    case Repo.RoleGroup.create(name, description.value, ctx.guild_id) do
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
