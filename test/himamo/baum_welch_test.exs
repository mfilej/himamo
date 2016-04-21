defmodule Himamo.BaumWelchTest do
  use ExUnit.Case
  import TestHelpers.AllInDelta
  alias Himamo.{BaumWelch, Model, ObsSeq}

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

  test "compute" do
    assert BaumWelch.compute(model, obs_seq) == %BaumWelch.Stats{
      alpha: alpha,
      beta: beta,
      gamma: gamma,
      xi: xi,
    }
  end
end
