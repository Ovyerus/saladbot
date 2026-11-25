defmodule Salad.PromptTest do
  use ExUnit.Case, async: false

  alias Nostrum.Cache.MemberCache
  alias Nostrum.Cache.MemberCache.ETS, as: MemberETS
  alias Nostrum.Cache.GuildCache.ETS, as: GuildETS
  alias Salad.CommandSystem.Component
  alias Salad.Components.{PromptPoolPage, QuestPoolPage}
  alias Salad.Quest.{PoolList, Template}
  alias Salad.Repo.QuestChoice

  @max_snowflake 18_446_744_073_709_551_615
  @max_mention "<@#{@max_snowflake}>"
  @prompt_wrapper "#{@max_mention}, your trivia prompt is: "

  setup do
    if :ets.whereis(MemberETS.table()) == :undefined, do: start_supervised!(MemberETS)
    if is_nil(Process.whereis(GuildETS)), do: start_supervised!(GuildETS)
    guild_id = 800_000_000_000_000_000 + 2 * System.unique_integer([:positive])

    GuildETS.create(%{
      id: guild_id,
      owner_id: 9999,
      roles: [%{id: guild_id, name: "@everyone", permissions: "0"}]
    })

    on_exit(fn ->
      if Process.whereis(GuildETS), do: GuildETS.delete(guild_id)
    end)

    {:ok, guild_id: guild_id, other_guild_id: guild_id + 1}
  end

  test "prompt greeting preserves exact text and does not permit incidental mentions", context do
    content = "  Name a planet. 🌎\n@everyone @here <@&123> <@999> {planet}  "
    assert :ok = Template.validate(content, :prompt)

    assert {:ok,
            %{
              content: "<@10>, your trivia prompt is: " <> ^content,
              allowed_mentions: %{parse: [], users: ["10"]}
            }} = Template.render(content, context.guild_id, 10, :prompt)

    assert {:ok, quest} = Template.render(content, context.guild_id, 10)
    assert quest.content == "Trick or treat, <@10>! Your quest is: " <> content
  end

  test "prompt placeholders stay guild scoped and repeated selections share a mention", context do
    cache_member(context.guild_id, 20, [123])
    cache_member(context.guild_id, 30, [456])
    cache_member(context.other_guild_id, 99, [123, 456])

    assert {:ok, result} =
             Template.render(
               "Ask {user_from:123}, then {user_from:456}, then {user_from:123}.",
               context.guild_id,
               10,
               :prompt
             )

    assert result.content == "<@10>, your trivia prompt is: Ask <@20>, then <@30>, then <@20>."
    assert result.allowed_mentions.parse == []
    assert Enum.sort(result.allowed_mentions.users) == ["10", "20", "30"]
  end

  test "a prompt placeholder may select the requester without duplicate permission", context do
    cache_member(context.guild_id, 10, [123])
    assert {:ok, result} = Template.render("Ask {user_from:123}.", context.guild_id, 10, :prompt)
    assert result.content == "<@10>, your trivia prompt is: Ask <@10>."
    assert result.allowed_mentions == %{parse: [], users: ["10"]}
  end

  test "other guild members cannot satisfy a missing prompt role", context do
    cache_member(context.other_guild_id, 20, [123])
    cache_member(context.guild_id, 30, [456])

    assert {:error, {:no_role_members, 123}} =
             Template.render("Ask {user_from:123}.", context.guild_id, 10, :prompt)
  end

  test "prompt validates the same malformed and out-of-range placeholders" do
    for content <- [
          "",
          " \n",
          "{user_from}",
          "{user_from:}",
          "{user_from:abc}",
          "{user_from:123",
          "{ user_from:123}",
          "{user_from:123 }",
          "{user_from:0}",
          "{user_from:-1}",
          "{user_from:18446744073709551616}"
        ] do
      assert {:error, _reason} = Template.validate(content, :prompt)
    end
  end

  test "prompt length reserves its own shorter wrapper, not the quest greeting", context do
    content = String.duplicate("a", 2000 - byte_size(@prompt_wrapper))
    assert :ok = Template.validate(content, :prompt)
    assert {:error, _reason} = Template.validate(content)
    assert {:error, _reason} = Template.validate(content <> "a", :prompt)

    assert {:ok, result} = Template.render(content, context.guild_id, @max_snowflake, :prompt)
    assert utf16_length(result.content) == 2000

    assert {:error, :message_too_long} =
             Template.render(content <> "a", context.guild_id, @max_snowflake, :prompt)
  end

  test "prompt boundary counts supplementary characters as two UTF-16 units", context do
    available = 2000 - byte_size(@prompt_wrapper)
    content = "🧠" <> String.duplicate("a", available - 2)
    assert :ok = Template.validate(content, :prompt)
    assert {:error, _reason} = Template.validate(content <> "a", :prompt)
    assert {:ok, result} = Template.render(content, context.guild_id, @max_snowflake, :prompt)
    assert utf16_length(result.content) == 2000
  end

  test "prompt reserves a maximum mention for every occurrence of a placeholder", context do
    cache_member(context.guild_id, @max_snowflake, [1])
    available = 2000 - byte_size(@prompt_wrapper) - 2 * byte_size(@max_mention)
    content = String.duplicate("a", available) <> "{user_from:1}{user_from:1}"
    assert :ok = Template.validate(content, :prompt)
    assert {:error, _reason} = Template.validate(content <> "a", :prompt)
    assert {:ok, result} = Template.render(content, context.guild_id, @max_snowflake, :prompt)
    assert utf16_length(result.content) == 2000
    assert result.allowed_mentions == %{parse: [], users: [Integer.to_string(@max_snowflake)]}
  end

  test "prompt pagination signs bounded IDs and carries the correct owner and guild" do
    choices =
      for n <- 1..8 do
        %QuestChoice{id: 9_223_372_036_854_775_807 - n, content: String.duplicate("🧠", 950)}
      end

    for {page, previous, following, prev_disabled, next_disabled} <- [
          {0, 0, 1, true, false},
          {1, 0, 2, false, false},
          {2, 1, 2, false, true}
        ] do
      data =
        PoolList.render(
          %{choices: choices, page: page, pages: 3, total: 24},
          @max_snowflake,
          @max_snowflake,
          :prompt
        )

      assert String.valid?(data.content)
      assert utf16_length(data.content) <= 2000
      assert data.allowed_mentions == %{parse: []}
      [%{components: [prev, next]}] = data.components
      assert prev.disabled == prev_disabled
      assert next.disabled == next_disabled

      for {button, destination} <- [{prev, previous}, {next, following}] do
        assert byte_size(button.custom_id) <= 100
        [name, argument, signature] = String.split(button.custom_id, "::")
        assert name == "promptpoolpage"
        assert byte_size(Base.decode64!(signature)) == 32
        assert button.custom_id == Component.generate_id(PromptPoolPage.name(), argument)

        assert <<@max_snowflake::unsigned-64, @max_snowflake::unsigned-64,
                 ^destination::unsigned-64>> = Base.url_decode64!(argument, padding: false)
      end
    end
  end

  test "empty prompt pagination removes stale controls and mentions" do
    data = PoolList.render(%{choices: [], page: 0, pages: 1, total: 0}, 7001, 9001, :prompt)
    assert data.components == []
    assert data.allowed_mentions == %{parse: []}
    assert data.content =~ "/prompt-pool add"
    refute data.content =~ "/quest-pool"
  end

  test "prompt pagination content cannot activate user, role or everyone mentions" do
    data =
      PoolList.render(
        %{
          choices: [%QuestChoice{id: 1, content: "@everyone <@123> <@&456>"}],
          page: 0,
          pages: 1,
          total: 1
        },
        7001,
        9001,
        :prompt
      )

    assert data.allowed_mentions == %{parse: []}
    [%{components: buttons}] = data.components
    assert Enum.all?(buttons, & &1.disabled)
  end

  test "prompt list buttons reject a different owner, guild or direct message", context do
    argument = argument(context.guild_id, 9001)

    for event <- [
          %{guild_id: context.guild_id, user: %{id: 9002}},
          %{guild_id: context.other_guild_id, user: %{id: 9001}},
          %{guild_id: nil, user: %{id: 9001}}
        ] do
      assert_private_error(QuestPoolPage.response(event, argument, :prompt))
    end
  end

  test "prompt pagination rechecks revoked moderator permissions", context do
    event = %{
      guild_id: context.guild_id,
      user: %{id: 9001},
      member: %Nostrum.Struct.Guild.Member{user_id: 9001, roles: []}
    }

    assert_private_error(QuestPoolPage.response(event, argument(context.guild_id, 9001), :prompt))
  end

  test "malformed prompt pagination arguments fail before pool access", context do
    event = %{guild_id: context.guild_id, user: %{id: 9001}}

    for argument <- ["not-base64!", "", Base.url_encode64(<<1, 2, 3>>, padding: false)] do
      assert_private_error(QuestPoolPage.response(event, argument, :prompt))
    end
  end

  defp assert_private_error(response) do
    assert response.type == 4
    assert response.data.flags == 64
    assert response.data.allowed_mentions == %{parse: []}
    assert is_binary(response.data.content)
  end

  defp argument(guild_id, user_id) do
    Base.url_encode64(<<guild_id::unsigned-64, user_id::unsigned-64, 1::unsigned-64>>,
      padding: false
    )
  end

  defp cache_member(guild_id, user_id, roles) do
    MemberCache.create(guild_id, %{user: %{id: user_id}, roles: roles})

    on_exit(fn ->
      if :ets.whereis(MemberETS.table()) != :undefined, do: MemberCache.delete(guild_id, user_id)
    end)
  end

  defp utf16_length(text) do
    text |> :unicode.characters_to_binary(:utf8, {:utf16, :big}) |> byte_size() |> div(2)
  end
end
