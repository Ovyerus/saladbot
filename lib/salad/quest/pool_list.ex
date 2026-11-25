defmodule Salad.Quest.PoolList do
  @moduledoc false

  alias Salad.CommandSystem.Structs.Components.ActionRow
  alias Salad.Components.{PromptPoolPage, QuestPoolPage}
  alias Salad.Repo.QuestChoice

  def page(guild_id, user_id, requested_page \\ 0, pool \\ :quest) do
    guild_id
    |> QuestChoice.get_page_for_guild(requested_page, pool)
    |> render(guild_id, user_id, pool)
  end

  def render(data, guild_id, user_id, pool \\ :quest)

  def render(%{total: 0}, _guild_id, _user_id, pool) do
    %{
      content: "This server's #{pool} pool is empty. Add a #{pool} with `/#{pool}-pool add`.",
      components: [],
      allowed_mentions: %{parse: []}
    }
  end

  def render(%{choices: choices, page: page, pages: pages, total: total}, guild_id, user_id, pool) do
    lines =
      Enum.map(choices, fn choice ->
        preview = choice.content |> String.replace(~r/\s+/u, " ") |> truncate(180)
        "`#{choice.id}`: #{preview}\n"
      end)

    # Eight bounded previews plus IDs/header fit within Discord's 2000 UTF-16 units.
    content =
      IO.iodata_to_binary([
        "#{String.capitalize(to_string(pool))}s in this server's pool (ID: #{pool}):\n",
        lines,
        "\nPage #{page + 1}/#{pages} — #{total} #{pool}s"
      ])

    component =
      case pool do
        :quest -> QuestPoolPage
        :prompt -> PromptPoolPage
      end

    buttons = [
      component.new(
        label: "Previous",
        style: 2,
        disabled: page == 0,
        arg: argument(guild_id, user_id, max(page - 1, 0))
      ),
      component.new(
        label: "Next",
        style: 2,
        disabled: page == pages - 1,
        arg: argument(guild_id, user_id, min(page + 1, pages - 1))
      )
    ]

    %{
      content: content,
      components: [%ActionRow{components: buttons}],
      allowed_mentions: %{parse: []}
    }
  end

  # Fixed-width IDs keep even the largest snowflakes/pages under Discord's
  # 100-character custom_id limit after the framework adds its HMAC.
  defp argument(guild_id, user_id, page) do
    Base.url_encode64(<<guild_id::unsigned-64, user_id::unsigned-64, page::unsigned-64>>,
      padding: false
    )
  end

  def truncate(content, limit) do
    if utf16_length(content) <= limit do
      content
    else
      take_utf16(content, limit - 3, []) <> "..."
    end
  end

  defp utf16_length(content), do: utf16_length(content, 0)
  defp utf16_length(<<>>, length), do: length

  defp utf16_length(<<codepoint::utf8, rest::binary>>, length) do
    utf16_length(rest, length + if(codepoint > 0xFFFF, do: 2, else: 1))
  end

  defp take_utf16(<<>>, _remaining, acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()

  defp take_utf16(<<codepoint::utf8, rest::binary>>, remaining, acc) do
    size = if codepoint > 0xFFFF, do: 2, else: 1

    if size <= remaining do
      take_utf16(rest, remaining - size, [<<codepoint::utf8>> | acc])
    else
      acc |> Enum.reverse() |> IO.iodata_to_binary()
    end
  end
end
