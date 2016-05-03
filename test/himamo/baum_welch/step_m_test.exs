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

  def stats, do: BaumWelch.compute_stats(model, obs_seq)

  test "reestimate_a/3" do
    reestimated_a = StepM.reestimate_a(model, [obs_seq], stats)
    expected = [
      {{0, 0}, 0.709503110},
      {{0, 1}, 0.290496890},
      {{1, 0}, 0.948070330},
      {{1, 1}, 0.051929667},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(reestimated_a, expected)
  end

  test "reestimate_a/2" do
    stats_list = BaumWelch.compute_stats_list(model, [obs_seq])
    reestimated_a = StepM.reestimate_a(model, stats_list)
    expected = [
      {{0, 0}, 0.709503110},
      {{0, 1}, 0.290496890},
      {{1, 0}, 0.948070330},
      {{1, 1}, 0.051929667},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(reestimated_a, expected)
  end

  test "reestimate_a/2 with multiple observations" do
    obs_seq_list = [
      [0, 0, 1],
      [1, 2, 0],
      [0, 2, 0],
    ] |> Enum.map(fn seq ->
      import ObsSeq
      new(seq) |> compute_prob(b)
    end)
    stats_list = BaumWelch.compute_stats_list(model, obs_seq_list)
    reestimated_a = StepM.reestimate_a(model, stats_list)
    expected = [
      {{0, 0}, 0.55040393396557790},
      {{0, 1}, 0.44959606603442230},
      {{1, 0}, 0.91271932451044960},
      {{1, 1}, 0.08728067548955028},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(reestimated_a, expected)
  end

  test "reestimate_b" do
    reestimated_b = StepM.reestimate_b(model, obs_seq, stats)
    expected = [
      {{0, 0}, 0.183004200},
      {{0, 1}, 0.615067920},
      {{0, 2}, 0.201927880},
      {{1, 0}, 0.681578330},
      {{1, 1}, 0.233439370},
      {{1, 2}, 0.084982295},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(reestimated_b, expected)
  end

  test "reestimate_pi" do
    reestimated_pi = StepM.reestimate_pi(model, stats)
    assert_in_delta(Model.Pi.get(reestimated_pi, 0), 0.41516738, 5.0e-9)
    assert_in_delta(Model.Pi.get(reestimated_pi, 1), 0.58483262, 5.0e-9)
  end
end
