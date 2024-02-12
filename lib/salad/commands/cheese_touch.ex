defmodule Salad.Commands.CheeseTouch do
  @moduledoc false
  import Bitwise
  require Logger
  use Salad.CommandSystem.Command

  alias Nostrum.Api
  alias Salad.Repo

  @impl true
  def name, do: "cheesetouch"

  @impl true
  def description, do: "Chesee touch related commands"

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
        name: "enable",
        type: Option.Type.subcommand(),
        description: "Enable cheese touch for this server in a certain channel.",
        options: [
          %Option{
            name: "channel",
            type: Option.Type.channel(),
            description: "The channel to use for cheese touch.",
            required: true
          },
          %Option{
            name: "role",
            type: Option.Type.role(),
            description: "The role to use for cheese touch.",
            required: true
          }
        ]
      },
      %Option{
        name: "disable",
        type: Option.Type.subcommand(),
        description: "Disable the cheese touch feature for this server."
      },
      %Option{
        name: "reroll",
        type: Option.Type.subcommand(),
        description: "Force a reroll of the current cheese toucher."
      }
    ]

  @impl true
  def run(ctx) do
    case ctx.options do
      %{"enable" => _} -> run_enable(ctx)
      %{"disable" => _} -> run_disable(ctx)
      %{"reroll" => _} -> run_reroll(ctx)
    end
  end

  defp run_enable(ctx) do
    %{
      "channel" => %{value: channel},
      "role" => %{value: role}
    } = ctx.options["enable"].value

    guild = Nostrum.Cache.GuildCache.get!(ctx.guild_id)
    me = Nostrum.Cache.Me.get()
    {:ok, guild_me} = Nostrum.Cache.MemberCache.get(guild.id, me.id)
    top_role = Nostrum.Struct.Guild.Member.top_role(guild_me, guild)

    with true <- role.id != ctx.guild_id or :everyone_role,
         true <- channel.type == Nostrum.Constants.ChannelType.guild_text() or :not_text_channel,
         true <- (top_role != nil and role.position < top_role.position) or :cannot_assign_role,
         %Repo.Guild{} = guild <- Repo.Guild.get(ctx.guild_id),
         {:ok, _updated} <-
           Repo.Guild.update(guild, %{
             cheese_touch_channel: channel.id,
             cheese_touch_role: role.id
           }) do
      Salad.CheeseTouch.schedule(ctx.guild_id, {5, :seconds})

      # TODO: add reply_msg macros (and take ctx in automatically).
      reply(ctx, %{
        type: 4,
        data: %{
          content:
            "Cheese touch has been enabled in <##{channel.id}>. The first participant will be selected shortly."
        }
      })
    else
      :everyone_role ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "You cannot use the `@everyone` role for cheese touch.",
            flags: 1 <<< 6
          }
        })

      :not_text_channel ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "The channel you selected is not a plain text channel.",
            flags: 1 <<< 6
          }
        })

      :cannot_assign_role ->
        reply(ctx, %{
          type: 4,
          data: %{
            content:
              "I cannot assign that role to users for cheese touch due to being above my highest role. Change the hierarchy or choose a different role.",
            flags: 1 <<< 6
          }
        })

      nil ->
        Logger.error(
          "/cheesetouch enable was somehow able to be run without guild setup. ID: #{ctx.guild_id}"
        )

        reply(ctx, %{
          type: 4,
          data: %{
            content:
              "Uhhh, this shouldn't have happened, but you need to /setup the server first.",
            flags: 1 <<< 6
          }
        })

      err ->
        Logger.error("Failed to enable cheese touch for guild. ID: #{ctx.guild_id}")
        IO.inspect(err)

        reply(ctx, %{
          type: 4,
          data: %{
            content: "An error occurred trying to run that, not sure why.",
            flags: 1 <<< 6
          }
        })
    end
  end

  defp run_disable(ctx) do
    with %Repo.Guild{} = guild <- Repo.Guild.get(ctx.guild_id),
         {:ok, _updated} <-
           Repo.Guild.update(guild, %{cheese_touch_channel: nil, cheese_touch_role: nil}) do
      reply(ctx, %{
        type: 4,
        data: %{
          content: "Cheese touch has been disabled.",
          flags: 1 <<< 6
        }
      })
    end
  end

  defp run_reroll(ctx) do
    with {:ok} <- reply(ctx, %{type: 5, data: %{flags: 1 <<< 6}}),
         {:ok, channel_id, member} <- Salad.CheeseTouch.run(ctx.guild_id, :admin_reroll),
         {:ok, _} <-
           Api.create_message(channel_id, "<@#{member.user_id}> now has the cheese touch!") do
      Api.edit_interaction_response(ctx.token, %{
        content: "Cheese touch has been rerolled and selected <@#{member.user_id}>."
        # flags: 1 <<< 6
      })
    else
      {:cancel, :guild_not_found} ->
        Api.edit_interaction_response(ctx.token, %{
          content: "Cheese touch has not been enabled in this server yet."
        })

      e ->
        e
    end
  end
end
