defmodule Salad.Commands.Prompt do
  @moduledoc false
  use Salad.CommandSystem.Command

  alias Salad.Commands.Quest

  @impl true
  def description, do: "Get a random trivia prompt."

  @impl true
  def predicates, do: Quest.predicates()

  @impl true
  def run(ctx), do: Quest.run(ctx, :prompt)
end
