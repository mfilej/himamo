defmodule Himamo.SimTest do
  use ExUnit.Case
  alias Himamo.{Sim, Model}

  def a do
    import Model.A, only: [new: 1, put: 3]
    new(3)
    |> put({0, 0}, 0.0) |> put({0, 1}, 1.0) |> put({0, 2}, 0.0)
    |> put({1, 0}, 0.0) |> put({1, 1}, 0.0) |> put({1, 2}, 1.0)
    |> put({2, 0}, 1.0) |> put({2, 1}, 0.0) |> put({2, 2}, 0.0)
  end

  def b do
    import Model.B, only: [new: 1, put: 3]
    new(n: 3, m: 3)
    |> put({0, 0}, 1.0) |> put({0, 1}, 0.0) |> put({0, 2}, 0.0)
    |> put({1, 0}, 0.0) |> put({1, 1}, 1.0) |> put({1, 2}, 0.0)
    |> put({2, 0}, 0.0) |> put({2, 1}, 0.0) |> put({2, 2}, 1.0)
  end

  def model, do: %Model{
    a: a,
    b: b,
    pi: Model.Pi.new([1.0, 0.0, 0.0]),
    n: 3,
    m: 3,
  }

  test "generates sequence of words according to a deterministic HMM" do
    assert Sim.simulate(model, 6) == [0, 1, 2, 0, 1, 2]
  end
end
