defmodule Salad.Util.Constants do
  @moduledoc """
  Module containing macros to easily define constants and enums.
  """

  defmacro __using__(_) do
    quote do
      require Salad.Util.Constants
      import Salad.Util.Constants
    end
  end

  defmacro defenum(offset \\ 0, [_ | _] = names) do
    for {name, idx} <- Enum.with_index(names, offset) do
      quote do
        defmacro unquote({name, [], nil}), do: unquote(idx)
      end
    end
  end
end
