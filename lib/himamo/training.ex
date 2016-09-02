defmodule Himamo.Training do
  @moduledoc """
  Defines the required functions to train a new model by optimizing a given
  model on the given observation sequences.

  ## Example

      iex> # Specifying a model
      ...> a = fn -> # State transition probabilities
      ...>   import Himamo.Model.A, only: [new: 1, put: 3]
      ...>   new(2)
      ...>   |> put({0, 0}, 0.6) |> put({0, 1}, 0.4)
      ...>   |> put({1, 0}, 0.9) |> put({1, 1}, 0.1)
      ...> end.()
      ...> b = fn -> # Symbol emission probabilities
      ...>   import Himamo.Model.B, only: [new: 1, put: 3]
      ...>   new(n: 2, m: 3)
      ...>   |> put({0, 0}, 0.3) |> put({0, 1}, 0.3) |> put({0, 2}, 0.4)
      ...>   |> put({1, 0}, 0.8) |> put({1, 1}, 0.1) |> put({1, 2}, 0.1)
      ...> end.()
      ...> model = %Himamo.Model{
      ...>   n: 2, m: 3,
      ...>   a: a, b: b,
      ...>   pi: Himamo.Model.Pi.new([0.7, 0.3]), # Initial state probabilities
      ...> }
      ...>
      ...> # Two observation sequences, 3 symbols each (they must have equal
      ...> # lengths).
      ...> observation_sequences = [[0, 1, 0], [0, 2, 0]]
      ...>
      ...> # Stop training when probability difference between two models is
      ...> # smaller than this value.
      ...> delta = 1.0e-3
      ...>
      ...> # Training a model based on observation sequences
      ...> {new_model, _stats, _prob} = Himamo.Training.train(model, observation_sequences, delta)
      ...> new_model
      %Himamo.Model{
        m: 3, n: 2,
        a: %Himamo.Matrix{ size: {2, 2},
          map: %{
            {0, 0} => 3.8825474955088077e-4, {0, 1} => 0.9996117452504493,
            {1, 0} => 0.9999999978716732, {1, 1} => 2.1283266130382603e-9,
          },
        },
        b: %Himamo.Matrix{ size: {2, 3},
          map: %{
            {0, 0} => 2.238512492599514e-9, {0, 1} => 0.42857142761206607, {0, 2} => 0.5714285701494215,
            {1, 0} => 0.9999999956546239, {1, 1} => 2.1726880663668223e-9, {1, 2} => 2.1726880663668223e-9,
          },
        },
        pi: %Himamo.Model.Pi{n: 2, probs: {2.6080207784738667e-9, 0.9999999973919793}},
      }
  """

  @doc """
  Train a new model.

  Train a new model by iteratively improving the initial `model` on the given
  `observation_sequences`. Stop iterating when proability difference between
  two successive models is smaller than `epsilon`.
  """
  @spec train(Himamo.Model.t, list(Himamo.ObsSeq.t), float) :: {Himamo.Model.t, list(Himamo.BaumWelch.Stats.t), float}
  def train(model, observation_sequences, epsilon) do
    obs_seqs = Enum.map(observation_sequences, fn(seq) ->
      import Himamo.ObsSeq
      new(seq) |> compute_prob(model.b)
    end)

    perform(model, obs_seqs, epsilon)
  end

  defp perform(initial_model, obs_seqs, epsilon) do
    {initial_stats_list, initial_prob} = compute_stats_list(initial_model, obs_seqs)
    perform({initial_model, initial_stats_list, initial_prob}, obs_seqs, epsilon, 100, 1.0)
  end
  defp perform(result, _, epsilon, _, delta) when delta < epsilon do
    debug "done (delta (#{delta}) < epsilon(#{epsilon})"
    result
  end
  defp perform(result, _, _, iter_left, _) when iter_left < 1 do
    debug "done (last iteration)"
    result
  end
  defp perform({model, stats_list, prob}, obs_seqs, epsilon, iter_left, _) do
    new_model = Himamo.BaumWelch.reestimate_model(model, stats_list)
    {new_stats, new_prob} = compute_stats_list(new_model, obs_seqs)

    delta = abs(prob - new_prob)

    debug "iter_left=#{iter_left}, p=#{new_prob}, d=#{delta}, e=#{epsilon}"

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

  defp debug(message) do
    if Mix.debug? do
      IO.puts(:stderr, message)
    end
  end
end
