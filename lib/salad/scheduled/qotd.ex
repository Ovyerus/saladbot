defmodule Salad.Scheduled.Qotd do
  use Oban.Worker, queue: :qotd

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"guild_id" => guild_id}}) do
    case Salad.Qotd.run(guild_id) do
      {:ok, _channel_id, _question} -> :ok
      {:cancel, _reason} -> :ok
      err -> err
    end
  end
end
