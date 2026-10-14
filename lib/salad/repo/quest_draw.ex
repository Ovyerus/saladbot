defmodule Salad.Repo.QuestDraw do
  @moduledoc false
  use Ecto.Schema

  alias Ecto.Changeset
  alias Salad.Repo

  @cooldown_seconds 2 * 60 * 60
  @reroll_seconds 10 * 60
  @max_rerolls 2

  schema "quest_draws" do
    field :user_id, :integer
    field :drawn_at, :utc_datetime_usec
    field :reroll_count, :integer, default: 0
    belongs_to :guild, Repo.Guild, type: :integer
    belongs_to :choice, Repo.QuestChoice
    timestamps()
  end

  def changeset(draw, params) do
    draw
    |> Changeset.cast(params, [:guild_id, :user_id, :choice_id, :drawn_at, :reroll_count])
    |> Changeset.validate_required([:guild_id, :user_id, :drawn_at, :reroll_count])
    |> Changeset.validate_number(:reroll_count,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: @max_rerolls
    )
    |> Changeset.check_constraint(:reroll_count, name: :quest_draws_reroll_count_range)
    |> Changeset.unique_constraint([:guild_id, :user_id])
  end

  # Both windows are anchored to the original draw, never to its reroll.
  def check(nil, _now), do: {:ok, :draw}

  def check(%__MODULE__{} = draw, now) do
    cooldown_ends = DateTime.add(draw.drawn_at, @cooldown_seconds, :second)
    reroll_ends = DateTime.add(draw.drawn_at, @reroll_seconds, :second)

    cond do
      DateTime.compare(now, cooldown_ends) != :lt ->
        {:ok, :draw}

      draw.reroll_count < @max_rerolls and DateTime.compare(now, reroll_ends) == :lt ->
        {:ok, :reroll}

      true ->
        {:error, {:cooldown, cooldown_ends}}
    end
  end
end
