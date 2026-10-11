defmodule Salad.Repo.QuestDrawTest do
  use ExUnit.Case, async: true

  alias Salad.Repo.QuestDraw

  @drawn_at ~U[2026-10-11 12:00:00.000000Z]

  test "a user without a quest gets a new draw" do
    assert QuestDraw.check(nil, @drawn_at) == {:ok, :draw}
  end

  test "the cooldown ends at exactly two hours, including subsecond boundaries" do
    draw = %QuestDraw{drawn_at: @drawn_at}
    ends_at = DateTime.add(@drawn_at, 7200, :second)

    assert QuestDraw.check(draw, DateTime.add(ends_at, -1, :microsecond)) ==
             {:error, {:cooldown, ends_at}}

    assert QuestDraw.check(draw, ends_at) == {:ok, :draw}
    assert QuestDraw.check(draw, DateTime.add(ends_at, 1, :second)) == {:ok, :draw}
  end

  test "repeat requests automatically reroll until exactly ten minutes" do
    draw = %QuestDraw{drawn_at: @drawn_at}
    ends_at = DateTime.add(@drawn_at, 600, :second)
    cooldown_ends = DateTime.add(@drawn_at, 7200, :second)

    assert QuestDraw.check(draw, @drawn_at) == {:ok, :reroll}
    assert QuestDraw.check(draw, DateTime.add(ends_at, -1, :microsecond)) == {:ok, :reroll}
    assert QuestDraw.check(draw, ends_at) == {:error, {:cooldown, cooldown_ends}}

    assert QuestDraw.check(draw, DateTime.add(ends_at, 1, :second)) ==
             {:error, {:cooldown, cooldown_ends}}
  end

  test "a used reroll blocks further requests until the original cooldown ends" do
    draw = %QuestDraw{drawn_at: @drawn_at, rerolled: true}
    now = DateTime.add(@drawn_at, 60, :second)

    assert QuestDraw.check(draw, now) ==
             {:error, {:cooldown, DateTime.add(@drawn_at, 7200, :second)}}
  end

  test "after two hours a request gets a fresh draw regardless of reroll usage" do
    now = DateTime.add(@drawn_at, 7200, :second)

    for rerolled <- [false, true] do
      draw = %QuestDraw{drawn_at: @drawn_at, rerolled: rerolled}
      assert QuestDraw.check(draw, now) == {:ok, :draw}
    end
  end
end
