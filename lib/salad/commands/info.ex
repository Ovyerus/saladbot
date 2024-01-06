defmodule Salad.Command.Info do
  @moduledoc false
  import Bitwise
  use Salad.CommandSystem.Command
  alias Nostrum.Struct.Embed
  alias Salad.Repo

  @impl true
  def description, do: "Get information for a role group"

  @impl true
  def predicates,
    do: [
      guild_only(),
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

    case Repo.RoleGroup.get_by_name_and_guild(group, ctx.guild_id) do
      nil ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "A role group with that name does not exist.",
            flags: 1 <<< 6
          }
        })

      role_group ->
        {:ok, guild} = Nostrum.Cache.GuildCache.get(ctx.guild_id)

        reply(ctx, %{
          type: 4,
          data: %{
            embeds: [
              %Embed{
                title: "Information for #{role_group.name}",
                description: role_group.description,
                fields:
                  Enum.map(role_group.roles, fn role ->
                    role_name =
                      case guild.roles[role.id] do
                        nil -> "Unknown role"
                        role -> role.name
                      end

                    %Embed.Field{
                      # name: role.name,
                      name: role_name,
                      value: "Assigned via #{role.icon}",
                      inline: true
                    }
                  end)
              }
            ]
          }
        })
    end
  end
end
