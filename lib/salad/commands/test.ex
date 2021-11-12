defmodule Salad.Commands.Test do
  use Salad.CommandSystem.Command

  def description, do: "Cool test description for a command."
  def options, do: []

  def run(ev) do
    IO.inspect(ev, label: "event")

    Api.create_interaction_response(ev, %{
      type: 4,
      data: %{
        content: "yes this is epic command"
      }
    })
  end
end
