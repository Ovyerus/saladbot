defmodule Salad.CommandSystem.Component do
  @moduledoc """
  Behaviour for specifying a module to be used as a message component.
  """
  alias Salad.CommandSystem.Structs.Components
  alias Salad.Util

  @valid_types [:button, :select_menu]

  defmacro __using__(opts) do
    {type, _} = Keyword.pop(opts, :type)

    if !type, do: raise(ArgumentError, ":type is required")
    if type not in @valid_types, do: raise(ArgumentError, "Invalid type: #{type}")

    quote do
      @behaviour Salad.CommandSystem.Component
      alias Nostrum.Api

      def name,
        do:
          __MODULE__
          |> to_string()
          |> String.split(".")
          |> List.last()
          |> String.downcase()

      def new(opts) do
        {arg, opts} = Keyword.pop(opts, :arg, "")

        custom_id =
          Salad.CommandSystem.Component.generate_id(
            name(),
            arg
          )

        unquote(
          case type do
            :button ->
              quote do
                {label, opts} = Keyword.pop(opts, :label)
                {emoji, opts} = Keyword.pop(opts, :emoji)
                {disabled, opts} = Keyword.pop(opts, :disabled, false)
                {style, opts} = Keyword.pop(opts, :style, 1)
                {url, opts} = Keyword.pop(opts, :url)

                %Components.Button{
                  label: label,
                  emoji: emoji,
                  custom_id: custom_id,
                  disabled: disabled,
                  style: style,
                  url: url
                }
              end

            :select_menu ->
              quote do
                {options, opts} = Keyword.pop(opts, :options)
                {min_values, opts} = Keyword.pop(opts, :min_values, 1)
                {max_values, opts} = Keyword.pop(opts, :max_values, 1)

                %Components.SelectMenu{
                  custom_id: custom_id,
                  options: options,
                  min_values: min_values,
                  max_values: max_values
                }
              end
          end
        )
      end

      defoverridable name: 0
    end
  end

  @callback name() :: String.t()
  @callback new(keyword()) :: Components.ActionRow.item()

  @callback run(ev :: Nostrum.Struct.Interaction.t(), arg :: String.t()) :: any()

  @spec generate_id(String.t(), any()) :: String.t()
  def generate_id(name, arg \\ "") do
    "#{name}::#{arg}"
    |> then(&"#{&1}::#{Util.hmac(&1)}")
  end
end
