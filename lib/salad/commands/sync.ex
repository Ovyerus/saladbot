defmodule Salad.Commands.Sync do
  @moduledoc false
  import Bitwise
  use Salad.CommandSystem.Command
  alias Nostrum.Struct.Guild.Member
  alias Nostrum.Cache.{Me, GuildCache, MemberCache}
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
    # TODO: unsync
    %{
      "channel" => %{value: %{id: channel_id}}
    } = ctx.options

    guild = GuildCache.get!(ctx.guild_id)
    {:ok, me} = MemberCache.get(guild.id, Me.get().id)
    # me = guild.members[Me.get().id]
    perms = Member.guild_channel_permissions(me, guild, channel_id)

    cond do
      :view_channel not in perms ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "I don't have permission to view that channel.",
            flags: 1 <<< 6
          }
        })

      :send_messages not in perms ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "I don't have permission to send messages in that channel.",
            flags: 1 <<< 6
          }
        })

      true ->
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
                Api.delete_message(msg.channel_id, msg.message_id)
                Repo.RoleGroupMessage.delete(msg)
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
                  {_, no_mentions_args} = Keyword.pop(args, :allowed_mentions)

                  messages
                  |> Enum.filter(fn msg ->
                    NaiveDateTime.compare(msg.updated_at, group.updated_at) == :lt
                  end)
                  |> Enum.each(fn m ->
                    case Api.edit_message(m.channel_id, m.message_id, no_mentions_args) do
                      {:ok, _} ->
                        Repo.RoleGroupMessage.update(m)

                      {:error, %{response: %{code: 10008}}} ->
                        {:ok, msg} = Api.create_message(channel_id, args)
                        Repo.RoleGroupMessage.delete(m)
                        Repo.RoleGroupMessage.create(msg.id, msg.channel_id, group.id)
                    end
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
end
