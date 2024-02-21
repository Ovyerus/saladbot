defmodule Salad.PromEx do
  use PromEx, otp_app: :cake
  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Ecto, repos: [Salad.Repo]},
      Plugins.Oban
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "mimir",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "ecto.json"},
      {:prom_ex, "oban.json"}
    ]
  end
end
