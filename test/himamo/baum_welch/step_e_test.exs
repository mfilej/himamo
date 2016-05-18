defmodule Himamo.BaumWelch.StepETest do
  use ExUnit.Case
  import TestHelpers.AllInDelta
  alias Himamo.{Model, ObsSeq}
  alias Himamo.BaumWelch

  defdelegate math_log(float), to: :math, as: :log

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

  def alpha, do: BaumWelch.StepE.compute_alpha(model, obs_seq)
  def beta, do: BaumWelch.StepE.compute_beta(model, obs_seq)
  def xi, do: BaumWelch.StepE.compute_xi(model, obs_seq, alpha: alpha, beta: beta)
  def gamma, do: BaumWelch.StepE.compute_gamma(model, obs_seq, xi: xi)

  test "compute_alpha" do
    expected = [
      {{0, 0}, math_log(0.21000000000)},
      {{0, 1}, math_log(0.24000000000)},
      {{1, 0}, math_log(0.10260000000)},
      {{1, 1}, math_log(0.01080000000)},
      {{2, 0}, math_log(0.02138400000)},
      {{2, 1}, math_log(0.00421200000)},
      {{3, 0}, math_log(0.00664848000)},
      {{3, 1}, math_log(0.00089748000)},
      {{4, 0}, math_log(0.00143904600)},
      {{4, 1}, math_log(0.00027491400)},
      {{5, 0}, math_log(0.00033325506)},
      {{5, 1}, math_log(0.00048248784)},
      {{6, 0}, math_log(0.00019025763)},
      {{6, 1}, math_log(1.8155081e-05)},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(alpha, expected, 1.0e-7)
  end

  test "compute_beta" do
    expected = [
      {{0, 0}, math_log(0.00041202932)},
      {{0, 1}, math_log(0.00050786063)},
      {{1, 0}, math_log(0.00179934800)},
      {{1, 1}, math_log(0.00220366700)},
      {{2, 0}, math_log(0.00779480000)},
      {{2, 1}, math_log(0.00990710000)},
      {{3, 0}, math_log(0.02652800000)},
      {{3, 1}, math_log(0.03570200000)},
      {{4, 0}, math_log(0.12920000000)},
      {{4, 1}, math_log(0.08180000000)},
      {{5, 0}, math_log(0.22000000000)},
      {{5, 1}, math_log(0.28000000000)},
      {{6, 0}, math_log(1.00000000000)},
      {{6, 1}, math_log(1.00000000000)},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(beta, expected)
  end

  test "compute_xi" do
    expected = [
      {{0, 0, 0}, math_log(0.3263493600)},
      {{0, 0, 1}, math_log(0.0888180140)},
      {{0, 1, 0}, math_log(0.5594560500)},
      {{0, 1, 1}, math_log(0.0253765750)},
      {{1, 0, 0}, math_log(0.6907178000)},
      {{1, 0, 1}, math_log(0.1950876200)},
      {{1, 1, 0}, math_log(0.1090607000)},
      {{1, 1, 1}, math_log(0.0051338846)},
      {{2, 0, 0}, math_log(0.6532516300)},
      {{2, 0, 1}, math_log(0.1465268700)},
      {{2, 1, 0}, math_log(0.1930061600)},
      {{2, 1, 1}, math_log(0.0072153385)},
      {{3, 0, 0}, math_log(0.7418791900)},
      {{3, 0, 1}, math_log(0.1043786000)},
      {{3, 1, 0}, math_log(0.1502196900)},
      {{3, 1, 1}, math_log(0.0035225234)},
      {{4, 0, 0}, math_log(0.2734296900)},
      {{4, 0, 1}, math_log(0.6186691900)},
      {{4, 1, 0}, math_log(0.0783536270)},
      {{4, 1, 1}, math_log(0.0295474960)},
      {{5, 0, 0}, math_log(0.2878227100)},
      {{5, 0, 1}, math_log(0.0639606030)},
      {{5, 1, 0}, math_log(0.6250660900)},
      {{5, 1, 1}, math_log(0.0231505960)},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(xi, expected, 5.0e-8)
  end

  test "compute_gamma" do
    expected = [
      {{0, 0}, math_log(0.41516738)},
      {{0, 1}, math_log(0.58483262)},
      {{1, 0}, math_log(0.88580541)},
      {{1, 1}, math_log(0.11419459)},
      {{2, 0}, math_log(0.79977850)},
      {{2, 1}, math_log(0.20022150)},
      {{3, 0}, math_log(0.84625779)},
      {{3, 1}, math_log(0.15374221)},
      {{4, 0}, math_log(0.89209888)},
      {{4, 1}, math_log(0.10790112)},
      {{5, 0}, math_log(0.35178331)},
      {{5, 1}, math_log(0.64821669)},
    ] |> Enum.into(Map.new)

     assert_all_in_delta(gamma, expected, 5.0e-8)
  end
end
