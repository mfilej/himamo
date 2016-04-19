defmodule Himamo.Training do
  def perform(initial_model, obs_seq, epsilon) do
    initial_stats = Himamo.BaumWelch.StepE.compute(initial_model, obs_seq)
    initial_prob = Himamo.ForwardBackward.compute(initial_stats.alpha)
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
    new_model = Himamo.BaumWelch.StepM.reestimate(model, obs_seq, stats)
    new_stats = Himamo.BaumWelch.StepE.compute(new_model, obs_seq)
    new_prob = Himamo.ForwardBackward.compute(new_stats.alpha)
    delta = abs(prob - new_prob)

    IO.puts "iter_left=#{iter_left}, prob=#{new_prob}, delta=#{delta}, epsilon=#{epsilon}, delta-epsilon=#{delta-epsilon}"

    perform({new_model, new_stats, new_prob}, obs_seq, epsilon, iter_left-1, delta)
  end
end
