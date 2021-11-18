defmodule Salad.CommandSystem.Command do
  @moduledoc """
  Behaviour for specifying a module to be used as a command.
  Also imports some aliases and useful macros to help reduce repetition.
  """
  alias Salad.CommandSystem
  alias CommandSystem.Structs
  alias Nostrum.Struct, as: NStruct

  @type predicate() :: (term() -> boolean() | String.t())

  defmacro __using__(_) do
    quote do
      @behaviour Salad.CommandSystem.Command

      use Salad.Util.Constants
      alias CommandSystem.Structs.{Command, Context, Option}
      alias Nostrum.Api
      require Command.Type
      require Option.Type
      import CommandSystem.Predicates
      import CommandSystem, only: [reply: 2]

      # Default `name` to getting the name of the module, by splitting on dots
      # and downcasing the last part.
      def name,
        do:
          __MODULE__
          |> to_string()
          |> String.split(".")
          |> List.last()
          |> String.downcase()

      def type, do: Command.Type.slash()
      def options, do: []
      def predicates, do: []
      def autocomplete(_), do: []

      defoverridable name: 0, type: 0, options: 0, predicates: 0, autocomplete: 1
    end
  end

  @callback name() :: String.t()
  @callback description() :: String.t()
  @callback type() :: Structs.Command.type()
  @callback options() :: list(Structs.Option.t())
  @callback predicates() :: [predicate()]
  # TODO: need to figure Discord's permission stuff to restrict commands that way (still have them added as a predicate though)

  @callback run(ctx :: Struct.Context.t()) :: any()
  @callback autocomplete(ev :: NStruct.Interaction.t()) ::
              list(NStruct.ApplicationCommand.command_choice())
end
