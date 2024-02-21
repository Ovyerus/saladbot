import Config

config :nostrum,
  token: System.fetch_env!("SALAD_TOKEN")

config :sentry,
  dsn: System.get_env("SALAD_SENTRY_DSN", nil)

config :salad, Salad.Repo,
  database: System.get_env("SALAD_DB_NAME", "salad"),
  username: System.get_env("SALAD_DB_USER", "salad"),
  password: System.get_env("SALAD_DB_PASS", "salad"),
  hostname: System.get_env("SALAD_DB_HOST", "localhost")

config :salad,
  owner: System.fetch_env!("SALAD_OWNER") |> String.to_integer(),
  hmac_key: System.fetch_env!("SALAD_HMAC_KEY"),
  dev_guild: System.fetch_env!("SALAD_DEV_GUILD") |> String.to_integer()

config :salad, Salad.PromEx,
  grafana:
    (case(System.get_env("SALAD_GRAFANA_ENABLED")) do
       x when x in ["1", "true", "TRUE"] ->
         [
           host: System.fetch_env!("SALAD_GRAFANA_HOST"),
           auth_token: System.fetch_env!("SALAD_GRAFANA_TOKEN"),
           upload_dashboards_on_start: true
         ]

       _ ->
         :disabled
     end)
