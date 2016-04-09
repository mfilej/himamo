defmodule Himamo.BaumWelch do
  alias Himamo.Model

  @doc ~S"""
  Compute alpha variable (`α`).

  `α_{t,i}` is the probability of being in state `i` after observing the first
  `t` symbols.

  Returns grid of size `T×N` where:
  * `T` - length of observation sequence
  * `N` - number of states in the model
  """
  @spec compute_alpha(Himamo.Model.t, list(Himamo.Model.symbol)) :: tuple
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
    Enum.reduce((1..obs_size-1), [first_row], fn(t, [prev_row|_] = rows) ->
      new_row = Enum.map(states_range, fn j ->
        sum = Stream.map(states_range, fn i ->
          elem(prev_row, i) * Model.A.get(a, {i, j})
        end)
        |> Enum.sum

        rhs = Model.ObsProb.get(b_map, {j, t})

        sum * rhs
      end)
      |> List.to_tuple

      [new_row | rows]
    end)
    |> Enum.reverse
    |> List.to_tuple
  end
end
