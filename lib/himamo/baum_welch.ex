defmodule Himamo.BaumWelch do
  alias Himamo.{Matrix, Model}

  @doc ~S"""
  Computes alpha variable for Baum-Welch.

  `α_t(i)` is the probability of being in state `S_i` at time `t` after
  observing the first `t` symbols.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_alpha(Model.t, list(Model.symbol)) :: tuple
  def compute_alpha(%Model{a: a, b: b, pi: pi, n: num_states}, observations) do
    b_map = Model.ObsProb.new(b, observations)
    observations = List.to_tuple(observations)
    obs_size = tuple_size(observations)

    states_range = 0..num_states-1

    # initialization
    first_row = Enum.map(states_range, fn j ->
      Model.Pi.get(pi, j) * Model.ObsProb.get(b_map, {j, 0})
    end)
    |> List.to_tuple

    # induction
    {result, _} = Enum.map_reduce((1..obs_size-1), first_row, fn(t, prev_row) ->
      new_row = Enum.map(states_range, fn j ->
        sum = Stream.map(states_range, fn i ->
          elem(prev_row, i) * Model.A.get(a, {i, j})
        end)
        |> Enum.sum

        rhs = Model.ObsProb.get(b_map, {j, t})

        sum * rhs
      end)
      |> List.to_tuple

      {new_row, new_row}
    end)

    [first_row | result] |> List.to_tuple
  end

  @doc ~S"""
  Computes beta variable for Baum-Welch.

  `ß_t(i)` is the probability of being in state `S_i` at time `t` and
  observing the partial sequence from `t+1` to the end.

  Returns tuple of tuples (size `T×N`) where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_beta(Model.t, list(Model.symbol)) :: tuple
  def compute_beta(%Model{a: a, b: b, n: num_states}, observations) do
    b_map = Model.ObsProb.new(b, observations)
    obs_size = length(observations)

    states_range = 0..num_states-1

    # initialization
    last_row = Tuple.duplicate(1, num_states)

    # induction
    Enum.reduce((obs_size-2)..0, [last_row], fn(t, [prev_row|_] = rows) ->
      new_row = Enum.map(states_range, fn i ->
        Stream.map(states_range, fn j ->
          transition_prob = Model.A.get(a, {i, j})
          emission_prob = Model.ObsProb.get(b_map, {j, t+1})
          prev_beta = elem(prev_row, j)
          transition_prob * emission_prob * prev_beta
        end)
        |> Enum.sum
      end)
      |> List.to_tuple

      [new_row | rows]
    end)
    |> List.to_tuple
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
        curr_alpha = alpha |> elem(t) |> elem(i)
        curr_a = Model.A.get(a, {i, j})
        curr_b_map = Model.ObsProb.get(b_map, {j, t+1})
        curr_beta = beta |> elem(t+1) |> elem(j)

        curr_alpha * curr_a * curr_b_map * curr_beta
      end)
      |> Enum.sum

      map_states_2d.(fn({i, j}) ->
        curr_alpha = alpha |> elem(t) |> elem(i)
        curr_a = Model.A.get(a, {i, j})
        curr_b_map = Model.ObsProb.get(b_map, {j, t+1})
        curr_beta = beta |> elem(t+1) |> elem(j)
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
  @spec reestimate_a(non_neg_integer, non_neg_integer, [xi: Matrix.t, gamma: Matrix.t]) :: Matrix.t
  def reestimate_a(num_states, obs_len, xi: xi, gamma: gamma) do
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
  @spec reestimate_b(Model.t, list(Model.symbol), [gamma: Matrix.t]) :: Matrix.t
  def reestimate_b(%Model{n: num_states, m: num_symbols}, observations, gamma: gamma) do
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
end
