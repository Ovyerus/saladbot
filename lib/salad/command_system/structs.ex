defmodule Salad.CommandSystem.Structs do
  @moduledoc false
  use TypedStruct
  use Salad.Util.Constants
  alias Nostrum.Struct.ApplicationCommand

  typedstruct module: Command do
    @type type :: ApplicationCommand.command_type()
    @derive Jason.Encoder

    field :name, String.t(), enforce: true
    field :description, String.t(), enforce: true
    field :type, ApplicationCommand.command_type(), default: 1
    field :options, list(Salad.CommandSystem.Structs.Option.t()), enforce: true

    defmodule Type do
      @moduledoc false
      defenum 1, [
        :slash,
        :user,
        :message
      ]
    end
  end

  typedstruct module: Option do
    @type type :: ApplicationCommand.command_option_type()
    @derive Jason.Encoder

    field :name, String.t(), enforce: true
    field :description, String.t(), enforce: true
    field :type, ApplicationCommand.command_option_type(), enforce: true
    field :required, boolean(), default: false
    field :choices, ApplicationCommand.command_choice(), default: []
    field :options, list(__MODULE__.t()), default: []
    field :channel_types, list(pos_integer()), default: []
    field :autocomplete, boolean(), default: false

    defmodule Type do
      @moduledoc false
      defenum 1, [
        :subcommand,
        :subcommand_group,
        :string,
        :integer,
        :boolean,
        :user,
        :channel,
        :role,
        :mentionable,
        :number
      ]
    end
  end
end
