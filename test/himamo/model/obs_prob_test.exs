defmodule Himamo.ObsProbTest do
  use ExUnit.Case
  alias Himamo.Model.ObsProb
  alias Himamo.Model.B

  def b do
    B.new(m: 2, n: 2)
    |> B.put({0, 0}, 0.5)
    |> B.put({0, 1}, 0.5)
    |> B.put({1, 0}, 0.2)
    |> B.put({1, 1}, 0.8)
  end

  test "new" do
    observations =  [1, 1, 0]

    result = ObsProb.new(b, observations)
    assert ObsProb.get(result, {0, 0}) == 0.5
    assert ObsProb.get(result, {0, 1}) == 0.5
    assert ObsProb.get(result, {0, 2}) == 0.5
    assert ObsProb.get(result, {1, 0}) == 0.8
    assert ObsProb.get(result, {1, 1}) == 0.8
    assert ObsProb.get(result, {1, 2}) == 0.2
  end

  test "get" do
    assert B.get(b, {0, 1}) == 0.5
    assert B.get(b, {1, 0}) == 0.2
    assert B.get(b, {1, 1}) == 0.8
  end
end
