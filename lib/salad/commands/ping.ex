defmodule Salad.Command.Ping do
  @moduledoc false
  import Bitwise
  use Salad.CommandSystem.Command

  @impl true
  def description, do: "Pong"

  @impl true
  def run(ctx) do
    reply(ctx, %{
      type: 4,
      data: %{
        content: "Pong!",
        flags: 1 <<< 6
      }
    })
  end
end
