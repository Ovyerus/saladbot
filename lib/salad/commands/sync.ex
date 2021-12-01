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
      "channel" => %{value: %{id: channel_id}}
    } = ctx.options

    case Repo.RoleGroup.get_for_guild_with_messages_in_channel(ctx.guild_id, channel_id) do
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
          Enum.filter(role_groups, fn
            %{roles: []} -> false
            _ -> true
          end)

        empty_groups_with_messages =
          Enum.filter(role_groups, fn
            %{roles: [], messages: [_ | _]} -> true
            _ -> false
          end)

        # Clean up any messages from a now empty group
        for group <- empty_groups_with_messages do
          for msg <- group.messages do
            case Api.delete_message(msg.channel_id, msg.message_id) do
              {:ok} -> Repo.RoleGroupMessage.delete(msg)
              _ -> :noop
            end
          end
        end

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

          args = [
            content: """
            __**#{group.name}**__#{if group.description, do: "\n> #{group.description}"}

            #{role_list}
            """,
            components: components,
            allowed_mentions: :none
          ]

          case group.messages do
            [] ->
              {:ok, msg} = Api.create_message(channel_id, args)
              Repo.RoleGroupMessage.create(msg.id, msg.channel_id, group.id)

            messages ->
              # TODO: pr to allow allowed_mentions on edit
              {_, args} = Keyword.pop(args, :allowed_mentions)

              messages
              |> Enum.filter(fn msg ->
                NaiveDateTime.compare(msg.updated_at, group.updated_at) == :lt
              end)
              |> Enum.each(fn m ->
                # TODO: handle messages manually deleted, create new one
                {:ok, _} = Api.edit_message(m.channel_id, m.message_id, args)
                Repo.RoleGroupMessage.update(m)
              end)
          end
        end

        finished = length(nonempty_groups)
        diff = length(role_groups) - finished

        Api.edit_interaction_response(ctx.token, %{
          content:
            "Finished syncing messages for `#{finished}` groups in <##{channel_id}>, skipped over `#{diff}` empty groups."
        })
    end
  end
end
