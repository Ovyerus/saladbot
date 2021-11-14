defmodule Salad.CommandSystem.InteractionTypes do
  @moduledoc false
  use Salad.Util.Constants

  defenum 1, [
    :ping,
    :command,
    :component,
    :command_autocomplete
  ]
end
