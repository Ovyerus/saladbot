defmodule Salad.Commands.QuestPool do
  @moduledoc false
  use Salad.CommandSystem.Command

  alias Salad.Repo.QuestChoice

  @impl true
  def name, do: "quest-pool"

  @impl true
  def description, do: "Manage this server's reusable quest pool"

  @impl true
  def predicates,
    do: [guild_only(), permissions([:manage_guild]), guild_setup()]

  @impl true
  def options,
    do: [
      %Option{
        name: "add",
        type: Option.Type.subcommand(),
        description: "Add a reusable quest to the pool.",
        options: [
          %Option{
            name: "quest",
            type: Option.Type.string(),
            description: "Quest text; use {user_from:ROLE_ID} to pick a member with that role.",
            required: true
          }
        ]
      },
      %Option{
        name: "remove",
        type: Option.Type.subcommand(),
        description: "Remove a quest from the pool.",
        options: [
          %Option{
            name: "quest",
            type: Option.Type.string(),
            description: "The quest ID to remove; search by text or ID.",
            required: true,
            autocomplete: true
          }
        ]
      },
      %Option{
        name: "list",
        type: Option.Type.subcommand(),
        description: "List quest text and IDs in this server's pool."
      }
    ]

  @impl true
  def autocomplete(%{data: %{options: options}, guild_id: guild_id} = ev)
      when is_list(options) do
    # The dispatcher does not run predicates for autocomplete interactions.
    if Enum.all?(predicates(), fn predicate -> predicate.(ev) == true end) do
      case focused_option(options) do
        %{name: "quest", value: text} when is_binary(text) ->
          choices =
            if text == "" do
              guild_id |> QuestChoice.get_for_guild() |> Enum.take(25)
            else
              QuestChoice.search_for_guild(guild_id, text)
            end

          Enum.map(choices, fn choice ->
            label = "#{choice.id}: #{single_line(choice.content)}"
            %{name: truncate(label, 100), value: to_string(choice.id)}
          end)

        _ ->
          []
      end
    else
      []
    end
  end

  def autocomplete(_), do: []

  @impl true
  def run(ctx) do
    case ctx.options do
      %{"add" => _} -> run_add(ctx)
      %{"remove" => _} -> run_remove(ctx)
      %{"list" => _} -> run_list(ctx)
    end
  end

  defp run_add(ctx) do
    %{"quest" => %{value: content}} = ctx.options["add"].value

    case QuestChoice.create(ctx.guild_id, content) do
      {:ok, choice} ->
        respond(ctx, "Quest added with ID `#{choice.id}`. It stays in the pool until removed.")

      {:error, %Ecto.Changeset{} = changeset} ->
        errors =
          changeset
          |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
            Enum.reduce(opts, message, fn {key, value}, message ->
              String.replace(message, "%{#{key}}", to_string(value))
            end)
          end)
          |> Enum.flat_map(fn {field, messages} ->
            Enum.map(messages, &"#{field}: #{&1}")
          end)
          |> Enum.join("; ")

        respond(ctx, "Could not add the quest: #{errors}")
    end
  end

  defp run_remove(ctx) do
    %{"quest" => %{value: id_text}} = ctx.options["remove"].value

    with {id, ""} when id > 0 and id <= 9_223_372_036_854_775_807 <- Integer.parse(id_text),
         %QuestChoice{} = choice <- QuestChoice.get(ctx.guild_id, id),
         {:ok, _} <- QuestChoice.delete(choice) do
      respond(ctx, "Quest `#{id}` removed from this server's pool.")
    else
      _ ->
        respond(
          ctx,
          "Quest not found in this server's pool. Select a quest using autocomplete or `/quest-pool list`."
        )
    end
  end

  defp run_list(ctx) do
    case QuestChoice.get_for_guild(ctx.guild_id) do
      [] ->
        respond(ctx, "This server's quest pool is empty. Add a quest with `/quest-pool add`.")

      choices ->
        header = "Quests in this server's pool (ID: quest):\n"
        total = length(choices)

        # Leave room for the truncation note, even if every quest is displayed.
        {lines, shown, _remaining} =
          Enum.reduce_while(choices, {[], 0, 1850 - utf16_length(header)}, fn choice,
                                                                              {lines, shown,
                                                                               remaining} ->
            line = "`#{choice.id}`: #{truncate(single_line(choice.content), 180)}\n"
            length = utf16_length(line)

            if length <= remaining do
              {:cont, {[line | lines], shown + 1, remaining - length}}
            else
              {:halt, {lines, shown, remaining}}
            end
          end)

        note =
          if shown < total do
            "\nShowing #{shown} of #{total} quests; list truncated. Use `/quest-pool remove` autocomplete to find more."
          else
            ""
          end

        respond(ctx, IO.iodata_to_binary([header, Enum.reverse(lines), note]))
    end
  end

  defp focused_option(options) do
    Enum.find_value(options, fn option ->
      if Map.get(option, :focused) == true do
        option
      else
        focused_option(Map.get(option, :options) || [])
      end
    end)
  end

  defp single_line(content), do: String.replace(content, ~r/\s+/u, " ")

  defp respond(ctx, content) do
    reply(ctx, %{
      type: 4,
      data: %{content: truncate(content, 2000), flags: 64, allowed_mentions: %{parse: []}}
    })
  end

  defp truncate(content, limit) do
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
