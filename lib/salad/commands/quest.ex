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
  def run(ctx) do
    case Salad.Quest.draw(ctx.guild_id, ctx.user.id, fn message ->
           reply(ctx, %{type: 4, data: message})
         end) do
      {:ok, _choice} ->
        :ok

      {:error, {:delivery_failed, reason}} ->
        Logger.error("Failed to deliver quest for guild #{ctx.guild_id}: #{inspect(reason)}")

      {:error, reason} ->
        reply(ctx, %{
          type: 4,
          data: %{content: error_message(reason), flags: 1 <<< 6, allowed_mentions: %{parse: []}}
        })
    end
  end

  defp error_message({:cooldown, ends_at}) do
    "You can get another quest <t:#{DateTime.to_unix(ends_at)}:R>."
  end

  defp error_message(:empty_pool),
    do: "There are no quests in this server yet. A moderator can add some with `/quest-pool add`."

  defp error_message({:no_role_members, role_id}),
    do:
      "This quest needs a member with role ID #{role_id}, but none are available. Your cooldown hasn't changed."

  defp error_message(:message_too_long),
    do: "That quest is too long to send. Your cooldown hasn't changed."

  defp error_message(reason) do
    Logger.error("Failed to draw quest: #{inspect(reason)}")
    "Failed to get a quest. Your cooldown hasn't changed."
  end
end
