defmodule Himamo.BaumWelch.StepMTest do
  use ExUnit.Case
  import TestHelpers.AllInDelta
  alias Himamo.{BaumWelch, Model, ObsSeq}
  alias BaumWelch.StepM

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

  test "reestimate_a" do
    a = StepM.reestimate_a(2, obs_seq, xi: xi, gamma: gamma)

    expected = [
      {{0, 0}, 0.709503110},
      {{0, 1}, 0.290496890},
      {{1, 0}, 0.948070330},
      {{1, 1}, 0.051929667},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(a, expected, 5.0e-9)
  end

  test "reestimate_b" do
    b = StepM.reestimate_b(model, obs_seq, gamma: gamma)

    expected = [
      {{0, 0}, 0.183004200},
      {{0, 1}, 0.615067920},
      {{0, 2}, 0.201927880},
      {{1, 0}, 0.681578330},
      {{1, 1}, 0.233439370},
      {{1, 2}, 0.084982295},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(b, expected, 5.0e-9)
  end
end
