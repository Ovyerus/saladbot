defmodule Salad.Components.PromptPoolPage do
  @moduledoc false
  use Salad.CommandSystem.Component, type: :button

  alias Nostrum.Api.Interaction
  alias Salad.Components.QuestPoolPage

  @impl true
  def run(ev, arg), do: Interaction.create_response(ev, QuestPoolPage.response(ev, arg, :prompt))
end
