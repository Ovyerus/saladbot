defmodule Salad.Quest.TemplateTest do
  use ExUnit.Case, async: false

  alias Nostrum.Cache.MemberCache
  alias Nostrum.Cache.MemberCache.ETS
  alias Salad.Quest.Template

  @max_snowflake 18_446_744_073_709_551_615
  @max_mention "<@#{@max_snowflake}>"
  @max_wrapper "Trick or treat, #{@max_mention}! Your quest is: "

  setup do
    if :ets.whereis(ETS.table()) == :undefined do
      start_supervised!(ETS)
    end

    guild_id = 900_000_000_000_000_000 + 2 * System.unique_integer([:positive])
    {:ok, guild_id: guild_id, other_guild_id: guild_id + 1}
  end

  test "literal choices retain their exact text without enabling incidental mentions", context do
    choice = "  Find a {pumpkin}! 🎃\n@everyone @here <@&123> <@999>  "

    assert :ok = Template.validate(choice)

    assert {:ok,
            %{
              content: "Trick or treat, <@10>! Your quest is: " <> ^choice,
              allowed_mentions: %{parse: [], users: ["10"]}
            }} = Template.render(choice, context.guild_id, 10)
  end

  test "role replacements are guild scoped and repeated tokens share the selected member",
       context do
    cache_member(context.guild_id, 20, [123])
    cache_member(context.guild_id, 30, [456])
    cache_member(context.guild_id, 40, [789])
    cache_member(context.other_guild_id, 99, [123, 456])

    assert {:ok, result} =
             Template.render(
               "Visit {user_from:123}, then {user_from:456}, then {user_from:123}.",
               context.guild_id,
               10
             )

    assert result.content ==
             "Trick or treat, <@10>! Your quest is: Visit <@20>, then <@30>, then <@20>."

    assert result.allowed_mentions.parse == []
    assert Enum.sort(result.allowed_mentions.users) == ["10", "20", "30"]
  end

  test "a role can select the requester without duplicating their mention permission", context do
    cache_member(context.guild_id, 10, [123])

    assert {:ok, result} = Template.render("Greet {user_from:123}.", context.guild_id, 10)
    assert result.content == "Trick or treat, <@10>! Your quest is: Greet <@10>."
    assert result.allowed_mentions == %{parse: [], users: ["10"]}
  end

  test "repeated role selections remain consistent even with multiple eligible members",
       context do
    cache_member(context.guild_id, 20, [123])
    cache_member(context.guild_id, 30, [123])

    assert {:ok, result} =
             Template.render("{user_from:123} and {user_from:123}", context.guild_id, 10)

    [_, [first], [second]] = Regex.scan(~r/<@(\d+)>/, result.content, capture: :all_but_first)
    assert first in ["20", "30"]
    assert first == second
    assert Enum.sort(result.allowed_mentions.users) == Enum.sort(["10", first])
  end

  test "members from another guild or another role cannot satisfy a placeholder", context do
    cache_member(context.other_guild_id, 20, [123])
    cache_member(context.guild_id, 30, [456])

    assert {:error, {:no_role_members, 123}} =
             Template.render("Find {user_from:123}.", context.guild_id, 10)

    assert {:error, {:no_role_members, 999}} =
             Template.render("Find {user_from:999}.", context.guild_id, 10)
  end

  test "a missing role does not produce a partially rendered quest", context do
    cache_member(context.guild_id, 20, [123])

    assert {:error, {:no_role_members, 456}} =
             Template.render("{user_from:123} and {user_from:456}", context.guild_id, 10)
  end

  test "blank content and malformed user_from tokens are rejected" do
    for content <- ["", " ", "\n\t"] do
      assert {:error, _reason} = Template.validate(content)
    end

    for content <- [
          "{user_from}",
          "{user_from:}",
          "{user_from:abc}",
          "{user_from:123",
          "{user_from:123 }",
          "{user_from :123}",
          "{ user_from:123}",
          "{\nuser_from:123}",
          "{user_from:1.5}",
          "{user_from:-1}",
          "{user_from:+1}",
          "{user_from:{user_from:123}}"
        ] do
      assert {:error, reason} = Template.validate(content)
      assert is_binary(reason)
    end
  end

  test "role IDs must be positive uint64 snowflakes" do
    assert :ok = Template.validate("Find {user_from:1}.")
    assert :ok = Template.validate("Find {user_from:#{@max_snowflake}}.")

    for id <- ["0", "000", "18446744073709551616", "999999999999999999999999999999"] do
      assert {:error, _reason} = Template.validate("Find {user_from:#{id}}.")
    end
  end

  test "literal length includes the worst-case requester greeting", context do
    choice = String.duplicate("a", 2000 - byte_size(@max_wrapper))
    assert :ok = Template.validate(choice)
    assert {:error, _reason} = Template.validate(choice <> "a")

    assert {:ok, result} = Template.render(choice, context.guild_id, @max_snowflake)
    assert byte_size(result.content) == 2000

    assert {:error, :message_too_long} =
             Template.render(choice <> "a", context.guild_id, @max_snowflake)
  end

  test "supplementary emoji count as two UTF-16 units", context do
    available = 2000 - byte_size(@max_wrapper)
    choice = "🎃" <> String.duplicate("a", available - 2)

    assert :ok = Template.validate(choice)
    assert {:error, _reason} = Template.validate(choice <> "a")
    assert {:ok, result} = Template.render(choice, context.guild_id, @max_snowflake)
    assert utf16_length(result.content) == 2000
  end

  test "every placeholder reserves the longest possible member mention", context do
    cache_member(context.guild_id, @max_snowflake, [1])
    literal_length = 2000 - byte_size(@max_wrapper) - 2 * byte_size(@max_mention)
    choice = String.duplicate("a", literal_length) <> "{user_from:1}{user_from:1}"

    assert :ok = Template.validate(choice)
    assert {:error, _reason} = Template.validate(choice <> "a")
    assert {:ok, result} = Template.render(choice, context.guild_id, @max_snowflake)
    assert byte_size(result.content) == 2000
    assert result.allowed_mentions == %{parse: [], users: [Integer.to_string(@max_snowflake)]}
  end

  defp cache_member(guild_id, user_id, roles) do
    MemberCache.create(guild_id, %{user: %{id: user_id}, roles: roles})

    on_exit(fn ->
      if :ets.whereis(ETS.table()) != :undefined do
        MemberCache.delete(guild_id, user_id)
      end
    end)
  end

  defp utf16_length(text) do
    text
    |> :unicode.characters_to_binary(:utf8, {:utf16, :big})
    |> byte_size()
    |> div(2)
  end
end
