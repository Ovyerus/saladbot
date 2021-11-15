defmodule Salad.CommandSystem do
  require Logger
  use Bitwise

  alias Nostrum.Api
  alias Salad.CommandSystem.Command, as: CommandMod
  alias Salad.CommandSystem.Structs
  require Salad.CommandSystem.InteractionTypes, as: InteractionTypes

  @table :commands

  def setup do
    init_table()
    load_commands()

    :ok
  end

  @spec all_commands() :: list({String.t(), {Structs.Command.t(), module()}})
  def all_commands(), do: :ets.tab2list(@table)

  def register_commands_for_guild(guild_id) do
    all_commands()
    |> Enum.map(fn {_, {struct, _}} ->
      struct
    end)
    |> then(&Api.bulk_overwrite_guild_application_commands(guild_id, &1))
  end

  @spec process_interaction(Nostrum.Struct.Interaction.t()) :: any()
  def process_interaction(%{type: type} = ev) do
    case type do
      InteractionTypes.command() ->
        process_command(ev)

      InteractionTypes.component() ->
        # TODO: Need automatic HMAC adding/verifying for component events so
        # that we can verify they aren't spoofed. Apparently you can spoof them
        # by saying theyre on an ephemeral message and Discord will just accept it.
        IO.inspect(ev, label: "component interaction")
        :todo

      InteractionTypes.command_autocomplete() ->
        IO.inspect(ev, label: "command autocomplete")
        :todo

      InteractionTypes.ping() ->
        Api.create_interaction_response(ev, %{type: 1})
    end
  end

  defp process_command(%{data: %{name: name}} = ev) do
    with [{^name, {_, mod}}] <- :ets.lookup(@table, name),
         true <-
           Enum.reduce_while(mod.predicates(), true, fn pred, _ ->
             # TODO: limit this struct down a bit so that predicates can't respond to them directly?
             case pred.(ev) do
               true -> {:cont, true}
               x -> {:halt, x}
             end
           end) do
      mod.run(ev)
    else
      false ->
        Api.create_interaction_response(ev, %{
          type: 4,
          data: %{
            content: "You are not allowed to use this command.",
            flags: 1 <<< 6
          }
        })

      x when is_binary(x) ->
        Api.create_interaction_response(ev, %{
          type: 4,
          data: %{
            embeds: [
              %{
                title: "You are not allowed to use this command.",
                description: x
              }
            ],
            flags: 1 <<< 6
          }
        })

      _ ->
        nil
    end
  end

  defp init_table() do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    :ok
  end

  defp load_commands() do
    {:ok, modules} = :application.get_key(:salad, :modules)

    modules =
      Enum.filter(modules, fn mod ->
        CommandMod in (mod.module_info(:attributes)[:behaviour] || [])
      end)

    items =
      for mod <- modules do
        name = mod.name()

        struct = %Structs.Command{
          name: name,
          description: mod.description(),
          type: mod.type(),
          options: mod.options()
        }

        Logger.debug("Loaded command #{mod}")
        {name, {struct, mod}}
      end

    true = :ets.insert(@table, items)
    Logger.debug("Finished loading all commands")

    :ok
  end
end
