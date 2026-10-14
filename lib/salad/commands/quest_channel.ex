defmodule Salad.Commands.QuestChannel do
  @moduledoc false
  use Salad.CommandSystem.Command
  require Logger

  alias Nostrum.Constants.ChannelType
  alias Salad.Quest

  @impl true
  def name, do: "quest-channel"

  @impl true
  def description,
    do: "Restrict quests to a channel, or omit the channel to remove the restriction."

  @impl true
  def predicates, do: [guild_only(), permissions([:manage_guild]), guild_setup()]

  @impl true
  def options do
    [
      %Option{
        name: "channel",
        type: Option.Type.channel(),
        description: "Where /quest can be used. Omit to allow it in any channel.",
        channel_types: [ChannelType.guild_text(), ChannelType.guild_announcement()]
      }
    ]
  end

  @impl true
  def run(ctx) do
    channel =
      case ctx.options["channel"] do
        nil -> nil
        %{value: channel} -> channel
      end

    content =
      case Quest.set_channel(ctx.guild_id, channel) do
        {:ok, %{quest_channel: nil}} ->
          "The quest channel restriction is cleared. `/quest` can be used in any channel."

        {:ok, %{quest_channel: channel_id}} ->
          "`/quest` can now only be used in <##{channel_id}>."

        {:error, :invalid_channel} ->
          "Choose a server text or announcement channel."

        {:error, :guild_not_found} ->
          "This server needs to be `/setup`'d before running this command."

        {:error, reason} ->
          Logger.error(
            "Failed to set quest channel for guild #{ctx.guild_id}: #{inspect(reason)}"
          )

          "Failed to change the quest channel restriction."
      end

    reply(ctx, %{type: 4, data: %{content: content, flags: 64, allowed_mentions: %{parse: []}}})
  end
end
