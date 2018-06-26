defmodule PasetoPlugTest do
  use ExUnit.Case
  doctest PasetoPlug

  test "greets the world" do
    assert PasetoPlug.hello() == :world
  end
end
