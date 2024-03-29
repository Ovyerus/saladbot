import Config

config :elixir, time_zone_database: Tz.TimeZoneDatabase
config :salad, ecto_repos: [Salad.Repo]

config :nostrum,
  request_guild_members: true,
  gateway_intents: [:guild_members, :guild_presences, :guilds, :guild_emojis]

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

config :salad, Oban,
  repo: Salad.Repo,
  queues: [cheese_touch: 10],
  plugins: [
    {
      Oban.Plugins.Pruner,
      # Run every 4 hours
      interval: 1000 * 60 * 60 * 4
    }
  ]

config :salad, Salad.PromEx,
  disabled: false,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  metrics_server: [
    port: 4100
  ]
