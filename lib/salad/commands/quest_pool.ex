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
            %{name: PoolList.truncate(label, 100), value: to_string(choice.id)}
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
    data = PoolList.page(ctx.guild_id, ctx.user.id) |> Map.put(:flags, 64)
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
