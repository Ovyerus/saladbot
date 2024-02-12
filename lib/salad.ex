defmodule Salad do
  @moduledoc """
  The Saladbot application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Salad.Repo,
      {Oban, Application.fetch_env!(:salad, Oban)},
      Salad.Consumer
    ]

    :ok = Salad.CommandSystem.setup()
    :ok = Oban.Telemetry.attach_default_logger()

    Supervisor.start_link(children, strategy: :one_for_one, name: Salad)
  end
end
