# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Saladbot (`salad`) is an Elixir Discord bot built with [Nostrum](https://github.com/Kraigie/nostrum). It handles role-selection menus ("role groups") and a "cheese touch" game feature for Discord guilds, backed by PostgreSQL via Ecto and Oban for background jobs.

## Commands

```sh
# Dependencies
mix deps.get

# Database
mix ecto.create
mix ecto.migrate

# Run the bot
mix run --no-halt

# Tests
mix test

# Linting
mix credo

# Production migrations (release binary)
./bin/salad eval "Salad.Release.migrate()"
```

### Nix / Build

```sh
nix develop         # enter dev shell (Elixir 1.16, Erlang 26)
nix build           # build OTP release
nix build .#docker  # build Docker image (Linux only)
```

### Required Environment Variables

| Variable          | Description                                 |
| ----------------- | ------------------------------------------- |
| `SALAD_TOKEN`     | Discord bot token                           |
| `SALAD_OWNER`     | Discord user ID of bot owner (integer)      |
| `SALAD_HMAC_KEY`  | Key for HMAC-signing component custom IDs   |
| `SALAD_DEV_GUILD` | Guild ID for dev slash command registration |

See `config/runtime.exs` for the full list including optional DB and Grafana vars.

## Architecture

### Supervision Tree

```
Salad (Supervisor)
├── Salad.PromEx          — Prometheus metrics (port 4100)
├── Salad.Repo            — Ecto/Postgres
├── Oban                  — Background job queue
└── Salad.Consumer        — Nostrum gateway event consumer
```

Before the supervisor starts, `Salad.CommandSystem.setup/0` populates two ETS tables with all command and component modules discovered via `:application.get_key/2`.

### Command System (`lib/salad/command_system/`)

The central dispatcher. Incoming Discord interactions are routed by type:

- **Slash commands** → ETS lookup by name, runs predicates, calls `mod.run(ctx)`
- **Message components** → parses HMAC-signed `custom_id`, calls `mod.run(ev, arg)`
- **Autocomplete** → calls `mod.autocomplete(ev)`

**Adding a command**: create a module under `lib/salad/commands/` that `use Salad.CommandSystem.Command`. Required callbacks: `description/0` and `run/1`. Everything else (`name/0`, `type/0`, `options/0`, `predicates/0`) has defaults.

**Adding a component**: create a module under `lib/salad/components/` that `use Salad.CommandSystem.Component`. Use `generate_id/2` to produce HMAC-signed `custom_id` strings — never construct them manually.

**Predicates** (`lib/salad/command_system/predicates.ex`) are compile-time macros for access control: `guild_only/1`, `permissions/2`, `owner_only/1`, `guild_setup/0`. Used in a command's `predicates/0` callback.

**Context** (`Salad.CommandSystem.Structs.Context`) is the enriched interaction struct passed to `run/1`, with resolved option values (users, roles, channels, etc.).

### Repo Layer (`lib/salad/repo/`)

Each file colocates an Ecto schema with its query functions. Key schemas:

- `Guild` — per-guild settings; references cheese touch channel/role
- `RoleGroup` — named groups with `:buttons` or `:select` display type
- `Role` — individual Discord role entries within a group
- `RoleGroupMessage` — tracks which Discord messages have been posted per group per channel
- `CheeseTouchHistory` — history of cheese touch assignments

### Cheese Touch (`lib/salad/cheese_touch.ex` + `lib/salad/scheduled/`)

Business logic picks a random guild member (avoiding recent recipients), assigns them a Discord role, records history, and schedules the next rotation. `Salad.Scheduled.CheeseTouch` is the Oban worker in the `cheese_touch` queue.

### Dev vs Prod

In `dev` (`MIX_ENV=dev`), `sync_dev_guild: true` registers slash commands only to the dev guild for near-instant propagation (global takes up to 1 hour).
