defmodule Salad.CommandSystem.Structs.Components do
  @moduledoc false
  use TypedStruct
  # alias Nostrum.Struct.ApplicationCommand

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
    field :label, String.t(), enforce: true
    field :disabled, boolean(), default: false
    field :style, pos_integer(), default: 1
    field :url, String.t()
  end

  typedstruct module: SelectMenu do
    @derive Jason.Encoder

    field :type, 3, default: 3
    field :custom_id, String.t(), enforce: true
    field :options, list(Option.t()), enforce: true
    field :min_values, pos_integer(), default: 1
    field :max_values, pos_integer(), default: 1

    typedstruct module: Option do
      @derive Jason.Encoder

      field :label, String.t(), enforce: true
      field :value, String.t(), enforce: true
      field :description, String.t()
      # TODO: type the map
      field :emoji, map()
      field :default, boolean(), default: false
    end
  end
end
