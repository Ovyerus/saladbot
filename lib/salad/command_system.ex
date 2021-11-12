defmodule Salad.CommandSystem do
  require Logger

  alias Nostrum.Api
  alias Salad.CommandSystem.Command, as: CommandMod
  alias Salad.CommandSystem.Structs

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
  def process_interaction(ev) do
    with name <- ev.data.name,
         [{^name, {_, mod}}] <- :ets.lookup(@table, name) do
      mod.run(ev)
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
