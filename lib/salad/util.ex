defmodule Salad.Util do
  @moduledoc """
  Miscellaneous utilities to be used across Salad.
  """
  @emote_re ~r/^<(a?):([^>:]+):([0-9]+)>$/

  def unicode_emoji?(str) when is_binary(str), do: Emojix.find_by_unicode(str) != nil
  def custom_emote?(str) when is_binary(str), do: Regex.match?(@emote_re, str)

  @spec emoji_or_custom_emote?(binary) :: boolean
  def emoji_or_custom_emote?(str) when is_binary(str),
    do: custom_emote?(str) or unicode_emoji?(str)

  def accessible_emoji?(emoji, guild_id) when is_binary(emoji) and is_integer(guild_id) do
    if unicode_emoji?(emoji) do
      true
    else
      with [_, _, _, emoji_id] <- Regex.run(@emote_re, emoji),
           emoji_id <- String.to_integer(emoji_id),
           # Maybe make an emoji cache at some point and get directly from
           {:ok, _} <- Nostrum.Api.get_guild_emoji(guild_id, emoji_id) do
        true
      else
        _ -> false
      end
    end
  end

  @spec parse_emoji(String.t()) :: {String.t() | nil, String.t(), boolean()}
  def parse_emoji(emoji) when is_binary(emoji) do
    if unicode_emoji?(emoji) do
      {nil, emoji, false}
    else
      case Regex.run(@emote_re, emoji) do
        [_, animated, emoji_name, emoji_id] -> {emoji_id, emoji_name, animated == "a"}
        _ -> {nil, "❓", false}
      end
    end
  end

  @spec hmac(String.t()) :: String.t()
  def hmac(data) when is_binary(data) do
    key = Application.fetch_env!(:salad, :hmac_key)

    :crypto.mac(:hmac, :sha256, key, data)
    |> Base.encode64()
  end
end
