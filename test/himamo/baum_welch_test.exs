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
      {{0, 0, 0}, 0.3263493600},
      {{0, 0, 1}, 0.0888180140},
      {{0, 1, 0}, 0.5594560500},
      {{0, 1, 1}, 0.0253765750},
      {{1, 0, 0}, 0.6907178000},
      {{1, 0, 1}, 0.1950876200},
      {{1, 1, 0}, 0.1090607000},
      {{1, 1, 1}, 0.0051338846},
      {{2, 0, 0}, 0.6532516300},
      {{2, 0, 1}, 0.1465268700},
      {{2, 1, 0}, 0.1930061600},
      {{2, 1, 1}, 0.0072153385},
      {{3, 0, 0}, 0.7418791900},
      {{3, 0, 1}, 0.1043786000},
      {{3, 1, 0}, 0.1502196900},
      {{3, 1, 1}, 0.0035225234},
      {{4, 0, 0}, 0.2734296900},
      {{4, 0, 1}, 0.6186691900},
      {{4, 1, 0}, 0.0783536270},
      {{4, 1, 1}, 0.0295474960},
      {{5, 0, 0}, 0.2878227100},
      {{5, 0, 1}, 0.0639606030},
      {{5, 1, 0}, 0.6250660900},
      {{5, 1, 1}, 0.0231505960},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(xi, expected, 5.0e-9)
  end

  test "compute_gamma" do
    model = %Model{
      a: a,
      b: b,
      pi: Model.Pi.new([0.7, 0.3]),
      n: 2,
      m: 2,
    }

    observations = [0, 1, 1, 2, 1, 0, 1]
    gamma = BaumWelch.compute_gamma(model, observations)

    expected = [
      {{0, 0}, 0.41516738},
      {{0, 1}, 0.58483262},
      {{1, 0}, 0.88580541},
      {{1, 1}, 0.11419459},
      {{2, 0}, 0.79977850},
      {{2, 1}, 0.20022150},
      {{3, 0}, 0.84625779},
      {{3, 1}, 0.15374221},
      {{4, 0}, 0.89209888},
      {{4, 1}, 0.10790112},
      {{5, 0}, 0.35178331},
      {{5, 1}, 0.64821669},
    ] |> Enum.into(Map.new)

     assert_all_in_delta(gamma, expected, 5.0e-9)
  end

  test "reestimate_a" do
    model = %Model{
      a: a,
      b: b,
      pi: Model.Pi.new([0.7, 0.3]),
      n: 2,
      m: 2,
    }

    observations = [0, 1, 1, 2, 1, 0, 1]
    xi = BaumWelch.compute_xi(model, observations)
    gamma = BaumWelch.compute_gamma(model, observations)

    a = BaumWelch.reestimate_a(2, length(observations), xi: xi, gamma: gamma)

    expected = [
      {{0, 0}, 0.709503110},
      {{0, 1}, 0.290496890},
      {{1, 0}, 0.948070330},
      {{1, 1}, 0.051929667},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(a, expected, 5.0e-9)
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
