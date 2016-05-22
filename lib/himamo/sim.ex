defmodule Himamo.Sim do
  defstruct [:model, :state]

  def simulate(model, len) do
    initial_state = pick_initial_state(model.pi)
    sim = %__MODULE__{model: model, state: initial_state}
    generate(sim, len)
  end

  defp generate(sim, len) do
    {emissions, _sim} =
      Enum.map_reduce(1..len, sim, fn _i, sim ->
        emission = emission_probs(sim) |> pick_random
        new_state = transition_probs(sim) |> pick_random
        sim = %{sim | state: new_state}
        {emission, sim}
      end)
    emissions
  end

  defp pick_initial_state(%Himamo.Model.Pi{probs: probs}) do
    Tuple.to_list(probs) |> Enum.with_index |> pick_random
  end

  defp emission_probs(%__MODULE__{model: model, state: state}) do
    for k <- 0..(model.m - 1) do
      symbol_prob = Himamo.Model.B.get(model.b, {state, k})
      {symbol_prob, k}
    end
  end

  defp transition_probs(%__MODULE__{model: model, state: state}) do
    for j <- 0..(model.n - 1) do
      state_prob = Himamo.Model.A.get(model.a, {state, j})
      {state_prob, j}
    end
  end

  defp pick_random(state_probs, rand_val \\ :random.uniform) do
    result = Enum.reduce_while(state_probs, 0.0, fn {prob, index}, current_val ->
      current_val = current_val + prob

      if rand_val > current_val do
        {:cont, current_val}
      else
        {:halt, {:new_state, index}}
      end
    end)

    case result do
      {:new_state, index} -> index
      _ -> raise("Unable to pick new state")
    end
  end

  @on_load :seed_random
  @doc false
  def seed_random do
    :random.seed(:os.timestamp())
    :ok
  end
end
