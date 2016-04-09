defmodule Himamo.Model.BTest do
  use ExUnit.Case
  alias Himamo.Model.B
  doctest B

  test "num_states" do
    b = B.new(m: 4, n: 5)

    assert B.num_states(b) == 5
  end
end
