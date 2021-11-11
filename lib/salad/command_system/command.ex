defmodule Salad.CommandSystem.Command do
  alias Salad.CommandSystem.Structs

  defmacro __using__(_) do
    quote do
      @behaviour Salad.CommandSystem.Command

      use Salad.Util.Constants
      require CommandSystem.Structs.Command, as: Command
      require CommandSystem.Structs.Option, as: Option

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

      defoverridable name: 0, type: 0, options: 0
    end
  end

  @callback name() :: String.t()
  @callback description() :: String.t()
  @callback type() :: Structs.Command.type()
  @callback options() :: list(Structs.Option.t())
  # predicates?

  @callback run(_ :: any()) :: any()
end
