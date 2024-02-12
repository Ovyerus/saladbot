defmodule Salad.CommandSystem.Structs do
  @moduledoc false
  use TypedStruct
  use Salad.Util.Constants
  alias Nostrum.Struct, as: NStruct
  alias NStruct.ApplicationCommand

  typedstruct module: Command do
    @moduledoc """
    Internal struct used to gather information for a command to send to Discord.
    """

    @type type() :: ApplicationCommand.command_type()
    @derive Jason.Encoder

    field :name, String.t(), enforce: true
    field :description, String.t(), enforce: true
    field :type, ApplicationCommand.command_type(), default: 1
    field :options, list(Salad.CommandSystem.Structs.Option.t()), enforce: true

    defmodule Type do
      @moduledoc """
      Module containing the different types of commands available.
      """

      defenum 1, [
        :slash,
        :user,
        :message
      ]
    end
  end

  typedstruct module: Option do
    @moduledoc """
    A struct used to define an option for a command.
    """

    @type type() :: ApplicationCommand.command_option_type()

    @derive Jason.Encoder

    field :name, String.t(), enforce: true
    field :description, String.t(), enforce: true
    field :type, ApplicationCommand.command_option_type(), enforce: true
    field :required, boolean(), default: false
    field :choices, list(ApplicationCommand.command_choice()), default: []
    field :options, list(__MODULE__.t()), default: []
    field :channel_types, list(pos_integer()), default: []
    field :autocomplete, boolean(), default: false

    # TODO: pass atoms as type instead of numbers from an enum
    defmodule Type do
      @moduledoc """
      Module containing the different types of options available.
      """

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

  typedstruct module: Context do
    field :name, String.t(), enforce: true
    # TODO: make this a normal map => values, and add another map for the full structs
    field :options, %{String.t() => ResolvedOption.t()}, default: %{}
    field :guild_id, pos_integer()
    field :channel_id, pos_integer()
    field :member, NStruct.Guild.Member.t() | nil
    field :message, NStruct.Message.t() | nil
    field :user, NStruct.User.t() | nil
    # Needed to respond to the interaction
    field :id, pos_integer()
    field :token, String.t()
    # Interaction type (ping, ...) (remove?)
    field :type, pos_integer()
    # Slash command type (data.type usually).
    field :source, pos_integer()

    typedstruct module: ResolvedOption, enforce: true do
      # TODO: look at when does `options` get brought up (subcommands?)
      # Keep string repr of name in case
      field :name, String.t()
      # TODO: atoms here ala above
      field :type, Salad.CommandSystem.Structs.Option.t()
      field :raw, String.t() | integer()

      field :value,
            String.t()
            | integer()
            | boolean()
            | float()
            | NStruct.User.t()
            | NStruct.Guild.Member.t()
            | NStruct.Guild.Role.t()
            | NStruct.Guild.Channel.t()
    end

    @spec from_interaction(NStruct.Interaction.t()) :: __MODULE__.t()
    def from_interaction(%{data: data} = interaction) do
      options = map_options(data.options || [], data.resolved)

      # Was complaining for some reason about %__MODULE__
      struct(__MODULE__, %{
        name: data.name,
        options: options,
        guild_id: interaction.guild_id,
        channel_id: interaction.channel_id,
        member: interaction.member,
        message: interaction.message,
        user: interaction.user,
        id: interaction.id,
        token: interaction.token,
        type: interaction.type,
        source: data.type
      })
    end

    defp map_options(options, resolved) do
      options
      |> Stream.map(fn opt ->
        opt = Map.from_struct(opt)

        case opt.type do
          # TODO: figure out subcommand_group whenever I need it
          # TODO: instead create a `path` property and push subcommand/groups to that, and then options into the normal prop.
          # Can normal options be defined before and outside of a subcommand?
          x when x in [1, 2] ->
            struct(
              ResolvedOption,
              Map.merge(opt, %{value: map_options(opt.options, resolved), raw: nil})
            )

          x when x in [3, 4, 5, 10] ->
            struct(ResolvedOption, Map.merge(opt, %{raw: opt.value}))

          # Users
          6 ->
            struct(
              ResolvedOption,
              Map.merge(opt, %{
                # TODO: users or members?
                value: resolved.users[opt.value],
                raw: opt.value
              })
            )

          # Channels
          7 ->
            struct(
              ResolvedOption,
              Map.merge(opt, %{
                value: resolved.channels[opt.value],
                raw: opt.value
              })
            )

          # Roles
          8 ->
            struct(
              ResolvedOption,
              Map.merge(opt, %{
                value: resolved.roles[opt.value],
                raw: opt.value
              })
            )

          9 ->
            # TODO (mentionables, presumably match first in any, need to investigate)
            nil
        end
      end)
      |> Stream.map(fn opt -> {opt.name, opt} end)
      |> Enum.into(%{})
    end
  end
end
