defmodule Himamo.Training do
  def perform(initial_model, obs_seq, epsilon) do
    {initial_stats_list, initial_prob} = compute_stats_list(initial_model, obs_seq)
    perform({initial_model, initial_stats_list, initial_prob}, obs_seq, epsilon, 100, 1.0)
  end
  def perform(result, _, epsilon, _, delta) when delta < epsilon do
    IO.puts "done (delta (#{delta}) < epsilon(#{epsilon})"
    result
  end

  def perform(result, _, _, iter_left, _) when iter_left < 1 do
    IO.puts "done (last iteration)"
    result
  end

  def perform({model, stats_list, prob}, obs_seq, epsilon, iter_left, _) do
    new_model = Himamo.BaumWelch.reestimate_model(model, stats_list)
    {new_stats, new_prob} = compute_stats_list(new_model, obs_seq)

    delta = abs(prob - new_prob)

    IO.puts "iter_left=#{iter_left}, p=#{new_prob}, d=#{delta}, e=#{epsilon}"

    perform({new_model, new_stats, new_prob}, obs_seq, epsilon, iter_left-1, delta)
  end

  defp compute_stats_list(model, obs_seq) do
    new_stats_list = Himamo.BaumWelch.compute_stats_list(model, [obs_seq])
    new_prob =
      Stream.map(new_stats_list, fn({_, prob_k, _}) -> prob_k end)
      |> Enum.reduce(1, fn(prob, product) -> product * prob end)

    {new_stats_list, new_prob}
  end
end
