# lib/salad/commands/qotd.ex
defmodule Salad.Commands.Qotd do
  @moduledoc false
  import Bitwise
  require Logger
  use Salad.CommandSystem.Command

  alias Salad.Repo

  @impl true
  def description, do: "Question of the Day commands"

  @impl true
  def predicates,
    do: [
      guild_only(),
      permissions([:manage_guild]),
      guild_setup()
    ]

  @impl true
  def options,
    do: [
      %Option{
        name: "enable",
        type: Option.Type.subcommand(),
        description: "Enable QOTD for this server.",
        options: [
          %Option{
            name: "channel",
            type: Option.Type.channel(),
            description: "The channel to post questions in.",
            required: true
          },
          %Option{
            name: "time",
            type: Option.Type.string(),
            description: "When to post each day — paste a Discord timestamp (type @time 9pm tomorrow to get one).",
            required: true
          }
        ]
      },
      %Option{
        name: "disable",
        type: Option.Type.subcommand(),
        description: "Disable QOTD for this server."
      },
      %Option{
        name: "add",
        type: Option.Type.subcommand(),
        description: "Add a question to the pool.",
        options: [
          %Option{
            name: "question",
            type: Option.Type.string(),
            description: "The question to add.",
            required: true
          }
        ]
      },
      %Option{
        name: "remove",
        type: Option.Type.subcommand(),
        description: "Remove a question from the pool.",
        options: [
          %Option{
            name: "question",
            type: Option.Type.string(),
            description: "The question to remove.",
            required: true,
            autocomplete: true
          }
        ]
      },
      %Option{
        name: "list",
        type: Option.Type.subcommand(),
        description: "List all questions in the pool."
      }
    ]

  @impl true
  def autocomplete(%{data: %{options: options}, guild_id: guild_id}) do
    opt = Enum.find(options, fn opt -> opt.focused end)

    case opt && opt.name do
      "question" ->
        results =
          if opt.value && opt.value != "" do
            Repo.QotdQuestion.search_for_guild(guild_id, opt.value)
          else
            Repo.QotdQuestion.get_for_guild(guild_id) |> Enum.take(25)
          end

        Enum.map(results, fn q ->
          label = if String.length(q.content) > 97, do: String.slice(q.content, 0, 97) <> "...", else: q.content
          %{name: label, value: to_string(q.id)}
        end)

      _ ->
        []
    end
  end

  @impl true
  def run(ctx) do
    case ctx.options do
      %{"enable" => _} -> run_enable(ctx)
      %{"disable" => _} -> run_disable(ctx)
      %{"add" => _} -> run_add(ctx)
      %{"remove" => _} -> run_remove(ctx)
      %{"list" => _} -> run_list(ctx)
    end
  end

  # Discord timestamp format: <t:UNIX> or <t:UNIX:format>
  @timestamp_regex ~r/<t:(\d+)(?::[tTdDfFR])?>/

  defp parse_discord_time(str) do
    case Regex.run(@timestamp_regex, str) do
      [_, unix_str] ->
        unix = String.to_integer(unix_str)
        dt = DateTime.from_unix!(unix)
        {:ok, DateTime.to_time(dt)}

      nil ->
        case Integer.parse(str) do
          {unix, ""} ->
            dt = DateTime.from_unix!(unix)
            {:ok, DateTime.to_time(dt)}

          _ ->
            :error
        end
    end
  end

  defp run_enable(ctx) do
    %{
      "channel" => %{value: channel},
      "time" => %{value: time_str}
    } = ctx.options["enable"].value

    with true <- channel.type == Nostrum.Constants.ChannelType.guild_text() or :not_text_channel,
         {:ok, qotd_time} <- parse_discord_time(time_str),
         %Repo.Guild{} = guild <- Repo.Guild.get(ctx.guild_id),
         {:ok, _updated} <-
           Repo.Guild.update(guild, %{qotd_channel: channel.id, qotd_time: qotd_time}) do
      Salad.Qotd.schedule(ctx.guild_id, %{guild | qotd_time: qotd_time})

      next_unix = Salad.Qotd.next_run_at(qotd_time) |> DateTime.to_unix()

      reply(ctx, %{
        type: 4,
        data: %{
          content:
            "QOTD has been enabled in <##{channel.id}>. Questions will be posted daily at <t:#{next_unix}:t>."
        }
      })
    else
      :not_text_channel ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "The channel you selected is not a plain text channel.",
            flags: 1 <<< 6
          }
        })

      :error ->
        reply(ctx, %{
          type: 4,
          data: %{
            content:
              "Please provide a time using a Discord timestamp — type `@time 9pm tomorrow` in any channel to get one, then paste it here.",
            flags: 1 <<< 6
          }
        })

      nil ->
        Logger.error("/qotd enable reached nil guild for #{ctx.guild_id}")

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Something went wrong fetching this server. Try `/setup` first.",
            flags: 1 <<< 6
          }
        })

      err ->
        Logger.error("Failed to enable QOTD for guild #{ctx.guild_id}: #{inspect(err)}")

        reply(ctx, %{
          type: 4,
          data: %{content: "An error occurred.", flags: 1 <<< 6}
        })
    end
  end

  defp run_disable(ctx) do
    import Ecto.Query

    with %Repo.Guild{} = guild <- Repo.Guild.get(ctx.guild_id),
         {:ok, _updated} <-
           Repo.Guild.update(guild, %{qotd_channel: nil, qotd_time: nil}) do
      # Cancel any pending Oban job for this guild.
      Oban.Job
      |> where(queue: "qotd")
      |> where(state: "scheduled")
      |> where(fragment("args->>'guild_id' = ?", ^to_string(ctx.guild_id)))
      |> Oban.cancel_all_jobs()

      reply(ctx, %{
        type: 4,
        data: %{content: "QOTD has been disabled.", flags: 1 <<< 6}
      })
    else
      err ->
        Logger.error("Failed to disable QOTD for guild #{ctx.guild_id}: #{inspect(err)}")
        reply(ctx, %{type: 4, data: %{content: "An error occurred.", flags: 1 <<< 6}})
    end
  end

  defp run_add(ctx) do
    %{"question" => %{value: content}} = ctx.options["add"].value

    case Repo.QotdQuestion.create(ctx.guild_id, content) do
      {:ok, _question} ->
        remaining = Repo.QotdQuestion.count_unposted(ctx.guild_id)

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Question added. There are now #{remaining} unposted question(s) in the pool.",
            flags: 1 <<< 6
          }
        })

      {:error, err} ->
        Logger.error("Failed to add QOTD question for guild #{ctx.guild_id}: #{inspect(err)}")
        reply(ctx, %{type: 4, data: %{content: "Failed to add the question.", flags: 1 <<< 6}})
    end
  end

  defp run_remove(ctx) do
    %{"question" => %{value: id_str}} = ctx.options["remove"].value

    with {id, ""} <- Integer.parse(id_str),
         %Repo.QotdQuestion{} = question <- Repo.QotdQuestion.get(id),
         true <- question.guild_id == ctx.guild_id or :wrong_guild,
         {:ok, _} <- Repo.QotdQuestion.delete(question) do
      reply(ctx, %{
        type: 4,
        data: %{content: "Question removed.", flags: 1 <<< 6}
      })
    else
      # Integer.parse failed or returned a partial match — not a valid ID
      bad_id when bad_id == :error or (is_tuple(bad_id) and is_integer(elem(bad_id, 0))) ->
        reply(ctx, %{
          type: 4,
          data: %{content: "Invalid question ID. Please select a question from the list.", flags: 1 <<< 6}
        })

      nil ->
        reply(ctx, %{
          type: 4,
          data: %{content: "That question doesn't exist.", flags: 1 <<< 6}
        })

      :wrong_guild ->
        reply(ctx, %{
          type: 4,
          data: %{content: "That question doesn't belong to this server.", flags: 1 <<< 6}
        })

      {:error, err} ->
        Logger.error("Failed to remove QOTD question: #{inspect(err)}")
        reply(ctx, %{type: 4, data: %{content: "Failed to remove the question.", flags: 1 <<< 6}})
    end
  end

  defp run_list(ctx) do
    questions = Repo.QotdQuestion.get_for_guild(ctx.guild_id)

    if questions == [] do
      reply(ctx, %{
        type: 4,
        data: %{content: "No questions in the pool for this server.", flags: 1 <<< 6}
      })
    else
      {posted, unposted} = Enum.split_with(questions, fn q -> not is_nil(q.posted_at) end)

      lines =
        [
          if(unposted != [],
            do: ["**Unposted (#{length(unposted)}):**"] ++ Enum.map(unposted, &format_question/1),
            else: []
          ),
          if(posted != [],
            do: ["**Posted (#{length(posted)}):**"] ++ Enum.map(posted, &format_question/1),
            else: []
          )
        ]
        |> List.flatten()

      # Truncate to fit Discord's 2000 char limit, leaving room for a note.
      content =
        lines
        |> Enum.reduce_while("", fn line, acc ->
          candidate = if acc == "", do: line, else: acc <> "\n" <> line
          if String.length(candidate) <= 1900, do: {:cont, candidate}, else: {:halt, acc}
        end)

      suffix =
        if String.length(Enum.join(lines, "\n")) > 1900,
          do: "\n*(list truncated — #{length(questions)} total)*",
          else: ""

      reply(ctx, %{
        type: 4,
        data: %{content: content <> suffix, flags: 1 <<< 6}
      })
    end
  end

  defp format_question(%Repo.QotdQuestion{id: id, content: content}) do
    preview = if String.length(content) > 80, do: String.slice(content, 0, 80) <> "…", else: content
    "• `#{id}` #{preview}"
  end
end
