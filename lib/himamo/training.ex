defmodule Himamo.Training do
  def perform(initial_model, obs_seq, epsilon) do
    {initial_stats, initial_prob} = compute_stats(initial_model, obs_seq)
    perform({initial_model, initial_stats, initial_prob}, obs_seq, epsilon, 100, 1.0)
  end
  def perform(result, _, epsilon, _, delta) when delta < epsilon do
    IO.puts "done (delta (#{delta}) < epsilon(#{epsilon})"
    result
  end

  def perform(result, _, _, iter_left, _) when iter_left < 1 do
    IO.puts "done (last iteration)"
    result
  end

  def perform({model, stats, prob}, obs_seq, epsilon, iter_left, _) do
    new_model = Himamo.BaumWelch.reestimate(model, obs_seq, stats)
    {new_stats, new_prob} = compute_stats(new_model, obs_seq)

    delta = abs(prob - new_prob)

    IO.puts "iter_left=#{iter_left}, p=#{new_prob}, d=#{delta}, e=#{epsilon}"

    perform({new_model, new_stats, new_prob}, obs_seq, epsilon, iter_left-1, delta)
  end

  defp compute_stats(model, obs_seq) do
    new_stats = Himamo.BaumWelch.compute_stats(model, obs_seq)
    new_prob = Himamo.ForwardBackward.compute(new_stats.alpha)
    {new_stats, new_prob}
  end
end
