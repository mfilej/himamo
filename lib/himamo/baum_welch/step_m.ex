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
  @spec reestimate_a(Model.t, Himamo.BaumWelch.stats_list) :: Matrix.t
  def reestimate_a(%Model{a: a, n: num_states}, stats_list) do
    states_range = 0..num_states-1

    Stream.flat_map(stats_list, fn({
      %ObsSeq{len: obs_len, prob: obs_prob},
      prob_k,
      %Stats{alpha: alpha, beta: beta, alpha_times_beta: albe}
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
              Matrix.get(albe, {t, i})

            {numer, denom}
          end)
          |> Enum.reduce({0, 0}, fn ({numer, denom}, {numer_sum, denom_sum}) ->
            {numer_sum + numer, denom_sum + denom}
          end)

        {{i, j}, {numerator * prob_k, denominator * prob_k}}
      end
    end)
    |> sum_fraction_parts
    |> fractions_to_numbers
    |> into_matrix({num_states, num_states})
  end

  @doc ~S"""
  Re-estimates the `B` variable.
  """
  @spec reestimate_b(Model.t, Himamo.BaumWelch.stats_list) :: Matrix.t
  def reestimate_b(%Model{n: num_states, m: num_symbols}, stats_list) do
    states_range = 0..num_states-1
    symbols_range = 0..num_symbols-1

    Enum.flat_map(stats_list, fn({
      %ObsSeq{seq: observations},
      prob_k,
      %Stats{alpha_times_beta: albe}
    }) ->

      observations = List.delete_at(observations, -1)

      for j <- states_range, k <- symbols_range do
        {numerator, denominator} =
          Stream.with_index(observations)
          |> Enum.reduce({0, 0}, fn({o, t}, {numer, denom}) ->
            increment = Matrix.get(albe, {t, j})
            denom = denom + increment

            if o == k, do: numer = numer + increment

            {numer, denom}
          end)

        {{j, k}, {numerator * prob_k, denominator * prob_k}}
      end
    end)
    |> sum_fraction_parts
    |> fractions_to_numbers
    |> into_matrix({num_states, num_symbols})
  end

  defp sum_fraction_parts(fractions) do
    Enum.reduce(fractions, Map.new, fn({{_i, _j} = key, {numer, denom}}, sums) ->
      {curr_numer, curr_denom} = Map.get(sums, key, {0, 0})
      Map.put(sums, key, {numer + curr_numer, denom + curr_denom})
    end)
  end

  defp fractions_to_numbers(fractions) do
    Stream.map(fractions, fn({key, {numerator, denominator}}) ->
      {key, numerator/denominator}
    end)
  end

  defp into_matrix(enumerable, size) do
    Enum.into(enumerable, Matrix.new(size))
  end

  @doc ~S"""
  Re-estimates the `π` variable.
  """
  @spec reestimate_pi(Model.t, Himamo.BaumWelch.stats_list) :: Model.Pi.t
  def reestimate_pi(%Model{n: num_states} = model, [{obs_seq, _, stats} |_]) do
    %ObsSeq{prob: obs_prob} = obs_seq
    %Stats{alpha: alpha, beta: beta} = stats

    row =
      Himamo.BaumWelch.StepE.compute_xi_row(model, alpha, beta, obs_prob, 0)
      |> Enum.into(Matrix.new({1, num_states, num_states}))

    for i <- 0..num_states-1 do
      for j <- 0..num_states-1 do
        Matrix.get(row, {0, i, j})
      end
      |> Enum.sum
    end
    |> Model.Pi.new
  end
end
