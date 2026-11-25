defmodule Salad.Commands.Quest do
  @moduledoc false
  use Salad.CommandSystem.Command
  import Bitwise
  require Logger

  @impl true
  def description, do: "Trick or treat! Get a random quest."

  @impl true
  def predicates, do: [guild_only(), guild_setup()]

  @impl true
  def run(ctx), do: run(ctx, :quest)

  def run(ctx, pool) do
    case Salad.Quest.draw(
           ctx.guild_id,
           ctx.user.id,
           ctx.channel_id,
           fn message -> reply(ctx, %{type: 4, data: message}) end,
           pool
         ) do
      {:ok, _choice} ->
        :ok

      {:error, {:delivery_failed, reason}} ->
        Logger.error("Failed to deliver #{pool} for guild #{ctx.guild_id}: #{inspect(reason)}")

      {:error, reason} ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: error_message(reason, pool),
            flags: 1 <<< 6,
            allowed_mentions: %{parse: []}
          }
        })
    end
  end

  defp error_message({:cooldown, ends_at}, pool) do
    "You can get another #{pool} <t:#{DateTime.to_unix(ends_at)}:R>."
  end

  defp error_message({:wrong_channel, channel_id}, pool),
    do: "Use `/#{pool}` in <##{channel_id}>. Your cooldown and rerolls haven't changed."

  defp error_message(:cheese_touch_disabled, :prompt),
    do:
      "Trivia prompts are disabled until a moderator configures the cheese touch channel and role. Your cooldown hasn't changed."

  defp error_message(:empty_pool, pool),
    do:
      "There are no #{pool}s in this server yet. A moderator can add some with `/#{pool}-pool add`."

  defp error_message({:no_role_members, role_id}, pool),
    do:
      "This #{pool} needs a member with role ID #{role_id}, but none are available. Your cooldown hasn't changed."

  defp error_message(:message_too_long, pool),
    do: "That #{pool} is too long to send. Your cooldown hasn't changed."

  defp error_message(reason, pool) do
    Logger.error("Failed to draw #{pool}: #{inspect(reason)}")
    "Failed to get a #{pool}. Your cooldown hasn't changed."
  end
end
