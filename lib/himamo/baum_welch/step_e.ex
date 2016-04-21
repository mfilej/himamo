defmodule Himamo.BaumWelch.StepE do
  @moduledoc ~S"""
  Defines components of the E-step of the Baum-Welch algorithm (Expectation).

  Calculates required statistics for the given model.
  """

  alias Himamo.{Matrix, Model, ObsSeq}

  @doc ~S"""
  Computes alpha variable for Baum-Welch.

  `α_t(i)` is the probability of being in state `S_i` at time `t` after
  observing the first `t` symbols.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_alpha(Model.t, ObsSeq.t) :: Matrix.t
  def compute_alpha(%Model{a: a, pi: pi, n: num_states}, %ObsSeq{len: seq_len, prob: obs_prob}) do
    states_range = 0..num_states-1
    obs_range = 1..seq_len-1

    # initialization
    first_row =
      for j <- states_range do
        {{0, j}, Model.Pi.get(pi, j) * Model.ObsProb.get(obs_prob, {j, 0})}
      end
      |> Enum.into(Matrix.new({seq_len, num_states}))

    # induction
    Enum.reduce(obs_range, first_row, fn(t, partial_alpha) ->
      for j <- states_range do
        rhs = Model.ObsProb.get(obs_prob, {j, t})
        sum =
          for i <- states_range do
            Matrix.get(partial_alpha, {t-1, i}) * Model.A.get(a, {i, j})
          end |> Enum.sum

        {{t, j}, rhs * sum}
      end
      |> Enum.into(partial_alpha)
    end)
  end

  @doc ~S"""
  Computes beta variable for Baum-Welch.

  `ß_t(i)` is the probability of being in state `S_i` at time `t` and
  observing the partial sequence from `t+1` to the end.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_beta(Model.t, ObsSeq.t) :: Matrix.t
  def compute_beta(%Model{a: a, n: num_states}, %ObsSeq{len: seq_len, prob: obs_prob}) do
    states_range = 0..num_states-1

    # initialization
    last_row = for j <- states_range do
      {{seq_len-1, j}, 1}
    end |> Enum.into(Matrix.new({seq_len, num_states}))

    # induction
    Enum.reduce((seq_len-2)..0, last_row, fn(t, partial_beta) ->
      for i <- states_range do
        sum = for j <- states_range do
          transition_prob = Model.A.get(a, {i, j})
          emission_prob = Model.ObsProb.get(obs_prob, {j, t+1})
          prev_beta = Matrix.get(partial_beta, {t+1, j})
          transition_prob * emission_prob * prev_beta
        end |> Enum.sum

        {{t, i}, sum}
      end |> Enum.into(partial_beta)
    end)
  end

  @doc ~S"""
  Computes xi variable for Baum-Welch.

  `ξ_t(i,j)` is the probability of being in state `S_i` at time `t` and in
  state `S_j` at time `t+1` given the full observation sequence.

  Returns tuple of tuples of tuples (size `T×N×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_xi(Model.t, ObsSeq.t, [alpha: Matrix.t, beta: Matrix.t]) :: Matrix.t
  def compute_xi(
    %Model{a: a, n: num_states},
    %ObsSeq{len: seq_len, prob: obs_prob},
    alpha: alpha,
    beta: beta
  ) do
    states_range = 0..num_states-1

    map_states_2d = fn(fun) ->
      Stream.flat_map(states_range, fn(i) ->
        Enum.map(states_range, fn(j) ->
          fun.({i, j})
        end)
      end)
    end

    Enum.flat_map((0..seq_len-2), fn(t) ->
      denominator = map_states_2d.(fn({i, j}) ->
        curr_alpha = Matrix.get(alpha, {t, i})
        curr_a = Model.A.get(a, {i, j})
        curr_b_map = Model.ObsProb.get(obs_prob, {j, t+1})
        curr_beta = Matrix.get(beta, {t+1, j})

        curr_alpha * curr_a * curr_b_map * curr_beta
      end)
      |> Enum.sum

      map_states_2d.(fn({i, j}) ->
        curr_alpha = Matrix.get(alpha, {t, i})
        curr_a = Model.A.get(a, {i, j})
        curr_b_map = Model.ObsProb.get(obs_prob, {j, t+1})
        curr_beta = Matrix.get(beta, {t+1, j})
        numerator = curr_alpha * curr_a * curr_b_map * curr_beta

        {{t, i, j}, numerator/denominator}
      end)
    end)
    |> Enum.into(Matrix.new({seq_len-1, num_states, num_states}))
  end

  @doc ~S"""
  Computes gamma variable for Baum-Welch.

  `γ_t(i)` is the probability of being in state `S_i` at time `t` given the
  full observation sequence.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_gamma(Model.t, ObsSeq.t, [xi: Matrix.t]) :: Matrix.t
  def compute_gamma(%Model{n: num_states}, obs_seq, xi: xi) do
    seq_len = obs_seq.len

    Enum.flat_map(0..seq_len-2, fn(t) ->
      Enum.map(0..num_states-1, fn(i) ->
        sum = Enum.map(0..num_states-1, fn(j) ->
          Matrix.get(xi, {t, i, j})
        end)
        |> Enum.sum

        {{t, i}, sum}
      end)
    end)
    |> Enum.into(Matrix.new({seq_len-1, num_states}))
  end
end
