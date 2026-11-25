defmodule Salad.Commands.QuestPool do
  @moduledoc false
  use Salad.CommandSystem.Command

  alias Salad.Quest.PoolList
  alias Salad.Repo.QuestChoice

  @impl true
  def name, do: "quest-pool"

  @impl true
  def description, do: "Manage this server's reusable quest pool"

  @impl true
  def predicates,
    do: [guild_only(), permissions([:manage_guild]), guild_setup()]

  @impl true
  def options, do: options(:quest)

  def options(pool),
    do: [
      %Option{
        name: "add",
        type: Option.Type.subcommand(),
        description: "Add a reusable #{pool} to the pool.",
        options: [
          %Option{
            name: to_string(pool),
            type: Option.Type.string(),
            description:
              "#{String.capitalize(to_string(pool))} text; use {user_from:ROLE_ID} to pick a member with that role.",
            required: true
          }
        ]
      },
      %Option{
        name: "remove",
        type: Option.Type.subcommand(),
        description: "Remove a #{pool} from the pool.",
        options: [
          %Option{
            name: to_string(pool),
            type: Option.Type.string(),
            description: "The #{pool} ID to remove; search by text or ID.",
            required: true,
            autocomplete: true
          }
        ]
      },
      %Option{
        name: "list",
        type: Option.Type.subcommand(),
        description: "List #{pool} text and IDs in this server's pool."
      }
    ]

  @impl true
  def autocomplete(ev), do: autocomplete(ev, :quest)

  def autocomplete(%{data: %{options: options}, guild_id: guild_id} = ev, pool)
      when is_list(options) do
    # The dispatcher does not run predicates for autocomplete interactions.
    if Enum.all?(predicates(), fn predicate -> predicate.(ev) == true end) do
      option_name = to_string(pool)

      case focused_option(options) do
        %{name: ^option_name, value: text} when is_binary(text) ->
          choices =
            if text == "" do
              guild_id |> QuestChoice.get_for_guild(pool) |> Enum.take(25)
            else
              QuestChoice.search_for_guild(guild_id, text, pool)
            end

          Enum.map(choices, fn choice ->
            label = "#{choice.id}: #{single_line(choice.content)}"
            %{name: PoolList.truncate(label, 100), value: to_string(choice.id)}
          end)

        _ ->
          []
      end
    else
      []
    end
  end

  def autocomplete(_, _pool), do: []

  @impl true
  def run(ctx), do: run(ctx, :quest)

  def run(ctx, pool) do
    case ctx.options do
      %{"add" => _} -> run_add(ctx, pool)
      %{"remove" => _} -> run_remove(ctx, pool)
      %{"list" => _} -> run_list(ctx, pool)
    end
  end

  defp run_add(ctx, pool) do
    %{value: content} = Map.fetch!(ctx.options["add"].value, to_string(pool))

    case QuestChoice.create(ctx.guild_id, content, pool) do
      {:ok, choice} ->
        respond(
          ctx,
          "#{String.capitalize(to_string(pool))} added with ID `#{choice.id}`. It stays in the pool until removed."
        )

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

        respond(ctx, "Could not add the #{pool}: #{errors}")
    end
  end

  defp run_remove(ctx, pool) do
    %{value: id_text} = Map.fetch!(ctx.options["remove"].value, to_string(pool))
    title = String.capitalize(to_string(pool))

    with {id, ""} when id > 0 and id <= 9_223_372_036_854_775_807 <- Integer.parse(id_text),
         %QuestChoice{} = choice <- QuestChoice.get(ctx.guild_id, id, pool),
         {:ok, _} <- QuestChoice.delete(choice) do
      respond(ctx, "#{title} `#{id}` removed from this server's pool.")
    else
      _ ->
        respond(
          ctx,
          "#{title} not found in this server's pool. Select a #{pool} using autocomplete or `/#{pool}-pool list`."
        )
    end
  end

  defp run_list(ctx, pool) do
    data = PoolList.page(ctx.guild_id, ctx.user.id, 0, pool) |> Map.put(:flags, 64)
    reply(ctx, %{type: 4, data: data})
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
      data: %{
        content: PoolList.truncate(content, 2000),
        flags: 64,
        allowed_mentions: %{parse: []}
      }
    })
  end
end
