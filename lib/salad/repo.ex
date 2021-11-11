defmodule Salad.Repo do
  use Ecto.Repo,
    otp_app: :salad,
    adapter: Ecto.Adapters.Postgres
end
