defmodule SaladTest do
  use ExUnit.Case
  doctest Salad

  test "greets the world" do
    assert Salad.hello() == :world
  end
end
