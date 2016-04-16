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

  test "compute_beta" do
    model = %Model{
      a: a,
      b: b,
      pi: Model.Pi.new([0.7, 0.3]),
      n: 2,
      m: 2,
    }

    observations = [0, 1, 1, 2, 1, 0, 1]
    beta = BaumWelch.compute_beta(model, observations)

    assert_all_in_delta(beta, [
       {0.00041202932,  0.00050786063},
       {0.001799348,  0.002203667},
       {0.0077948,  0.0099071},
       {0.026528,  0.035702},
       {0.1292,  0.0818},
       {0.22,  0.28},
       {1.0,  1.0},
    ])
  end

  test "compute_xi" do
    model = %Model{
      a: a,
      b: b,
      pi: Model.Pi.new([0.7, 0.3]),
      n: 2,
      m: 2,
    }

    observations = [0, 1, 1, 2, 1, 0, 1]
    xi = BaumWelch.compute_xi(model, observations)
    expected = [
      {{0, 0, 0}, 0.32634936},
      {{0, 0, 1}, 0.088818014},
      {{0, 1, 0}, 0.55945605},
      {{0, 1, 1}, 0.025376575},
      {{1, 0, 0}, 0.6907178},
      {{1, 0, 1}, 0.19508762},
      {{1, 1, 0}, 0.1090607},
      {{1, 1, 1}, 0.0051338846},
      {{2, 0, 0}, 0.65325163},
      {{2, 0, 1}, 0.14652687},
      {{2, 1, 0}, 0.19300616},
      {{2, 1, 1}, 0.0072153385},
      {{3, 0, 0}, 0.74187919},
      {{3, 0, 1}, 0.1043786},
      {{3, 1, 0}, 0.15021969},
      {{3, 1, 1}, 0.0035225234},
      {{4, 0, 0}, 0.27342969},
      {{4, 0, 1}, 0.61866919},
      {{4, 1, 0}, 0.078353627},
      {{4, 1, 1}, 0.029547496},
      {{5, 0, 0}, 0.28782271},
      {{5, 0, 1}, 0.063960603},
      {{5, 1, 0}, 0.62506609},
      {{5, 1, 1}, 0.023150596},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(xi, expected, 5.0e-9)
  end

  def assert_all_in_delta(actual, expected, delta \\ 1.0e-10)
  def assert_all_in_delta(actual, expected, delta)
    when tuple_size(actual) == length(expected) do
    actual = Tuple.to_list(actual)

    Enum.zip(actual, expected)
    |>Enum.each(fn {{actual_p1, actual_p2}, {expected_p1, expected_p2}} ->
      assert_in_delta(actual_p1, expected_p1, delta)
      assert_in_delta(actual_p2, expected_p2, delta)
    end)
  end
  def assert_all_in_delta(%Himamo.Matrix{map: map} = _actual, expected, delta)
    when map_size(map) == map_size(expected) do
    Enum.each(map, fn({position, entry}) ->
      expected_value = Map.fetch!(expected, position)
      assert_in_delta(entry, expected_value, delta)
    end)
  end
end
