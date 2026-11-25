defmodule Salad.Scheduled.CheeseTouch do
  use Oban.Worker, queue: :cheese_touch

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"guild_id" => guild_id}}) do
    with {:ok, channel_id, member} <- Salad.CheeseTouch.run(guild_id, :automatic),
         {:ok, _} <-
           Nostrum.Api.create_message(
             channel_id,
             Salad.CheeseTouch.announcement(member.user_id)
           ) do
      :ok
    end
  end
end
