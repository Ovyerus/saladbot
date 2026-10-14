defmodule Salad.Components.QuestPoolPage do
  @moduledoc false
  use Salad.CommandSystem.Component, type: :button

  alias Nostrum.Api.Interaction
  alias Salad.Commands.QuestPool
  alias Salad.Quest.PoolList

  @impl true
  def run(ev, arg), do: Interaction.create_response(ev, response(ev, arg))

  def response(ev, arg) do
    with {:ok, <<guild_id::unsigned-64, user_id::unsigned-64, page::unsigned-64>>} <-
           Base.url_decode64(arg, padding: false),
         true <- ev.guild_id == guild_id and ev.user.id == user_id,
         true <- access(ev) do
      # Type 7 edits the clicked message, preserving its ephemeral visibility.
      %{type: 7, data: PoolList.page(guild_id, user_id, page)}
    else
      message when is_binary(message) ->
        error(message)

      _ ->
        error(
          "These list buttons are only available to the moderator who opened the list in this server."
        )
    end
  end

  defp access(ev) do
    # Component callbacks bypass the command dispatcher’s predicates.
    Enum.reduce_while(QuestPool.predicates(), true, fn predicate, _ ->
      case predicate.(ev) do
        true -> {:cont, true}
        denied -> {:halt, denied}
      end
    end)
  end

  defp error(content) do
    %{type: 4, data: %{content: content, flags: 64, allowed_mentions: %{parse: []}}}
  end
end
