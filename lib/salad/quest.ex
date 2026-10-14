defmodule Salad.Quest do
  @moduledoc false
  import Ecto.Query

  alias Ecto.Adapters.SQL
  alias Salad.Quest.Template
  alias Salad.Repo
  alias Salad.Repo.{Guild, QuestChoice, QuestDraw}

  def set_channel(guild_id, channel) do
    with {:ok, channel_id} <- channel_id(channel),
         %Guild{} = guild <- Repo.get(Guild, guild_id) do
      Guild.update(guild, %{quest_channel: channel_id})
    else
      nil -> {:error, :guild_not_found}
      {:error, _reason} = error -> error
    end
  end

  # Deliver inside the transaction so a failed Discord response does not consume
  # a draw or reroll. Serialize even the first draw, when no row exists yet.
  def draw(guild_id, user_id, channel_id, deliver) when is_function(deliver, 1) do
    Repo.transaction(fn ->
      SQL.query!(
        Repo,
        "SELECT pg_advisory_xact_lock(hashtextextended($1, 0))",
        ["quest:#{guild_id}:#{user_id}"]
      )

      now = DateTime.utc_now()
      previous = Repo.get_by(QuestDraw, guild_id: guild_id, user_id: user_id)

      with :ok <- check_channel(guild_id, channel_id),
           {:ok, action} <- QuestDraw.check(previous, now),
           %QuestChoice{} = choice <- pick(guild_id, previous, action),
           {:ok, message} <- Template.render(choice.content, guild_id, user_id),
           {:ok, _draw} <- save(previous, choice, user_id, action, now) do
        case deliver.(message) do
          {:ok} -> choice
          {:ok, _response} -> choice
          {:error, reason} -> Repo.rollback({:delivery_failed, reason})
        end
      else
        nil -> Repo.rollback(:empty_pool)
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp channel_id(nil), do: {:ok, nil}
  defp channel_id(%{id: id, type: type}) when type in [0, 5], do: {:ok, id}
  defp channel_id(_channel), do: {:error, :invalid_channel}

  defp check_channel(guild_id, channel_id) do
    case Repo.get(Guild, guild_id) do
      %Guild{quest_channel: nil} -> :ok
      %Guild{quest_channel: ^channel_id} -> :ok
      %Guild{quest_channel: required} -> {:error, {:wrong_channel, required}}
      nil -> {:error, :guild_not_found}
    end
  end

  defp pick(guild_id, previous, action) do
    pool = from(q in QuestChoice, where: q.guild_id == ^guild_id)
    random = from(q in pool, order_by: fragment("RANDOM()"), limit: 1)

    if action == :reroll and not is_nil(previous.choice_id) do
      Repo.one(from(q in random, where: q.id != ^previous.choice_id)) || Repo.one(random)
    else
      Repo.one(random)
    end
  end

  defp save(previous, choice, user_id, action, now) do
    params = %{guild_id: choice.guild_id, user_id: user_id, choice_id: choice.id}

    params =
      if action == :reroll,
        do: Map.put(params, :reroll_count, previous.reroll_count + 1),
        else: Map.merge(params, %{drawn_at: now, reroll_count: 0})

    (previous || %QuestDraw{})
    |> QuestDraw.changeset(params)
    |> Repo.insert_or_update()
  end
end
