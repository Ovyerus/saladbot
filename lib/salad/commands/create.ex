defmodule Salad.Commands.Create do
  @moduledoc false
  import Bitwise
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
      },
      %{
        name: "display_type",
        type: Option.Type.string(),
        description: "What the role selection should display as when this group is synced",
        choices: [%{name: "Buttons", value: "buttons"}, %{name: "Select menu", value: "select"}]
      }
    ]

  @impl true
  def run(ctx) do
    %{"name" => %{value: name}} = ctx.options
    %{value: description} = Map.get(ctx.options, "description", %{value: nil})
    %{value: display_type} = Map.get(ctx.options, "display_type", %{value: "buttons"})

    case Repo.RoleGroup.create(
           name,
           description,
           # buttons/select atoms are guaranteed to exist due to the role group module.
           String.to_existing_atom(display_type),
           ctx.guild_id
         ) do
      {:ok, group} ->
        reply(ctx, %{
          type: 4,
          data: %{
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
          user_id: ctx.user.id
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
