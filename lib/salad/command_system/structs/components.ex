defmodule Salad.CommandSystem.Structs.Components do
  @moduledoc false
  use TypedStruct
  # alias Nostrum.Struct.ApplicationCommand

  typedstruct module: PartialEmoji do
    @derive Jason.Encoder

    field :name, String.t(), enforce: true
    field :id, String.t()
    field :animated, boolean()
  end

  typedstruct module: ActionRow do
    @type item :: Button.t() | SelectMenu.t()
    @derive Jason.Encoder

    field :type, 1, default: 1
    field :components, list(item()), default: []
  end

  typedstruct module: Button do
    @derive Jason.Encoder

    field :type, 2, default: 2
    field :custom_id, String.t(), enforce: true
    field :label, String.t()
    field :emoji, PartialEmoji.t()
    field :disabled, boolean(), default: false
    field :style, pos_integer(), default: 1
    field :url, String.t()
  end

  typedstruct module: SelectMenu do
    @derive Jason.Encoder

    field :type, 3 | 5 | 6 | 7 | 8, default: 3
    field :custom_id, String.t(), enforce: true
    field :options, list(Option.t())
    field :default_values, list(DefaultValue.t())
    field :min_values, pos_integer(), default: 1
    field :max_values, pos_integer(), default: 1

    typedstruct module: Option do
      @derive Jason.Encoder

      field :label, String.t(), enforce: true
      field :value, String.t(), enforce: true
      field :default, boolean()
      field :description, String.t()
      field :emoji, PartialEmoji.t()
    end

    typedstruct module: DefaultValue do
      @derive Jason.Encoder

      field :id, String.t(), enforce: true
      field :type, String.t(), enforce: true
    end
  end
end
