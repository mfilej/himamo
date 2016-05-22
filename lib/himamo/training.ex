defmodule Himamo.Training do
  def train(model, observation_sequences, epsilon) do
    obs_seqs = Enum.map(observation_sequences, fn(seq) ->
      import Himamo.ObsSeq
      new(seq) |> compute_prob(model.b)
    end)

    perform(model, obs_seqs, epsilon)
  end

  def perform(initial_model, obs_seqs, epsilon) do
    {initial_stats_list, initial_prob} = compute_stats_list(initial_model, obs_seqs)
    perform({initial_model, initial_stats_list, initial_prob}, obs_seqs, epsilon, 100, 1.0)
  end
  def perform(result, _, epsilon, _, delta) when delta < epsilon do
    IO.puts "done (delta (#{delta}) < epsilon(#{epsilon})"
    result
  end
  def perform(result, _, _, iter_left, _) when iter_left < 1 do
    IO.puts "done (last iteration)"
    result
  end
  def perform({model, stats_list, prob}, obs_seqs, epsilon, iter_left, _) do
    new_model = Himamo.BaumWelch.reestimate_model(model, stats_list)
    {new_stats, new_prob} = compute_stats_list(new_model, obs_seqs)

    delta = abs(prob - new_prob)

    IO.puts "iter_left=#{iter_left}, p=#{new_prob}, d=#{delta}, e=#{epsilon}"

    perform({new_model, new_stats, new_prob}, obs_seqs, epsilon, iter_left-1, delta)
  end

  defp compute_stats_list(model, obs_seqs) do
    new_stats_list = Himamo.BaumWelch.compute_stats_list(model, obs_seqs)
    new_prob = new_stats_list |> extract_prob_k |> multiply_probabilities

    {new_stats_list, new_prob}
  end

  defp extract_prob_k(stats) do
    Stream.map(stats, fn({_, prob_k, _}) -> prob_k end)
  end

  defp multiply_probabilities(probabilities) do
    Enum.reduce(probabilities, fn(prob, product) ->
      Himamo.Logzero.ext_log_product(product, prob)
    end)
  end
end
