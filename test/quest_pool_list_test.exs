defmodule Salad.Quest.PoolListTest do
  use ExUnit.Case, async: true

  alias Salad.Quest.PoolList
  alias Salad.Repo.QuestChoice

  test "navigation disables only the unavailable directions and encodes bounded destinations" do
    for {page, previous, following, prev_disabled, next_disabled} <- [
          {0, 0, 1, true, false},
          {1, 0, 2, false, false},
          {2, 1, 2, false, true}
        ] do
      data =
        PoolList.render(
          %{
            choices: [%QuestChoice{id: 1, content: "Find a pumpkin."}],
            page: page,
            pages: 3,
            total: 17
          },
          7001,
          9001
        )

      [%{components: [prev, next]}] = data.components
      assert prev.disabled == prev_disabled
      assert next.disabled == next_disabled
      assert destination(prev.custom_id) == {7001, 9001, previous}
      assert destination(next.custom_id) == {7001, 9001, following}
    end
  end

  test "a single page disables both directions" do
    data =
      PoolList.render(
        %{
          choices: [%QuestChoice{id: 1, content: "Find a pumpkin."}],
          page: 0,
          pages: 1,
          total: 1
        },
        7001,
        9001
      )

    [%{components: buttons}] = data.components
    assert Enum.all?(buttons, & &1.disabled)
    assert Enum.all?(buttons, &(destination(&1.custom_id) == {7001, 9001, 0}))
  end

  test "an emptied pool removes previous navigation controls" do
    data = PoolList.render(%{choices: [], page: 0, pages: 1, total: 0}, 7001, 9001)
    assert data.components == []
  end

  test "long emoji previews and largest IDs stay within Discord message and button limits" do
    choices =
      for n <- 1..8 do
        %QuestChoice{id: 9_223_372_036_854_775_807 - n, content: String.duplicate("🎃", 950)}
      end

    max_id = 18_446_744_073_709_551_615
    data = PoolList.render(%{choices: choices, page: 1, pages: 3, total: 24}, max_id, max_id)
    assert String.valid?(data.content)
    assert utf16_length(data.content) <= 2000
    [%{components: buttons}] = data.components

    for button <- buttons do
      assert byte_size(button.custom_id) <= 100
      assert {^max_id, ^max_id, _} = destination(button.custom_id)
    end
  end

  test "quest text cannot enable user, role, or everyone pings on page updates" do
    data =
      PoolList.render(
        %{
          choices: [%QuestChoice{id: 1, content: "@everyone <@123> <@&456>"}],
          page: 0,
          pages: 1,
          total: 1
        },
        7001,
        9001
      )

    assert data.allowed_mentions == %{parse: []}
  end

  defp destination(custom_id) do
    [_name, arg, _signature] = String.split(custom_id, "::")

    <<guild_id::unsigned-64, user_id::unsigned-64, page::unsigned-64>> =
      Base.url_decode64!(arg, padding: false)

    {guild_id, user_id, page}
  end

  defp utf16_length(text) do
    text |> :unicode.characters_to_binary(:utf8, {:utf16, :big}) |> byte_size() |> div(2)
  end
end
