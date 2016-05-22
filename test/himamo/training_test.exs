defmodule Himamo.TrainingTest do
  alias Himamo.Model
  use ExUnit.Case

  def a do
    import Model.A, only: [new: 1, put: 3]
    new(2)
    |> put({0, 0}, 0.6) |> put({0, 1}, 0.4)
    |> put({1, 0}, 0.9) |> put({1, 1}, 0.1)
  end

  def b do
    import Model.B, only: [new: 1, put: 3]
    new(n: 2, m: 3)
    |> put({0, 0}, 0.3) |> put({0, 1}, 0.3) |> put({0, 2}, 0.4)
    |> put({1, 0}, 0.8) |> put({1, 1}, 0.1) |> put({1, 2}, 0.1)
  end

  def model, do: %Model{
    a: a,
    b: b,
    pi: Model.Pi.new([0.7, 0.3]),
    n: 2,
    m: 3,
  }

  @tag :skip
  test "perform" do
    Himamo.Training.train(model, [[0, 1, 1, 2, 1, 0, 1]], 1.0e-6)
  end

  @tag :skip
  test "perform multi-obs" do
    Himamo.Training.train(model, [
      [0, 1, 1, 0, 1, 0, 0],
      [1, 1, 1, 2, 1, 1, 1],
      [0, 2, 2, 0, 0, 0, 1],
      [2, 2, 1, 2, 1, 0, 2],
      [0, 0, 0, 2, 0, 1, 1],
    ], 1.0e-6)
  end
end
