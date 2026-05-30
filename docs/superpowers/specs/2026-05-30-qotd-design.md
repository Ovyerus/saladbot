# QOTD (Question of the Day) — Design Spec

**Date:** 2026-05-30
**Status:** Approved

## Overview

Add a "Question of the Day" feature to Saladbot. Once enabled per guild, the bot
posts one question from a per-guild pool to a configured channel at a configured
time each day. Questions are marked as posted and never reused. When the pool is
exhausted, the feature disables itself silently (notification support deferred).

Airtable / bulk-import integration is explicitly out of scope for this spec —
noted as a future addition.

---

## Data Model

### New table: `qotd_questions`

| Column | Type | Notes |
|---|---|---|
| `id` | bigserial | Primary key |
| `guild_id` | bigint | FK → `guilds`, not null |
| `content` | text | The question text, not null |
| `posted_at` | naive_datetime | null until posted; set when used |
| `inserted_at` | naive_datetime | Standard Ecto timestamp |
| `updated_at` | naive_datetime | Standard Ecto timestamp |

Questions are posted in insertion order (oldest unposted first, ordered by
`inserted_at`).

### Additions to `guilds` table

| Column | Type | Notes |
|---|---|---|
| `qotd_channel` | bigint | Discord channel ID; null = QOTD disabled |
| `qotd_time` | time | UTC time of day to post; only meaningful when channel is set |

A guild with `qotd_channel = nil` has QOTD disabled.

---

## Scheduling & Business Logic

### `Salad.Repo.QotdQuestion`

Schema + query module colocated in `lib/salad/repo/qotd_question.ex`. Key
functions:

- `create/2` — inserts a new question for a guild
- `delete/1` — deletes a question struct
- `get/1` — fetch by id
- `get_for_guild/1` — all questions for a guild, ordered by `inserted_at`
- `get_next_unposted/1` — oldest unposted question for a guild (`posted_at IS NULL`)
- `mark_posted/1` — sets `posted_at` to current UTC time
- `search_for_guild/2` — fuzzy search on `content` for autocomplete (all questions, posted or not)

### `Salad.Qotd`

Core business logic in `lib/salad/qotd.ex`, mirroring `Salad.CheeseTouch`.

**`run/1` (guild_id)**:
1. Fetch guild; verify `qotd_channel` is set (guard against race conditions).
2. Fetch next unposted question via `QotdQuestion.get_next_unposted/1`.
3. If no question found: set `qotd_channel = nil` on the guild (disables), log a
   warning, return `{:cancel, :no_questions_remaining}`. Do not reschedule.
4. Post the question as a plain text message to `qotd_channel`.
5. Call `QotdQuestion.mark_posted/1`.
6. Call `schedule/1` to queue the next job.
7. Return `{:ok, channel_id, question}`.

**`schedule/2` (guild_id, guild \\ nil)**:
- Cancels any existing scheduled `:qotd` queue job for this guild.
- Loads the guild if not provided.
- Computes next UTC datetime for `guild.qotd_time`: if the time is still in the
  future today (UTC), schedule for today; otherwise schedule for tomorrow.
- Inserts a new `Salad.Scheduled.Qotd` oban job with `schedule_at`.

### `Salad.Scheduled.Qotd`

Oban worker in `lib/salad/scheduled/qotd.ex`, queue `:qotd`.

```elixir
def perform(%Oban.Job{args: %{"guild_id" => guild_id}}) do
  case Salad.Qotd.run(guild_id) do
    {:ok, _channel_id, _question} -> :ok
    {:cancel, _reason} -> :ok
    err -> err
  end
end
```

---

## Commands

Single `/qotd` slash command in `lib/salad/commands/qotd.ex`.

**Predicates:** `guild_only()`, `permissions([:manage_guild])`, `guild_setup()`

### Subcommands

#### `/qotd enable`

Options:
- `channel` — channel type, required
- `time` — string type, required (Discord timestamp token)

Behaviour:
1. Validate `channel` is a text channel.
2. Parse `time` — accept `<t:UNIX>` or `<t:UNIX:format>` (any format variant),
   or a raw integer string. Extract the Unix timestamp, convert to UTC `Time`.
   On failure, reply with an ephemeral error:
   > "please provide a time using a discord timestamp — type `@time 9pm tomorrow`
   > in any channel to get one, then paste it here."
3. Update guild: set `qotd_channel` and `qotd_time`.
4. Call `Salad.Qotd.schedule/1`.
5. Reply confirming QOTD is enabled in the channel at the configured time.

If already enabled, silently update and reschedule (no error).

#### `/qotd disable`

1. Clear `qotd_channel` and `qotd_time` on the guild.
2. Cancel the scheduled oban job.
3. Reply confirming QOTD is disabled.

#### `/qotd add`

Options:
- `question` — string type, required

Behaviour: insert a new `QotdQuestion` for the guild. Reply confirming it was
added (optionally include how many unposted questions remain).

#### `/qotd remove`

Options:
- `question` — string type, required, **autocomplete enabled**

Autocomplete: searches all questions for the guild (posted or unposted) using
`QotdQuestion.search_for_guild/2`. Returns up to 25 results with the question
content as label and the question ID (as string) as value.

Behaviour: parse the selected value as an integer ID, fetch and delete the
question. Allow deletion of already-posted questions (cleanup use case). Reply
confirming deletion.

#### `/qotd list`

Lists all questions for the guild. Groups or marks posted vs. unposted.
If the list is long, truncate with a count (Discord has a 2000-char message
limit).

---

## Error Handling & Edge Cases

| Scenario | Handling |
|---|---|
| Invalid timestamp on `enable` | Ephemeral error with `@time` usage hint |
| Channel is not a text channel | Ephemeral error (same check as cheese touch) |
| All questions exhausted | `run/1` sets `qotd_channel = nil`, logs warning, stops scheduling |
| `remove` on a posted question | Allowed — no restriction |
| `enable` when already enabled | Update + reschedule silently |
| Guild not found in `run/1` | Log error, return `{:cancel, :guild_not_found}` |

---

## Files To Create / Modify

| Action | Path |
|---|---|
| Create | `lib/salad/qotd.ex` |
| Create | `lib/salad/repo/qotd_question.ex` |
| Create | `lib/salad/scheduled/qotd.ex` |
| Create | `lib/salad/commands/qotd.ex` |
| Create | `priv/repo/migrations/TIMESTAMP_qotd.exs` |
| Modify | `lib/salad/repo/guild.ex` — add `qotd_channel`, `qotd_time` fields |
| Modify | `config/config.exs` (or runtime) — add `:qotd` to Oban queues |

---

## Out of Scope

- Airtable / bulk import integration (future)
- Notifications when the question pool is exhausted
- Per-guild timezone support (UTC only for now)
- Posting format other than plain text
