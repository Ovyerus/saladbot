defmodule Salad.Commands.Remove do
  @moduledoc false
  require Logger
  use Bitwise
  use Salad.CommandSystem.Command
  alias Salad.Repo

  @impl true
  def description, do: "Remove a role from a role group"

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
        name: "group",
        type: Option.Type.string(),
        description: "The name of the group to add the role to",
        required: true,
        autocomplete: true
      },
      %Option{
        name: "role",
        type: Option.Type.role(),
        description: "The role to add to the group",
        required: true
      }
    ]

  @impl true
  def autocomplete(%{data: %{options: options}, guild_id: guild_id}) do
    opt = Enum.find(options, fn opt -> opt.focused end)

    case opt.name do
      "group" ->
        if(opt.value && opt.value != "",
          do: Repo.RoleGroup.search_for_guild(guild_id, opt.value, 25),
          else: Repo.RoleGroup.get_for_guild(guild_id, 25)
        )
        |> Enum.map(fn group -> %{name: group.name, value: group.name} end)

      _ ->
        []
    end
  end

  @impl true
  def run(ctx) do
    %{
      "group" => %{value: group},
      "role" => %{value: role}
    } = ctx.options

    with role_group when role_group != nil <-
           Repo.RoleGroup.get_by_name_and_guild(group, ctx.guild_id),
         %Repo.Role{} = repo_role <-
           Enum.find(role_group.roles, :no_role, fn r -> r.id == role.id end),
         {:ok, _} <- Repo.Role.delete(repo_role) do
      reply(ctx, %{
        type: 4,
        data: %{
          content: "Successfully removed #{role} from the \"#{group}\" group.",
          flags: 1 <<< 6
        }
      })
    else
      nil ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "A role group with that name does not exist.",
            flags: 1 <<< 6
          }
        })

      :no_role ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "That role isn't a part of this group. Try picking another one.",
            flags: 1 <<< 6
          }
        })

      {:error, %Ecto.Changeset{} = err} ->
        Logger.error("Failed to remove role from group `#{group}`: #{inspect(err)}")

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Failed to remove the role from the group.",
            flags: 1 <<< 6
          }
        })
    end
  end
end
