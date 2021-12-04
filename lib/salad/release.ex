defmodule Salad.Release do
  @moduledoc false

  def migrate do
    Ecto.Migrator.with_repo(Salad.Repo, &Ecto.Migrator.run(&1, :up, all: true))
  end

  def rollback(version) do
    Ecto.Migrator.with_repo(Salad.Repo, &Ecto.Migrator.run(&1, :down, to: version))
  end
end
