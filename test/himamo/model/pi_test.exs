defmodule Himamo.Model.PiTest do
  use ExUnit.Case
  alias Himamo.Model.Pi
  doctest Pi

  test "raises when trying to access a state out of bounds" do
    pi = Pi.new([0.3, 0.2, 0.5])

    assert_raise FunctionClauseError, fn ->
      Pi.get(pi, -1)
    end

    assert_raise FunctionClauseError, fn ->
      Pi.get(pi, 3)
    end
  end
end
