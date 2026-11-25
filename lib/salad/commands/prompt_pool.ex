defmodule Salad.Commands.PromptPool do
  @moduledoc false
  use Salad.CommandSystem.Command

  alias Salad.Commands.QuestPool

  @impl true
  def name, do: "prompt-pool"

  @impl true
  def description, do: "Manage this server's reusable trivia prompt pool"

  @impl true
  def predicates, do: QuestPool.predicates()

  @impl true
  def options, do: QuestPool.options(:prompt)

  @impl true
  def autocomplete(ev), do: QuestPool.autocomplete(ev, :prompt)

  @impl true
  def run(ctx), do: QuestPool.run(ctx, :prompt)
end
