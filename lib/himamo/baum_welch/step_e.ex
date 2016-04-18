defmodule Himamo.BaumWelch.StepE do
  @moduledoc ~S"""
  Defines the E-step of the Baum-Welch algorithm.

  Calculates required statistics for the given model.
  """

  alias Himamo.{Matrix, Model}

  @doc ~S"""
  Computes alpha variable for Baum-Welch.

  `α_t(i)` is the probability of being in state `S_i` at time `t` after
  observing the first `t` symbols.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_alpha(Model.t, list(Model.symbol)) :: Matrix.t
  def compute_alpha(%Model{a: a, b: b, pi: pi, n: num_states}, observations) do
    b_map = Model.ObsProb.new(b, observations)
    states_range = 0..num_states-1
    obs_len = length(observations)
    obs_range = 1..obs_len-1

    # initialization
    first_row =
      for j <- states_range do
        {{0, j}, Model.Pi.get(pi, j) * Model.ObsProb.get(b_map, {j, 0})}
      end
      |> Enum.into(Matrix.new({obs_len, num_states}))

    # induction
    Enum.reduce(obs_range, first_row, fn(t, partial_alpha) ->
      for j <- states_range do
        rhs = Model.ObsProb.get(b_map, {j, t})
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
  @spec compute_beta(Model.t, list(Model.symbol)) :: Matrix.t
  def compute_beta(%Model{a: a, b: b, n: num_states}, observations) do
    b_map = Model.ObsProb.new(b, observations)
    obs_len = length(observations)

    states_range = 0..num_states-1

    # initialization
    last_row = for j <- states_range do
      {{obs_len-1, j}, 1}
    end |> Enum.into(Matrix.new({obs_len, num_states}))

    # induction
    Enum.reduce((obs_len-2)..0, last_row, fn(t, partial_beta) ->
      for i <- states_range do
        sum = for j <- states_range do
          transition_prob = Model.A.get(a, {i, j})
          emission_prob = Model.ObsProb.get(b_map, {j, t+1})
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
  @spec compute_xi(Model.t, list(Model.symbol)) :: Matrix.t
  def compute_xi(%Model{a: a, b: b, n: num_states} = model, observations) do
    b_map = Model.ObsProb.new(b, observations)
    obs_size = length(observations)

    alpha = compute_alpha(model, observations)
    beta = compute_beta(model, observations)

    states_range = 0..num_states-1

    map_states_2d = fn(fun) ->
      Stream.flat_map(states_range, fn(i) ->
        Enum.map(states_range, fn(j) ->
          fun.({i, j})
        end)
      end)
    end

    Enum.flat_map((0..obs_size-2), fn(t) ->
      denominator = map_states_2d.(fn({i, j}) ->
        curr_alpha = Matrix.get(alpha, {t, i})
        curr_a = Model.A.get(a, {i, j})
        curr_b_map = Model.ObsProb.get(b_map, {j, t+1})
        curr_beta = Matrix.get(beta, {t+1, j})

        curr_alpha * curr_a * curr_b_map * curr_beta
      end)
      |> Enum.sum

      map_states_2d.(fn({i, j}) ->
        curr_alpha = Matrix.get(alpha, {t, i})
        curr_a = Model.A.get(a, {i, j})
        curr_b_map = Model.ObsProb.get(b_map, {j, t+1})
        curr_beta = Matrix.get(beta, {t+1, j})
        numerator = curr_alpha * curr_a * curr_b_map * curr_beta

        {{t, i, j}, numerator/denominator}
      end)
    end)
    |> Enum.into(Matrix.new({obs_size-1, num_states, num_states}))
  end

  @doc ~S"""
  Computes gamma variable for Baum-Welch.

  `γ_t(i)` is the probability of being in state `S_i` at time `t` given the
  full observation sequence.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_gamma(Model.t, list(Model.symbol)) :: Matrix.t
  def compute_gamma(%Model{n: num_states} = model, observations) do
    xi = compute_xi(model, observations)
    obs_size = length(observations)

    Enum.flat_map(0..obs_size-2, fn(t) ->
      Enum.map(0..num_states-1, fn(i) ->
        sum = Enum.map(0..num_states-1, fn(j) ->
          Matrix.get(xi, {t, i, j})
        end)
        |> Enum.sum

        {{t, i}, sum}
      end)
    end)
    |> Enum.into(Matrix.new({obs_size-1, num_states}))
  end
end
