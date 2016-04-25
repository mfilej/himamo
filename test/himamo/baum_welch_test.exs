defmodule Himamo.BaumWelchTest do
  use ExUnit.Case
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

  test "compute_stats" do
    expected_alpha = alpha = BaumWelch.StepE.compute_alpha(model, obs_seq)
    expected_beta = beta = BaumWelch.StepE.compute_beta(model, obs_seq)
    expected_xi = xi = BaumWelch.StepE.compute_xi(model, obs_seq, alpha: alpha, beta: beta)
    expected_gamma = BaumWelch.StepE.compute_gamma(model, obs_seq, xi: xi)

    assert BaumWelch.compute_stats(model, obs_seq) == %BaumWelch.Stats{
      alpha: expected_alpha,
      beta: expected_beta,
      gamma: expected_gamma,
      xi: expected_xi,
    }
  end

  test "reestimate_model" do
    stats = BaumWelch.compute_stats(model, obs_seq)
    expected_a = BaumWelch.StepM.reestimate_a(model, [obs_seq], stats)
    expected_b = BaumWelch.StepM.reestimate_b(model, obs_seq, stats)
    expected_pi = BaumWelch.StepM.reestimate_pi(model, stats)

    %Model{
      a: a, b: b, pi: pi
    } = BaumWelch.reestimate_model(model, obs_seq, stats)

    assert a == expected_a
    assert b == expected_b
    assert pi == expected_pi
  end

  test "compute_stats_list" do
    obs_seq_list = [obs_seq_1, obs_seq_2, obs_seq_3] = fn ->
      import ObsSeq
      [
        compute_prob(new([0, 2, 1]), b),
        compute_prob(new([1, 0, 1]), b),
        compute_prob(new([2, 0, 0]), b),
      ]
    end.()

    assert BaumWelch.compute_stats_list(model, obs_seq_list) == [
      {obs_seq_1, BaumWelch.compute_stats(model, obs_seq_1)},
      {obs_seq_2, BaumWelch.compute_stats(model, obs_seq_2)},
      {obs_seq_3, BaumWelch.compute_stats(model, obs_seq_3)},
    ]
  end
end
