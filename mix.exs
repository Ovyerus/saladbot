defmodule Salad.MixProject do
  use Mix.Project

  def project do
    [
      app: :salad,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools, :observer_cli],
      mod: {Salad, []}
    ]
  end

  # When adding/updating dependencies, make sure to run `mix2nix > mix.nix`
  defp deps do
    [
      {:credo, "~> 1.7.8", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:emojix, "~> 0.3.1"},
      {:hackney, "~> 1.8"},
      {:jason, "~> 1.1"},
      {:mint, "~> 1.4", override: true},
      {:nostrum, "~> 0.10"},
      # {:nostrum,
      #  git: "https://github.com/Kraigie/nostrum.git",
      #  ref: "03b06ba1c5094b83991097b1ce76b5fe2740324c"},
      {:oban, "~> 2.16"},
      {:sentry, "~> 10.0"},
      {:postgrex, ">= 0.15.13"},
      {:prom_ex, "~> 1.11"},
      {:typedstruct, "~> 0.5"},
      {:tz, "~> 0.12.0"},
      {:observer_cli, "~> 1.7"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end

  defp aliases do
    [
      sentry_recompile: ["compile", "deps.compile sentry --force"]
    ]
  end
end
