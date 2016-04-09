defmodule Himamo.BaumWelchTest do
  use ExUnit.Case
  alias Himamo.{BaumWelch, Model}

  def a do
    import Model.A, only: [new: 1, put: 3]
    new(2)
    |> put({0, 0}, 0.6)
    |> put({0, 1}, 0.4)
    |> put({1, 0}, 0.9)
    |> put({1, 1}, 0.1)
  end

  def b do
    import Model.B, only: [new: 1, put: 3]
    new(n: 2, m: 3)
    |> put({0, 0}, 0.3)
    |> put({0, 1}, 0.3)
    |> put({0, 2}, 0.4)
    |> put({1, 0}, 0.8)
    |> put({1, 1}, 0.1)
    |> put({1, 2}, 0.1)
  end

  test "compute_alpha" do
    model = %Model{
      a: a,
      b: b,
      pi: Model.Pi.new([0.7, 0.3]),
      n: 2,
      m: 2,
    }

    observations = [0, 1, 1, 2, 1, 0, 1]
    alpha = BaumWelch.compute_alpha(model, observations)

    assert_all_in_delta(alpha, [
      {0.21,  0.24},
      {0.1026,  0.0108},
      {0.021384,  0.004212},
      {0.00664848,  0.00089748},
      {0.001439046,  0.000274914},
      {0.00033325506,  0.00048248784},
      {0.00019025763,  1.8155081e-05},
    ])
  end

  def assert_all_in_delta(actual, expected)
    when tuple_size(actual) == length(expected) do
    actual = Tuple.to_list(actual)

    Enum.zip(actual, expected)
    |>Enum.each(fn {{actual_p1, actual_p2}, {expected_p1, expected_p2}} ->
      assert_in_delta(actual_p1, expected_p1, 1.0e-10)
      assert_in_delta(actual_p2, expected_p2, 1.0e-10)
    end)
  end
end
