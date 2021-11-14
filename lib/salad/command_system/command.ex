defmodule Salad.CommandSystem.Command do
  alias Salad.CommandSystem.Structs
  alias Nostrum.Struct, as: NStruct

  defmacro __using__(_) do
    quote do
      @behaviour Salad.CommandSystem.Command

      use Salad.Util.Constants
      alias Salad.CommandSystem.Structs.{Command, Option}
      alias Nostrum.Api
      require Command.Type
      require Option.Type

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
      def autocomplete(_), do: []

      defoverridable name: 0, type: 0, options: 0, autocomplete: 1
    end
  end

  @callback name() :: String.t()
  @callback description() :: String.t()
  @callback type() :: Structs.Command.type()
  @callback options() :: list(Structs.Option.t())
  # predicates?

  @callback run(_ :: Nostrum.Struct.Interaction.t()) :: any()
  @callback autocomplete(_ :: NStruct.Interaction.t()) ::
              list(NStruct.ApplicationCommand.command_choice())
end
