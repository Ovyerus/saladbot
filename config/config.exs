import Config

config :elixir, time_zone_database: Tz.TimeZoneDatabase
config :salad, ecto_repos: [Salad.Repo]

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:guild_id, :interaction_id, :message_id, :user_id]
