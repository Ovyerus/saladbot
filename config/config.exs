import Config

config :elixir, time_zone_database: Tz.TimeZoneDatabase
config :salad, ecto_repos: [Salad.Repo]

config :logger,
  level:
    (case Mix.env() do
       :prod -> :info
       _ -> :debug
     end),
  backends: [:console, Sentry.LoggerBackend],
  truncate: :infinity

config :sentry,
  release: Mix.Project.config()[:version],
  environment_name: Mix.env(),
  included_environments: [:prod],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{env: "production"}

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:guild_id, :interaction_id, :message_id, :user_id]

config :salad,
  sync_dev_guild: Mix.env() == :dev
