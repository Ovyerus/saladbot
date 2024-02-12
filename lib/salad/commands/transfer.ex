defmodule Salad.Commands.Transfer do
  @moduledoc false
  import Bitwise
  use Salad.CommandSystem.Command
  alias Salad.Repo

  @impl true
  def description, do: "Transfer the cheese touch to another user."

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
        name: "user",
        type: Option.Type.user(),
        description: "The user to spread the cheese touch to.",
        required: true
      }
    ]

  @impl true
  def run(ctx) do
    %{
      "user" => %{value: user}
    } = ctx.options

    {:ok, member} = Nostrum.Cache.MemberCache.get(ctx.guild_id, user.id)

    with %Repo.Guild{cheese_touch_channel: channel_id, cheese_touch_role: role_id}
         when channel_id != nil and role_id != nil <- Repo.Guild.get(ctx.guild_id),
         true <- role_id in ctx.member.roles or :not_cheesed,
         {:ok} <- reply(ctx, %{type: 5, data: %{flags: 1 <<< 6}}),
         {:ok, channel_id, member} <- Salad.CheeseTouch.run(ctx.guild_id, :transfer, member),
         {:ok, _} <-
           Api.create_message(
             channel_id,
             "<@#{ctx.member.user_id}> has passed the cheese touch onto <@#{member.user_id}>!"
           ) do
      Api.edit_interaction_response(ctx.token, %{
        content: "Cheese touch has successfully been transferred to <@#{member.user_id}>."
      })
    else
      %Repo.Guild{} ->
        Api.edit_interaction_response(ctx.token, %{
          content: "Cheese touch has not been enabled in this server yet."
        })

      :not_cheesed ->
        Api.edit_interaction_response(ctx.token, %{
          content: "You don't have the cheese touch yet, silly."
        })

      e ->
        e
    end

    nil
  end
end
