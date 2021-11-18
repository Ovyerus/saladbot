defmodule Salad.Commands.Setup do
  @moduledoc false
  use Bitwise
  use Salad.CommandSystem.Command

  require Logger
  alias Salad.Repo

  @impl true
  def description, do: "Initialise the server for using the bot"

  @impl true
  def predicates,
    do: [
      guild_only(message: "This command can only be run in a server."),
      permissions([:manage_guild])
    ]

  @impl true
  @spec run(Salad.CommandSystem.Structs.Context.t()) :: any()
  def run(%{guild_id: guild_id} = ctx) do
    with nil <- Repo.Guild.get(guild_id),
         {:ok, _} <- Repo.Guild.create(guild_id) do
      reply(ctx, %{
        type: 4,
        data: %{
          content:
            "This server has now been set up. You can now run `/create` to create a role group."
        }
      })
    else
      {:error, e} ->
        Logger.error(e)

        reply(ctx, %{
          type: 4,
          data: %{
            content: "Failed to set up this server.",
            flags: 1 <<< 6
          }
        })

      _ ->
        reply(ctx, %{
          type: 4,
          data: %{
            content: "This server has already been set up.",
            flags: 1 <<< 6
          }
        })
    end
  end
end
