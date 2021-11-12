defmodule Salad.Consumer do
  @moduledoc """
  Nostrum event consumer.
  """

  use Nostrum.Consumer
  alias Salad.CommandSystem

  def start_link, do: Consumer.start_link(__MODULE__)

  def handle_event({:READY, %{guilds: guilds}, _}) do
    Enum.each(guilds, fn guild ->
      # Global commands soon probs
      CommandSystem.register_commands_for_guild(guild.id)
    end)
  end

  # def handle_event({:MESSAGE_CREATE, msg, _}) do
  #   IO.inspect(msg)
  # end

  def handle_event({:INTERACTION_CREATE, ev, _}) do
    # TODO: handle buttons andt stuff
    CommandSystem.process_interaction(ev)
  end

  def handle_event(_), do: :noop
end
