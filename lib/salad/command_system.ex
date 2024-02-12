defmodule Salad.CommandSystem do
  require Logger
  import Bitwise

  alias Nostrum.{Api, Struct.Embed}
  alias Salad.CommandSystem.Command, as: CommandMod
  alias Salad.CommandSystem.Component, as: ComponentMod
  alias Salad.CommandSystem.Structs
  alias Salad.Util
  require Salad.CommandSystem.InteractionTypes, as: InteractionTypes

  @commands_table :commands
  @components_table :components

  @spec reply(Salad.CommandSystem.Structs.Context.t(), map()) :: {:ok} | {:error, map()}
  @doc """
  Easily reply to a interaction with the command's context.

  Just a simple wrapper around `Nostrum.Api.create_interaction_response/3`
  to make it work easily with our custom context. A shorthand equivalent for
  doing the following:

      %{id: id, token: token} = ctx
      Nostrum.Api.create_interaction_response(id, token, %{...})

  """
  def reply(%Structs.Context{} = ctx, response),
    do: Api.create_interaction_response(ctx.id, ctx.token, response)

  def setup do
    init_tables()
    load_modules()

    :ok
  end

  @spec all_commands() :: list({String.t(), {Structs.Command.t(), module()}})
  def all_commands(), do: :ets.tab2list(@commands_table)

  def register_commands_for_guild(guild_id) do
    registered =
      all_commands()
      |> Enum.map(fn {_, {struct, _}} ->
        struct
      end)
      |> then(&Api.bulk_overwrite_guild_application_commands(guild_id, &1))

    case registered do
      {:ok, _} ->
        Logger.info("Synced commands for dev server #{guild_id}")
        :ok

      e ->
        Logger.info("Failed to sync commands for dev server #{guild_id}")
        IO.inspect(e)
        e
    end
  end

  def register_commands_global() do
    all_commands()
    |> Enum.map(fn {_, {struct, _}} ->
      struct
    end)
    |> then(&Api.bulk_overwrite_global_application_commands/1)

    Logger.info("Synced commands globally")
  end

  @spec process_interaction(Nostrum.Struct.Interaction.t()) :: any()
  def process_interaction(%{type: type} = ev) do
    case type do
      InteractionTypes.command() ->
        process_command(ev)

      InteractionTypes.component() ->
        process_component(ev)

      InteractionTypes.command_autocomplete() ->
        process_autocomplete(ev)

      InteractionTypes.ping() ->
        Api.create_interaction_response(ev, %{type: 1})
    end
  end

  defp process_command(%{data: %{name: name}} = ev) do
    with [{^name, {_, mod}}] <- :ets.lookup(@commands_table, name),
         true <-
           Enum.reduce_while(mod.predicates(), true, fn pred, _ ->
             # TODO: limit this struct down a bit so that predicates can't respond to them directly?
             case pred.(ev) do
               true -> {:cont, true}
               x -> {:halt, x}
             end
           end) do
      ctx = Structs.Context.from_interaction(ev)
      mod.run(ctx)
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
              %Embed{
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

  defp process_autocomplete(%{data: %{name: name}} = ev) do
    with [{^name, {_, mod}}] <- :ets.lookup(@commands_table, name),
         true <- {:autocomplete, 1} in mod.__info__(:functions) do
      # TODO: custom autocomplete context?
      # TODO: can we cancel in progress autocompletes if we detect new ones?
      choices = mod.autocomplete(ev)

      Api.create_interaction_response(ev, %{
        type: 8,
        data: %{choices: choices}
      })
    else
      false ->
        Logger.warning("No autocomplete function for command: #{name}")
        :noop

      _ ->
        :noop
    end
  end

  defp process_component(%{data: %{custom_id: custom_id}} = ev) do
    with [name, arg, hmac] <- String.split(custom_id, "::"),
         ^hmac <- Util.hmac("#{name}::#{arg}"),
         [{^name, mod}] <- :ets.lookup(@components_table, name) do
      mod.run(ev, arg)
    else
      [] -> :noop
      [_ | _] -> :noop
      e -> Logger.error(inspect(e))
    end
  end

  defp init_tables() do
    :ets.new(@commands_table, [:named_table, :set, :public, read_concurrency: true])
    :ets.new(@components_table, [:named_table, :set, :public, read_concurrency: true])
    :ok
  end

  defp load_modules() do
    {:ok, modules} = :application.get_key(:salad, :modules)

    command_modules =
      Enum.filter(modules, fn mod ->
        CommandMod in (mod.module_info(:attributes)[:behaviour] || [])
      end)

    component_modules =
      Enum.filter(modules, fn mod ->
        ComponentMod in (mod.module_info(:attributes)[:behaviour] || [])
      end)

    command_items =
      for mod <- command_modules do
        name = mod.name()

        # TODO: validate name and description
        struct = %Structs.Command{
          name: name,
          description: mod.description(),
          type: mod.type(),
          options: mod.options()
        }

        Logger.debug("Loaded command #{mod}")
        {name, {struct, mod}}
      end

    true = :ets.insert(@commands_table, command_items)
    Logger.debug("Finished loading all commands")

    component_items =
      for mod <- component_modules do
        name = mod.name()
        Logger.debug("Loaded component #{mod}")
        {name, mod}
      end

    true = :ets.insert(@components_table, component_items)
    Logger.debug("Finished loading all components")

    :ok
  end
end
