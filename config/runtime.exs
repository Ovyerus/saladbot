import Config

config :nostrum,
  token: System.fetch_env!("SALAD_TOKEN")

config :cake, Cake.Repo,
  database: System.get_env("SALAD_DB_NAME", "salad"),
  username: System.get_env("SALAD_DB_USER", "salad"),
  password: System.get_env("SALAD_DB_PASS", "salad"),
  hostname: System.get_env("SALAD_DB_HOST", "localhost")
