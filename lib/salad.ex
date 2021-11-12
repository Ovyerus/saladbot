defmodule Salad do
  @moduledoc """
  The Saladbot application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Salad.Repo,
      Salad.Consumer
    ]

    Salad.CommandSystem.setup()
    Supervisor.start_link(children, strategy: :one_for_one, name: Salad)
  end
end
