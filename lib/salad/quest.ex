defmodule Salad.Quest do
  @moduledoc false
  import Ecto.Query

  alias Ecto.Adapters.SQL
  alias Salad.Quest.Template
  alias Salad.Repo
  alias Salad.Repo.{QuestChoice, QuestDraw}

  # Deliver inside the transaction so a failed Discord response does not consume
  # a draw or reroll. Serialize even the first draw, when no row exists yet.
  def draw(guild_id, user_id, deliver) when is_function(deliver, 1) do
    Repo.transaction(fn ->
      SQL.query!(
        Repo,
        "SELECT pg_advisory_xact_lock(hashtextextended($1, 0))",
        ["quest:#{guild_id}:#{user_id}"]
      )

      now = DateTime.utc_now()
      previous = Repo.get_by(QuestDraw, guild_id: guild_id, user_id: user_id)

      with {:ok, action} <- QuestDraw.check(previous, now),
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
