defmodule Salad.CheeseTouch do
  alias Salad.Repo
  require Logger

  def run(guild_id, reason, prechosen_victim \\ nil) do
    with %Repo.Guild{cheese_touch_channel: channel_id, cheese_touch_role: role_id}
         when channel_id != nil and role_id != nil <-
           Repo.Guild.get(guild_id),
         :ok <- remove_existing_cheeses(guild_id, role_id),
         {:ok, member} <- find_victim_and_execute(guild_id, role_id, prechosen_victim),
         {:ok, _history} <- Repo.CheeseTouchHistory.create(guild_id, member.user_id, reason),
         {:ok, _} <- schedule(guild_id) do
      Logger.info("Ran cheese touch for guild #{guild_id}, selected user #{member.user_id}")

      # Return the channel ID & victim in case anything calling this needs to
      # send a message to the cheese touch channel.
      {:ok, channel_id, member}
    else
      %Repo.Guild{} ->
        {:cancel, :cheese_touch_not_enabled}

      {:error, :not_found} ->
        Logger.warning("Failed to find guild #{guild_id} for scheduled cheese touch")
        {:cancel, :guild_not_found}

      e ->
        Logger.error("Failed to run scheduled cheese touch for #{guild_id}.")
        e
    end
  end

  def schedule(guild_id, schedule_in \\ {24, :hours}, cancel_existing \\ true) do
    import Ecto.Query

    if cancel_existing do
      Oban.Job
      |> where(queue: "cheese_touch")
      |> where(state: "scheduled")
      |> where(fragment("args->'guild_id' = ?", ^guild_id))
      |> Oban.cancel_all_jobs()
    end

    %{guild_id: guild_id}
    |> Salad.Scheduled.CheeseTouch.new(schedule_in: schedule_in)
    |> Oban.insert()
  end

  defp remove_existing_cheeses(guild_id, role_id) do
    with {:ok, _guild} <- Nostrum.Cache.GuildCache.get(guild_id) do
      Nostrum.Cache.MemberCache.fold([], guild_id, fn m, a ->
        if role_id in m.roles,
          do: [m | a],
          else: a
      end)
      |> Enum.each(fn m ->
        Nostrum.Api.remove_guild_member_role(
          guild_id,
          m.user_id,
          role_id,
          "Cheese touch rotation"
        )
      end)

      :ok
    end
  end

  defp find_victim_and_execute(guild_id, role_id, prechosen_victim) do
    guild = Nostrum.Cache.GuildCache.get!(guild_id)
    last_few = Repo.CheeseTouchHistory.get_last_n_for_guild(guild_id)
    filter_min = length(last_few)

    victim =
      case prechosen_victim do
        nil ->
          []
          |> Nostrum.Cache.MemberCache.fold_with_users(guild_id, fn {m, u}, a ->
            # Only select users that haven't had cheese touch, if the guild has enough users to care.
            # Also skip bots cause they stinky
            if !u.bot and (m.user_id not in last_few or guild.member_count <= filter_min),
              do: [m | a],
              else: a
          end)
          |> Enum.random()

        v ->
          v
      end

    with {:ok} <-
           Nostrum.Api.add_guild_member_role(
             guild_id,
             victim.user_id,
             role_id,
             "Cheese touch rotation"
           ) do
      {:ok, victim}
    end
  end
end
