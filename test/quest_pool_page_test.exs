defmodule Salad.Components.QuestPoolPageTest do
  use ExUnit.Case, async: false

  alias Nostrum.Cache.GuildCache.ETS
  alias Salad.Components.QuestPoolPage

  setup do
    if is_nil(Process.whereis(ETS)), do: start_supervised!(ETS)
    guild_id = 900_000_000_000_000_000 + System.unique_integer([:positive])

    ETS.create(%{
      id: guild_id,
      owner_id: 9999,
      roles: [%{id: guild_id, name: "@everyone", permissions: "0"}]
    })

    on_exit(fn ->
      if Process.whereis(ETS), do: ETS.delete(guild_id)
    end)

    {:ok, guild_id: guild_id}
  end

  test "the list owner still needs moderator permissions when navigating", %{guild_id: guild_id} do
    ev = %{
      guild_id: guild_id,
      user: %{id: 9001},
      member: %Nostrum.Struct.Guild.Member{user_id: 9001, roles: []}
    }

    response = QuestPoolPage.response(ev, argument(guild_id, 9001))
    assert response.type == 4
    assert response.data.flags == 64
  end

  test "another user or server cannot reuse the list buttons", %{guild_id: guild_id} do
    arg = argument(guild_id, 9001)

    for ev <- [
          %{guild_id: guild_id, user: %{id: 9002}},
          %{guild_id: guild_id + 1, user: %{id: 9001}},
          %{guild_id: nil, user: %{id: 9001}}
        ] do
      response = QuestPoolPage.response(ev, arg)
      assert response.type == 4
      assert response.data.flags == 64
    end
  end

  test "malformed button arguments are rejected without fetching pool data", %{guild_id: guild_id} do
    ev = %{guild_id: guild_id, user: %{id: 9001}}

    for arg <- ["not-base64!", "", Base.url_encode64(<<1, 2, 3>>, padding: false)] do
      response = QuestPoolPage.response(ev, arg)
      assert response.type == 4
      assert response.data.flags == 64
    end
  end

  defp argument(guild_id, user_id) do
    Base.url_encode64(<<guild_id::unsigned-64, user_id::unsigned-64, 1::unsigned-64>>,
      padding: false
    )
  end
end
