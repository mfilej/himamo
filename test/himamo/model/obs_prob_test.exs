defmodule Himamo.ObsProbTest do
  use ExUnit.Case
  alias Himamo.Model.ObsProb
  alias Himamo.Model.B

  def b do
    B.new(2, 2)
    |> B.put({0, 0}, 0.5)
    |> B.put({0, 1}, 0.5)
    |> B.put({1, 0}, 0.2)
    |> B.put({1, 1}, 0.8)
  end

  test "new" do
    observations =  [1, 1, 0]

    %ObsProb{states: states} = ObsProb.new(b, observations)
    assert states == {
      {0.5, 0.5, 0.5},
      {0.8, 0.8, 0.2},
    }
  end

  test "b_map" do
    observations =  [0, 1, 1, 1, 1, 0, 1]
    assert ObsProb.b_map(b, observations) == {
      {0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5},
      {0.2, 0.8, 0.8, 0.8, 0.8, 0.2, 0.8},
    }
  end
end
