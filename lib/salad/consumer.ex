defmodule Salad.Consumer do
  @moduledoc """
  Nostrum event consumer.
  """

  use Nostrum.Consumer
  require Logger
  alias Salad.CommandSystem

  # def start_link, do: Consumer.start_link(__MODULE__)

  def handle_event({:READY, _, _}) do
    if Application.get_env(:salad, :sync_dev_guild) do
      CommandSystem.register_commands_for_guild(Application.get_env(:salad, :dev_guild))
    else
      CommandSystem.register_commands_global()
    end

    Logger.info("Bot is running")
  end

  def handle_event({:INTERACTION_CREATE, ev, _}) do
    CommandSystem.process_interaction(ev)
  end

  def handle_event(_), do: :noop
end
