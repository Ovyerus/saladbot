defmodule Salad.CommandSystem.Predicates do
  use Bitwise
  alias Nostrum.Struct.Guild.Member

  defmacro guild_only(opts \\ []) do
    message = Keyword.get(opts, :message, false)

    quote do
      fn
        %{guild_id: nil} -> unquote(if is_binary(message), do: message, else: false)
        _ -> true
      end
    end
  end

  @spec permissions(maybe_improper_list, keyword) :: {:fn, [], [{:->, [], [...]}, ...]}
  defmacro permissions(perms, opts \\ []) when is_list(perms) do
    operation = Keyword.get(opts, :operation, :and)

    default_message_extra =
      case operation do
        :and -> "all of"
        :or -> "any of"
      end

    default_message =
      perms
      |> Enum.map(fn p -> "`#{p}`" end)
      |> Enum.join(", ")
      |> then(
        &"You need #{default_message_extra} the following permissions to use this command: #{&1}"
      )

    message = Keyword.get(opts, :message, default_message)

    enum_fun =
      case operation do
        :and -> :all?
        :or -> :any?
      end

    quote do
      fn %{member: member, guild_id: guild_id} ->
        guild = Nostrum.Cache.GuildCache.get!(guild_id)
        member_perms = Member.guild_permissions(member, guild)

        if apply(Enum, unquote(enum_fun), [unquote(perms), fn p -> p in member_perms end]) do
          true
        else
          unquote(
            case message do
              false -> false
              x when is_binary(x) -> x
            end
          )
        end
      end
    end
  end
end
