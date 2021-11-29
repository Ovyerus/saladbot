defmodule Salad.Commands.Sync do
  @moduledoc false
  use Bitwise
  use Salad.CommandSystem.Command
  alias Salad.Components.Role, as: RoleButton
  alias Salad.Repo

  @impl true
  def description, do: "Sync the role groups to a channel so people can use them"

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
        name: "channel",
        type: Option.Type.channel(),
        description: "The channel to sync to",
        required: true,
        channel_types: [0, 5]
      }
    ]

  @impl true
  def run(ctx) do
    %{
      "channel" => %{value: channel}
    } = ctx.options

    case Repo.RoleGroup.get_for_guild(ctx.guild_id) do
      [] ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "No groups found for this server. Use `/create` to create one first.",
            flags: 1 <<< 6
          }
        })

      role_groups ->
        {:ok} = reply(ctx, %{type: 5, data: %{flags: 1 <<< 6}})

        nonempty_groups =
          Enum.filter(role_groups, fn group ->
            length(group.roles) > 0
          end)

        for group <- nonempty_groups do
          # Action rows can only have 5 buttons each
          components =
            group.roles
            |> Enum.map(&RoleButton.new(emoji: &1.icon, arg: &1.id))
            |> Enum.chunk_every(5)
            |> Enum.map(&%ActionRow{components: &1})

          role_list =
            group.roles
            |> Enum.map(fn role -> "#{role.icon} - <@&#{role.id}>" end)
            |> Enum.join("\n")

          {:ok, _} =
            Api.create_message(channel.id,
              content: """
              __**#{group.name}**__#{if group.description, do: "\n> #{group.description}"}

              #{role_list}
              """,
              components: components,
              allowed_mentions: :none
            )

          # TODO: store in db so we can sync properly
        end

        finished = length(nonempty_groups)
        diff = length(role_groups) - finished

        Api.edit_interaction_response(ctx.token, %{
          content:
            "Finished sending messages for `#{finished}` groups, skipped over `#{diff}` empty groups."
        })
    end
  end
end
