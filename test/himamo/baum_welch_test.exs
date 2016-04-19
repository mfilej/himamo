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

  test "performing Baum-Welch" do
    new_model = BaumWelch.perform(model, obs_seq)

    expected_a = [
      {{0, 0}, 0.709503110},
      {{0, 1}, 0.290496890},
      {{1, 0}, 0.948070330},
      {{1, 1}, 0.051929667},
    ] |> Enum.into(Map.new)

    expected_b = [
      {{0, 0}, 0.183004200},
      {{0, 1}, 0.615067920},
      {{0, 2}, 0.201927880},
      {{1, 0}, 0.681578330},
      {{1, 1}, 0.233439370},
      {{1, 2}, 0.084982295},
    ] |> Enum.into(Map.new)

    assert_all_in_delta(new_model.b, expected_b)
    assert_all_in_delta(new_model.a, expected_a)
    assert_in_delta(Model.Pi.get(new_model.pi, 0), 0.41516738, 5.0e-9)
    assert_in_delta(Model.Pi.get(new_model.pi, 1), 0.58483262, 5.0e-9)
  end
end
