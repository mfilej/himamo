defmodule Himamo.BaumWelch.StepM do
  @moduledoc ~S"""
  Defines components of the M-step of the Baum-Welch algorithm (Maximization).

  Maximizes the model's parameters.
  """

  alias Himamo.{Matrix, Model, ObsSeq, Logzero}
  alias Himamo.BaumWelch.Stats

  import Logzero

  @doc ~S"""
  Re-estimates the `A` variable.

  Each entry in `A=[a_{i,j}]` is recomputed as: expected number of transitions
  from state `S_i` to state `S_j` divided by the expected number of
  transitions from state `S_j`.

  This is part of the _M_ step of Baum-Welch.
  """
  @spec reestimate_a(Model.t, Himamo.BaumWelch.stats_list) :: Matrix.t
  def reestimate_a(%Model{n: num_states}, stats_list) do
    states_range = 0..num_states-1

    Stream.flat_map(stats_list, fn({
      %ObsSeq{len: obs_len},
      prob_k,
      %Stats{xi: xi, gamma: gamma}
    }) ->

      for i <- states_range, j <- states_range do
        {numerator, denominator} =
          Enum.map(0..obs_len-2, fn (t) ->
            curr_log_xi = Matrix.get(xi, {t, i, j})
            curr_log_gamma = Matrix.get(gamma, {t, i})

            {curr_log_xi, curr_log_gamma}
          end)
          |> Enum.reduce({Logzero.const, Logzero.const}, fn ({numer, denom}, {numer_sum, denom_sum}) ->
            {ext_log_sum(numer_sum, numer), ext_log_sum(denom_sum, denom)}
          end)

        {{i, j}, {ext_log_product(numerator, prob_k), ext_log_product(denominator, prob_k)}}
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
      %Stats{gamma: gamma}
    }) ->

      observations = List.delete_at(observations, -1)

      for j <- states_range, k <- symbols_range do
        {numerator, denominator} =
          Stream.with_index(observations)
          |> Enum.reduce({Logzero.const, Logzero.const}, fn({o, t}, {numer, denom}) ->
            curr_log_gamma = Matrix.get(gamma, {t, j})

            denom = ext_log_sum(denom, curr_log_gamma)

            numer = if o == k do
              ext_log_sum(numer, curr_log_gamma)
            else
              numer
            end

            {numer, denom}
          end)

        {{j, k}, {ext_log_product(numerator, prob_k), ext_log_product(denominator, prob_k)}}
      end
    end)
    |> sum_fraction_parts
    |> fractions_to_numbers
    |> into_matrix({num_states, num_symbols})
  end

  defp sum_fraction_parts(fractions) do
    Enum.reduce(fractions, Map.new, fn({{_i, _j} = key, {numer, denom}}, sums) ->
      {curr_numer, curr_denom} = Map.get(sums, key, {Logzero.const, Logzero.const})
      Map.put(sums, key, {ext_log_sum(numer, curr_numer), ext_log_sum(denom, curr_denom)})
    end)
  end

  defp fractions_to_numbers(fractions) do
    Stream.map(fractions, fn({key, {numerator, denominator}}) ->
      {key, ext_exp(ext_log_product(numerator, -denominator))}
    end)
  end

  defp into_matrix(enumerable, size) do
    Enum.into(enumerable, Matrix.new(size))
  end

  @doc ~S"""
  Re-estimates the `π` variable.
  """
  @spec reestimate_pi(Model.t, Himamo.BaumWelch.stats_list) :: Model.Pi.t
  def reestimate_pi(model, [{obs_seq, _, stats} |_]) do
    %ObsSeq{prob: obs_prob} = obs_seq
    %Stats{alpha: alpha, beta: beta} = stats
    states_range = 0..(model.n - 1)
    row =
      Himamo.BaumWelch.StepE.compute_xi_row(model, alpha, beta, obs_prob, 0)
      |> Enum.into(Matrix.new({1, model.n, model.n}))

    for i <- states_range do
      for j <- states_range do
        Matrix.get(row, {0, i, j})
      end
      |> Logzero.sum_log_values
      |> Logzero.ext_exp
    end
    |> Model.Pi.new
  end
end
