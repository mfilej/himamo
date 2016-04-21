defmodule Himamo.BaumWelch.StepETest do
  use ExUnit.Case
  import TestHelpers.AllInDelta
  alias Himamo.{Model, ObsSeq}
  alias Himamo.BaumWelch
  alias BaumWelch.StepE

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

  def obs_seq do
    ObsSeq.new([0, 1, 1, 2, 1, 0, 1])
    |> ObsSeq.compute_prob(b)
  end

  def alpha, do: StepE.compute_alpha(model, obs_seq)
  def beta, do: StepE.compute_beta(model, obs_seq)
  def xi, do: StepE.compute_xi(model, obs_seq, alpha: alpha, beta: beta)
  def gamma, do: StepE.compute_gamma(model, obs_seq, xi: xi)

  test "compute" do
    assert StepE.compute(model, obs_seq) == %BaumWelch.Stats{
      alpha: alpha,
      beta: beta,
      gamma: gamma,
      xi: xi,
    }
  end

  test "compute_alpha" do
    expected = [
      {{0, 0}, 0.21},
      {{0, 1}, 0.24},
      {{1, 0}, 0.1026},
      {{1, 1}, 0.0108},
      {{2, 0}, 0.021384},
      {{2, 1}, 0.004212},
      {{3, 0}, 0.00664848},
      {{3, 1}, 0.00089748},
      {{4, 0}, 0.001439046},
      {{4, 1}, 0.000274914},
      {{5, 0}, 0.00033325506},
      {{5, 1}, 0.00048248784},
      {{6, 0}, 0.00019025763},
      {{6, 1}, 1.8155081e-05},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(alpha, expected)
  end

  test "compute_beta" do
    expected = [
      {{0, 0}, 0.00041202932},
      {{0, 1}, 0.00050786063},
      {{1, 0}, 0.001799348},
      {{1, 1}, 0.002203667},
      {{2, 0}, 0.0077948},
      {{2, 1}, 0.0099071},
      {{3, 0}, 0.026528},
      {{3, 1}, 0.035702},
      {{4, 0}, 0.1292},
      {{4, 1}, 0.0818},
      {{5, 0}, 0.22},
      {{5, 1}, 0.28},
      {{6, 0}, 1.0},
      {{6, 1}, 1.0},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(beta, expected)
  end

  test "compute_xi" do
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

    assert_all_in_delta(xi, expected)
  end

  test "compute_gamma" do
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

     assert_all_in_delta(gamma, expected)
  end
end
