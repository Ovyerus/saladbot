defmodule Salad.Commands.List do
  @moduledoc false
  use Salad.CommandSystem.Command
  alias Nostrum.Struct.Embed
  alias Salad.Repo

  @impl true
  def description, do: "List role groups for the server"

  @impl true
  def predicates,
    do: [
      guild_only(),
      guild_setup()
    ]

  @impl true
  def run(ctx) do
    case Repo.RoleGroup.get_for_guild(ctx.guild_id) do
      [] ->
        nil

      role_groups ->
        {:ok, guild} = Nostrum.Cache.GuildCache.get(ctx.guild_id)

        # I dont wanna add pagination lol
        reply(ctx, %{
          type: 4,
          data: %{
            embeds: [
              %Embed{
                title: "Role groups for #{guild.name}",
                fields:
                  Enum.map(role_groups, fn group ->
                    %Embed.Field{
                      name: group.name,
                      value: """
                        #{if group.description, do: "> #{group.description}\n"}
                        Contains **#{length(group.roles)}** roles.
                        Use `/info group:#{group.name}` for more info.
                      """
                    }
                  end)
              }
            ]
          }
        })
    end
  end
end

# /info group:dingus
