defmodule Salad.Commands.Delete do
  @moduledoc false
  require Logger
  import Bitwise
  use Salad.CommandSystem.Command
  alias Salad.Repo

  @impl true
  def description, do: "Delete a role group"

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
        description: "The name of the group to delete",
        required: true,
        autocomplete: true
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
      "group" => %{value: group}
    } = ctx.options

    with role_group when role_group != nil <-
           Repo.RoleGroup.get_by_name_and_guild(group, ctx.guild_id),
         {:ok, _} <- Repo.RoleGroup.delete(role_group) do
      reply(ctx, %{
        type: 4,
        data: %{
          content: "Successfully deleted the group \"#{group}\".",
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

      {:error, %Ecto.Changeset{} = err} ->
        Logger.error("Failed to delete group `#{group}`: #{inspect(err)}")

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Failed to delete the group.",
            flags: 1 <<< 6
          }
        })
    end
  end
end
