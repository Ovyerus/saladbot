defmodule Salad.Commands.Prompt do
  @moduledoc false
  use Salad.CommandSystem.Command

  alias Salad.Commands.Quest
  alias Salad.Repo.Guild

  @impl true
  def description, do: "Get a random trivia prompt."

  @impl true
  def predicates, do: Quest.predicates() ++ [&cheese_touch_member/1]

  @impl true
  def run(ctx), do: Quest.run(ctx, :prompt)

  defp cheese_touch_member(%{guild_id: guild_id, member: %{roles: roles}} = interaction)
       when is_list(roles) do
    case Guild.get(guild_id) do
      %Guild{cheese_touch_role: role_id} when not is_nil(role_id) ->
        admin = permissions([:administrator])

        role_id in roles or admin.(interaction) == true or
          "You need the cheese-touch role or Administrator permission to use `/prompt`."

      _ ->
        "Cheese touch has not been enabled in this server yet."
    end
  end

  defp cheese_touch_member(_interaction), do: false
end
