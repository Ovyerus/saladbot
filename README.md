# Salad

An Elixir Discord bot with role-selection menus, cheese touch, QOTD, and reusable quests.

## Quests

Run `/setup` for the server first. Quests are separate from QOTD: nothing is scheduled, and drawing a quest never removes it from the pool.

### Moderator administration

Members with **Manage Server** permission (including administrators) can use:

- `/quest-pool add quest:<text>` — add a quest and receive its ID.
- `/quest-pool list` — privately browse quest previews and IDs, eight per page, with Previous/Next buttons.
- `/quest-pool remove quest:<id>` — remove a quest; autocomplete searches by text or ID.
- `/quest-channel channel:#quests` — restrict `/quest` to a server text or announcement channel.
- `/quest-channel` — clear the restriction and allow `/quest` in any channel.

Quests belong to the server where they were added. They remain available until explicitly removed.

The list shows a page counter and disables navigation at the first/last page. Only the member who opened it can navigate, and they must still have Manage Server permission. Each click reads the current pool; if quests were removed, a stale page is clamped to the new last page. An empty pool removes the buttons. Long quest text is previewed to keep every page within Discord's message limit.

Servers start with no channel restriction. When configured, it applies to everyone, including admins, for both initial draws and rerolls. Requests elsewhere receive a link to the required channel without consuming a cooldown or reroll. The restriction matches that exact channel; threads within it are separate channels. Settings are per server, take effect immediately, and survive restarts. Setting, changing, or clearing the restriction does not reset existing cooldowns or reroll usage. The administration commands remain usable outside the restricted channel.

### Getting a quest

Run `/quest` with no parameters:

- If you have no active quest, or your two-hour cooldown has ended, you receive a new random quest publicly in the channel.
- Run `/quest` again up to twice within ten minutes of the original draw to automatically use your two rerolls. If more than one quest is available, each reroll chooses a different quest from your current one; a single-entry pool returns that same quest.
- Once both rerolls are used, or the original ten-minute window has closed, further requests show when your cooldown ends.

Each user has a **two-hour cooldown per server**, starting at the original draw. Neither reroll restarts or shortens it, and both share the same ten-minute window from that first draw. A fresh draw after the cooldown resets the reroll count and window. Both cooldowns and used rerolls survive bot restarts. Failed rendering or delivery does not consume a draw or reroll.

Quest selection is random, not a sequential walk through the list. Rerolls exclude only the current quest when alternatives exist, so a later reroll can return an earlier quest. The pool never depletes.

Responses use this template, with `user` rendered as a mention:

```text
Trick or treat, {user}! Your quest is: {choice}
```

### Random role-member mentions

Include `{user_from:ROLE_ID}` anywhere in quest text, replacing `ROLE_ID` with the numeric Discord role ID. For example:

```text
Share a spooky story with {user_from:123456789012345678}!
```

Each distinct role placeholder selects a random cached member of this server who has that role. Repeated placeholders for the same role mention the same selected member. Different roles are selected independently; the requester or a bot can be selected if they have the role. If no matching member is available, the user receives an error without spending their cooldown or reroll.

Only the requester and selected members are allowed to receive mention notifications; incidental `@everyone`, `@here`, role mentions, and other user mentions in the text do not ping. Invalid placeholders and text that would exceed Discord's message limit after expansion are rejected when added.

The bot already enables the guild-member intent and member fetching. The **Server Members Intent** must also be enabled for the bot in the Discord Developer Portal so the member cache can populate.

### Deployment

Apply migrations before running the updated bot:

```sh
mix ecto.migrate
```

For an OTP release:

```sh
./bin/salad eval "Salad.Release.migrate()"
```

The new command modules are discovered by the existing command registration system.

### Tests

```sh
mix test --no-start
```

`--no-start` runs the tests without starting the Discord connection or the application's database supervision tree. Quest tests cover cooldown/reroll boundaries, role-placeholder rendering using Nostrum's member cache, pagination boundaries and Discord size limits, and button authorization.
