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
    expected_albe = BaumWelch.StepE.compute_alpha_times_beta(alpha, beta)

    assert BaumWelch.compute_stats(model, obs_seq) == %BaumWelch.Stats{
      alpha: expected_alpha,
      beta: expected_beta,
      alpha_times_beta: expected_albe,
    }
  end

  test "reestimate_model" do
    stats_list = BaumWelch.compute_stats_list(model, [obs_seq])
    expected_a = BaumWelch.StepM.reestimate_a(model, stats_list)
    expected_b = BaumWelch.StepM.reestimate_b(model, stats_list)
    expected_pi = BaumWelch.StepM.reestimate_pi(model, stats_list)

    %Model{
      a: a, b: b, pi: pi
    } = BaumWelch.reestimate_model(model, stats_list)

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
    stats_1 = BaumWelch.compute_stats(model, obs_seq_1)
    stats_2 = BaumWelch.compute_stats(model, obs_seq_2)
    stats_3 = BaumWelch.compute_stats(model, obs_seq_3)
    result = BaumWelch.compute_stats_list(model, obs_seq_list)

    assert Enum.at(result, 0) == {obs_seq_1, -3.4076179494650780, stats_1}
    assert Enum.at(result, 1) == {obs_seq_2, -3.5204540025120930, stats_2}
    assert Enum.at(result, 2) == {obs_seq_3, -2.7895314429700933, stats_3}
  end
end
