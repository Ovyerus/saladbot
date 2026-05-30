defmodule Salad.Qotd do
  require Logger
  alias Salad.Repo

  @doc """
  Posts the next unposted question for a guild to its configured QOTD channel.
  Marks the question as posted and reschedules the next job.

  If no questions remain, disables QOTD for the guild and does not reschedule.
  """
  @spec run(pos_integer()) ::
          {:ok, pos_integer(), Repo.QotdQuestion.t()}
          | {:cancel, :no_questions_remaining | :qotd_not_enabled | :guild_not_found}
  def run(guild_id) do
    case Repo.Guild.get(guild_id) do
      nil ->
        Logger.warning("QOTD run for unknown guild #{guild_id}")
        {:cancel, :guild_not_found}

      %Repo.Guild{qotd_channel: nil} ->
        {:cancel, :qotd_not_enabled}

      %Repo.Guild{qotd_channel: channel_id} = guild ->
        run_for_guild(guild_id, channel_id, guild)
    end
  end

  defp run_for_guild(guild_id, channel_id, guild) do
    case Repo.QotdQuestion.get_next_unposted(guild_id) do
      nil ->
        Logger.warning("No QOTD questions remaining for guild #{guild_id}, disabling.")
        Repo.Guild.update(guild, %{qotd_channel: nil, qotd_time: nil})
        {:cancel, :no_questions_remaining}

      %Repo.QotdQuestion{} = question ->
        with {:ok, _} <- Nostrum.Api.create_message(channel_id, "**today's QOTD is:** #{question.content}"),
             {:ok, _} <- Repo.QotdQuestion.mark_posted(question),
             {:ok, _} <- schedule(guild_id) do
          Logger.info("Posted QOTD for guild #{guild_id}, question id=#{question.id}")
          {:ok, channel_id, question}
        else
          err ->
            Logger.error("Failed to run QOTD for guild #{guild_id}: #{inspect(err)}")
            err
        end
    end
  end

  @doc """
  Cancels any existing scheduled QOTD job for the guild and schedules the next one
  based on the guild's configured `qotd_time` (UTC).
  """
  @spec schedule(pos_integer(), Repo.Guild.t() | nil) ::
          {:ok, Oban.Job.t()} | {:error, Ecto.Changeset.t()}
  def schedule(guild_id, guild \\ nil) do
    import Ecto.Query

    # Cancel any existing scheduled job for this guild.
    Oban.Job
    |> where(queue: "qotd")
    |> where(state: "scheduled")
    |> where(fragment("args->>'guild_id' = ?", ^to_string(guild_id)))
    |> Oban.cancel_all_jobs()

    guild = guild || Repo.Guild.get(guild_id)
    run_at = next_run_at(guild.qotd_time)

    %{guild_id: guild_id}
    |> Salad.Scheduled.Qotd.new(scheduled_at: run_at)
    |> Oban.insert()
  end

  @doc """
  Computes the next UTC `DateTime` for a given `Time`.
  If the time is still in the future today (UTC), returns today at that time.
  Otherwise returns tomorrow at that time.
  """
  @spec next_run_at(Time.t()) :: DateTime.t()
  def next_run_at(%Time{} = qotd_time) do
    now = DateTime.utc_now()
    today = DateTime.to_date(now)
    today_run = DateTime.new!(today, qotd_time, "Etc/UTC")

    if DateTime.compare(today_run, now) == :gt do
      today_run
    else
      DateTime.add(today_run, 1, :day)
    end
  end
end
