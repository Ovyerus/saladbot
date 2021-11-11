defmodule Salad.MixProject do
  use Mix.Project

  def project do
    [
      app: :salad,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:gun, "== 2.0.1", hex: :remedy_gun},
      {
        :nostrum,
        git: "https://github.com/Kraigie/nostrum.git",
        ref: "b4daaf30c0c1a4b246a3aaecfdbd96490c708484"
      },
      {:postgrex, ">= 0.15.13"},
      {:typed_struct, "~> 0.2.1"},
      {:tz, "~> 0.12.0"}
    ]
  end
end
