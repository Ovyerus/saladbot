defmodule Salad.Consumer do
  @moduledoc """
  Nostrum event consumer.
  """

  use Nostrum.Consumer
  alias Nostrum.Api

  def start_link, do: Consumer.start_link(__MODULE__)

  def handle_event({:MESSAGE_CREATE, msg, _}) do
    IO.inspect(msg)
  end

  def handle_event(_), do: :noop
end
