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
      extra_applications: [:logger],
      mod: {Salad, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.0"},
      {:emojix, "~> 0.3.1"},
      {:gun, "== 2.0.1", hex: :remedy_gun},
      {:hackney, "~> 1.8"},
      {:jason, "~> 1.1"},
      {:mint, "~> 1.4", override: true},
      {
        :nostrum,
        git: "https://github.com/Ovyerus/nostrum.git",
        ref: "deca1186a6e601289f81e7749e07cbbaaed829fe"
      },
      {:sentry, "8.0.0"},
      {:postgrex, ">= 0.15.13"},
      {:typed_struct, "~> 0.2.1"},
      {:tz, "~> 0.12.0"}
    ]
  end

  defp aliases do
    [
      sentry_recompile: ["compile", "deps.compile sentry --force"]
    ]
  end
end
