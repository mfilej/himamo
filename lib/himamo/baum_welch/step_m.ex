defmodule Himamo.BaumWelch.StepM do
  @moduledoc ~S"""
  Defines the M-step of the Baum-Welch algorithm (Maximization).

  Maximizes the model's parameters.
  """

  alias Himamo.{Matrix, Model, ObsSeq}
  alias Himamo.BaumWelch.StepE

  @doc ~S"""
  Returns a new model with re-estimated parameters `A`, `B`, and `π`.
  """
  @spec reestimate(Model.t, ObsSeq.t, StepE.t) :: Model.t
  def reestimate(model, obs_seq, step_e) do
    %{model |
      a: reestimate_a(model, obs_seq, step_e),
      b: reestimate_b(model, obs_seq, step_e),
      pi: reestimate_pi(model, step_e),
    }
  end

  @doc ~S"""
  Re-estimates the `A` variable.

  Each entry in `A=[a_{i,j}]` is recomputed as: expected number of transitions
  from state `S_i` to state `S_j` divided by the expected number of
  transitions from state `S_j`.

  This is part of the _M_ step of Baum-Welch.
  """
  @spec reestimate_a(Model.t, ObsSeq.t, StepE.t) :: Matrix.t
  def reestimate_a(%Model{a: a, n: num_states}, %ObsSeq{len: obs_len, prob: obs_prob}, %StepE{alpha: alpha, beta: beta}) do
    states_range = 0..num_states-1

    for i <- states_range, j <- states_range do
      {numerator, denominator} =
        Enum.reduce(0..obs_len-2, {0, 0}, fn (t, {numer, denom}) ->
          new_numer =
            Matrix.get(alpha, {t, i}) *
            Model.A.get(a, {i, j}) *
            Model.ObsProb.get(obs_prob, {j, t+1}) *
            Matrix.get(beta, {t+1, j})

          new_denom =
            Matrix.get(alpha, {t, i}) * Matrix.get(beta, {t, i})

          {(numer + new_numer), (denom + new_denom)}
        end)

      {{i, j}, numerator/denominator}
    end
    |> Enum.into(Matrix.new({num_states, num_states}))
  end

  @doc ~S"""
  Re-estimates the `B` variable.
  """
  @spec reestimate_b(Model.t, ObsSeq.t, StepE.t) :: Matrix.t
  def reestimate_b(%Model{n: num_states, m: num_symbols}, %ObsSeq{seq: observations}, %StepE{gamma: gamma}) do
    states_range = 0..num_states-1
    symbols_range = 0..num_symbols-1

    observations = List.delete_at(observations, -1)

    for j <- states_range, k <- symbols_range do
      {numerator, denominator} =
        Stream.with_index(observations)
        |> Enum.reduce({0, 0}, fn({o, t}, {numer, denom}) ->
          gamma_el = Matrix.get(gamma, {t, j})
          denom = denom + gamma_el

          if o == k, do: numer = numer + gamma_el

          {numer, denom}
        end)

      {{j, k}, numerator/denominator}
    end
    |> Enum.into(Matrix.new({num_states, num_symbols}))
  end

  @doc ~S"""
  Re-estimates the `π` variable.
  """
  @spec reestimate_pi(Model.t, StepE.t) :: Model.Pi.t
  def reestimate_pi(%Model{n: num_states}, %StepE{gamma: gamma}) do
    for i <- 0..num_states-1 do
      Matrix.get(gamma, {0, i})
    end
    |> Model.Pi.new
  end
end
