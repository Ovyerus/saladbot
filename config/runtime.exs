import Config

config :nostrum,
  token: System.fetch_env!("SALAD_TOKEN")

config :salad, Salad.Repo,
  database: System.get_env("SALAD_DB_NAME", "salad"),
  username: System.get_env("SALAD_DB_USER", "salad"),
  password: System.get_env("SALAD_DB_PASS", "salad"),
  hostname: System.get_env("SALAD_DB_HOST", "localhost")

config :salad,
  owner: System.fetch_env!("SALAD_OWNER") |> String.to_integer(),
  hmac_key: System.fetch_env!("SALAD_HMAC_KEY"),
  dev_guild: System.fetch_env!("SALAD_DEV_GUILD") |> String.to_integer()
