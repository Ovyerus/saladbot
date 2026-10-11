defmodule Salad.Quest.Template do
  @moduledoc """
  Validates quest text and expands guild-scoped random role-member placeholders.
  """

  alias Nostrum.Cache.MemberCache

  @max_snowflake 18_446_744_073_709_551_615
  @max_mention "<@#{@max_snowflake}>"
  @max_wrapper "Trick or treat, #{@max_mention}! Your quest is: "
  @message_limit 2000
  @placeholder_pattern ~r/(\{\s*user_from[^}]*\}?)/u
  @placeholder_start ~r/\A\{\s*user_from/u
  @role_pattern ~r/\A\{user_from:([0-9]+)\}\z/
  @length_error "Quest text must fit within Discord's 2000 UTF-16 character limit, including the greeting and expanded user mentions."

  @spec validate(String.t()) :: :ok | {:error, String.t()}
  def validate(content) do
    with {:ok, parts} <- parse(content),
         :ok <- validate_length(parts) do
      :ok
    else
      {:error, :message_too_long} -> {:error, @length_error}
      {:error, reason} -> {:error, reason}
    end
  end

  @spec render(String.t(), pos_integer(), pos_integer()) ::
          {:ok, %{content: String.t(), allowed_mentions: map()}} | {:error, term()}
  def render(content, guild_id, user_id) do
    with {:ok, parts} <- parse(content),
         :ok <- validate_length(parts),
         {:ok, selections} <- select_members(parts, guild_id) do
      quest =
        Enum.map_join(parts, fn
          {:text, text} -> text
          {:role, role_id} -> "<@#{Map.fetch!(selections, role_id)}>"
        end)

      message = "Trick or treat, <@#{user_id}>! Your quest is: #{quest}"

      if utf16_length(message) <= @message_limit do
        users =
          [user_id | Map.values(selections)]
          |> Enum.map(&Integer.to_string/1)
          |> Enum.uniq()

        {:ok, %{content: message, allowed_mentions: %{parse: [], users: users}}}
      else
        {:error, :message_too_long}
      end
    end
  end

  defp parse(content) when is_binary(content) do
    if String.trim(content) == "" do
      {:error, "Quest text cannot be blank."}
    else
      @placeholder_pattern
      |> Regex.split(content, include_captures: true, trim: true)
      |> Enum.reduce_while({:ok, []}, fn part, {:ok, parts} ->
        case parse_part(part) do
          {:ok, parsed} -> {:cont, {:ok, [parsed | parts]}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, parts} -> {:ok, Enum.reverse(parts)}
        error -> error
      end
    end
  end

  defp parse(_content), do: {:error, "Quest text must be a string."}

  defp parse_part(part) do
    if Regex.match?(@placeholder_start, part) do
      case Regex.run(@role_pattern, part) do
        [_, digits] ->
          case Integer.parse(digits) do
            {role_id, ""} when role_id > 0 and role_id <= @max_snowflake ->
              {:ok, {:role, role_id}}

            _ ->
              {:error,
               "Role IDs in {user_from:roleid} must be positive unsigned 64-bit integers."}
          end

        _ ->
          {:error,
           "Invalid user_from placeholder. Use {user_from:roleid} with a numeric role ID."}
      end
    else
      {:ok, {:text, part}}
    end
  end

  defp validate_length(parts) do
    length =
      Enum.reduce(parts, byte_size(@max_wrapper), fn
        {:text, text}, length -> length + utf16_length(text)
        {:role, _role_id}, length -> length + byte_size(@max_mention)
      end)

    if length <= @message_limit, do: :ok, else: {:error, :message_too_long}
  end

  defp select_members(parts, guild_id) do
    Enum.reduce_while(parts, {:ok, %{}}, fn
      {:text, _text}, selections ->
        {:cont, selections}

      {:role, role_id}, {:ok, selections} ->
        if Map.has_key?(selections, role_id) do
          {:cont, {:ok, selections}}
        else
          members =
            MemberCache.fold([], guild_id, fn member, members ->
              if role_id in member.roles, do: [member.user_id | members], else: members
            end)

          case members do
            [] -> {:halt, {:error, {:no_role_members, role_id}}}
            members -> {:cont, {:ok, Map.put(selections, role_id, Enum.random(members))}}
          end
        end
    end)
  end

  defp utf16_length(text), do: utf16_length(text, 0)
  defp utf16_length(<<>>, length), do: length

  defp utf16_length(<<codepoint::utf8, rest::binary>>, length) do
    units = if codepoint > 0xFFFF, do: 2, else: 1
    utf16_length(rest, length + units)
  end
end
