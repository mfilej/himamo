defmodule Himamo.BaumWelch.StepM do
  @defmodule ~S"""
  Defines the M-step of the Baum-Welch algorithm (Maximization).

  Maximizes the model's parameters.
  """

  alias Himamo.{Matrix, Model, ObsSeq}

  @doc ~S"""
  Re-estimates the `A` variable.

  Requires the following arguments:
    * `num_states` - number of states of the model being re-estimated (`N`).
    * `obs_len` - observation sequence length (`T`).
    * `xi` - the computed variable `ξ` (see `compute_xi/2`).
    * `gamma` - the computed variable `γ` (see `compute_gamma/2`).

  Each entry in `A=[a_{i,j}]` is recomputed as: expected number of transitions
  from state `S_i` to state `S_j` divided by the expected number of
  transitions from state `S_j`.

  This is part of the _M_ step of Baum-Welch.
  """
  @spec reestimate_a(Model.t, ObsSeq.t, StepE.t) :: Matrix.t
  def reestimate_a(%Model{n: num_states}, %ObsSeq{len: obs_len}, %StepE{xi: xi, gamma: gamma}) do
    states_range = 0..num_states-1

    Enum.flat_map(states_range, fn(i) ->
      Enum.map(states_range, fn(j) ->
        {numerator, denominator} =
          Enum.reduce(0..obs_len-2, {0, 0}, fn (t, {numer, denom}) ->
            new_numer = numer + Matrix.get(xi, {t, i, j})
            new_denom = denom + Matrix.get(gamma, {t, i})
            {new_numer, new_denom}
          end)

        {{i, j}, numerator/denominator}
      end)
    end)
    |> Enum.into(Matrix.new({num_states, num_states}))
  end

  @doc ~S"""
  Re-estimates the `B` variable.

  Requires the following arguments:
  * `model` - the HMM.
  * `observations` - the observation sequence.
  * `gamma` - the computed variable `γ` (see `compute_gamma/2`).
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

  Requires the following arguments:
  * `model` - the HMM.
  * `gamma` - the computed variable `γ` (see `compute_gamma/2`).
  """
  @spec reestimate_pi(Model.t, StepE.t) :: Model.Pi.t
  def reestimate_pi(%Model{n: num_states}, %StepE{gamma: gamma}) do
    for i <- 0..num_states-1 do
      Matrix.get(gamma, {0, i})
    end
    |> Model.Pi.new
  end
end
