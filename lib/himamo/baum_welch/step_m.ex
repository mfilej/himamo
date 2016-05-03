defmodule Himamo.BaumWelch.StepM do
  @moduledoc ~S"""
  Defines components of the M-step of the Baum-Welch algorithm (Maximization).

  Maximizes the model's parameters.
  """

  alias Himamo.{Matrix, Model, ObsSeq}
  alias Himamo.BaumWelch.Stats

  @doc ~S"""
  Re-estimates the `A` variable.

  Each entry in `A=[a_{i,j}]` is recomputed as: expected number of transitions
  from state `S_i` to state `S_j` divided by the expected number of
  transitions from state `S_j`.

  This is part of the _M_ step of Baum-Welch.
  """
  @spec reestimate_a(Model.t, list(ObsSeq.t), Stats.t) :: Matrix.t
  def reestimate_a(%Model{a: a, n: num_states}, obs_seq_list, %Stats{alpha: alpha, beta: beta}) do
    states_range = 0..num_states-1

    for i <- states_range, j <- states_range do
      {numerator, denominator} =
        Stream.flat_map(obs_seq_list, fn(%ObsSeq{len: obs_len, prob: obs_prob}) ->
          Enum.map(0..obs_len-2, fn (t) ->
            numer =
              Matrix.get(alpha, {t, i}) *
              Model.A.get(a, {i, j}) *
              Model.ObsProb.get(obs_prob, {j, t+1}) *
              Matrix.get(beta, {t+1, j})

            denom =
              Matrix.get(alpha, {t, i}) * Matrix.get(beta, {t, i})

            {numer, denom}
          end)
        end)
        |> Enum.reduce({0, 0}, fn ({numer, denom}, {numer_sum, denom_sum}) ->
          {numer_sum + numer, denom_sum + denom}
        end)

      {{i, j}, numerator/denominator}
    end
    |> Enum.into(Matrix.new({num_states, num_states}))
  end

  @spec reestimate_a(Model.t, Himamo.BaumWelch.stats_list) :: Matrix.t
  def reestimate_a(%Model{a: a, n: num_states}, stats_list) do
    states_range = 0..num_states-1

    Stream.flat_map(stats_list, fn({
      %ObsSeq{len: obs_len, prob: obs_prob},
      prob_k,
      %Stats{alpha: alpha, beta: beta}
    }) ->

      for i <- states_range, j <- states_range do
        {numerator, denominator} =
          Enum.map(0..obs_len-2, fn (t) ->
            numer =
              Matrix.get(alpha, {t, i}) *
              Model.A.get(a, {i, j}) *
              Model.ObsProb.get(obs_prob, {j, t+1}) *
              Matrix.get(beta, {t+1, j})
            denom =
              Matrix.get(alpha, {t, i}) * Matrix.get(beta, {t, i})

            {numer, denom}
          end)
          |> Enum.reduce({0, 0}, fn ({numer, denom}, {numer_sum, denom_sum}) ->
            {numer_sum + numer, denom_sum + denom}
          end)

        {{i, j}, {numerator * prob_k, denominator * prob_k}}
      end
    end)
    |> Enum.reduce(Map.new, fn({{_i, _j} = key, {numer, denom}}, sums) ->
      {curr_numer, curr_denom} = Map.get(sums, key, {0, 0})
      Map.put(sums, key, {numer + curr_numer, denom + curr_denom})
    end)
    |> Stream.map(fn({key, {numerator, denominator}}) ->
      {key, numerator/denominator}
    end)
    |> Enum.into(Matrix.new({num_states, num_states}))
  end

  @doc ~S"""
  Re-estimates the `B` variable.
  """
  @spec reestimate_b(Model.t, ObsSeq.t, Stats.t) :: Matrix.t
  def reestimate_b(%Model{n: num_states, m: num_symbols}, %ObsSeq{seq: observations}, %Stats{gamma: gamma}) do
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

  @spec reestimate_b(Model.t, Himamo.BaumWelch.stats_list) :: Matrix.t
  def reestimate_b(%Model{n: num_states, m: num_symbols}, stats_list) do
    states_range = 0..num_states-1
    symbols_range = 0..num_symbols-1

    Enum.flat_map(stats_list, fn({
      %ObsSeq{seq: observations},
      prob_k,
      %Stats{alpha: alpha, beta: beta}
    }) ->

      observations = List.delete_at(observations, -1)

      for j <- states_range, k <- symbols_range do
        {numerator, denominator} =
          Stream.with_index(observations)
          |> Enum.reduce({0, 0}, fn({o, t}, {numer, denom}) ->
            increment = Matrix.get(alpha, {t, j}) * Matrix.get(beta, {t, j})
            denom = denom + increment

            if o == k, do: numer = numer + increment

            {numer, denom}
          end)

        {{j, k}, {numerator, denominator}}
      end
    end)
    |> Enum.reduce(Map.new, fn({{_i, _j} = key, {numer, denom}}, sums) ->
      {curr_numer, curr_denom} = Map.get(sums, key, {0, 0})
      Map.put(sums, key, {numer + curr_numer, denom + curr_denom})
    end)
    |> Stream.map(fn({key, {numerator, denominator}}) ->
      {key, numerator/denominator}
    end)
    |> Enum.into(Matrix.new({num_states, num_symbols}))
  end

  @doc ~S"""
  Re-estimates the `π` variable.
  """
  @spec reestimate_pi(Model.t, Stats.t) :: Model.Pi.t
  def reestimate_pi(%Model{n: num_states}, %Stats{gamma: gamma}) do
    for i <- 0..num_states-1 do
      Matrix.get(gamma, {0, i})
    end
    |> Model.Pi.new
  end
end
