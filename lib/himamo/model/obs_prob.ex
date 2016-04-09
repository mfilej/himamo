defmodule Himamo.Model.ObsProb do
  @moduledoc ~S"""
  An intermediate representation of an observation sequence.

  In this intermediate representation the observed symbols are replaced with
  their respective probabilities of occurrence for each possible state of the
  model, as given by `B`.

  Internal representation uses a tuple of tuples of size `N×T` where:

  * `N` - number of states in the model
  * `T` - length of observation sequence

  This intermediate representation is used by the Baum-Welch algorithm.
  """

  @type occurrence :: {Himamo.Model.state, Himamo.Model.symbol}
  @type t :: Himamo.Grid.t

  @doc ~S"""
  Creates an `ObsProb` where its `states` are computed (using `b_map/2`) based
  on the given `B` and sequence of observed symbols.
  """
  @spec new(Himamo.Model.B.t, list(Himamo.Model.symbol)) :: t
  def new(b, observations) when is_list(observations) do
    num_obs = length(observations)
    num_states = Himamo.Model.B.num_states(b)
    states = b_map(b, observations)
    Himamo.Grid.new(num_obs, num_states, states)
  end

  @doc ~S"""
  Returns probability of occurrence `t` when in state `j`.

  Argument `key` is a `{j, t}` tuple.
  """
  @spec get(t, occurrence) :: Himamo.Model.probability
  def get(grid, key) do
    Himamo.Grid.get(grid, key)
  end

  defp b_map(b, observations) when is_list(observations) do
    observations = List.to_tuple(observations)
    obs_size = tuple_size(observations)
    num_states = Himamo.Model.B.num_states(b)

    Stream.flat_map(0..num_states-1, fn j ->
      Stream.map(0..obs_size-1, fn t ->
        key = {j, t}
        val = Himamo.Model.B.get(b, {j, elem(observations, t)})
        {key, val}
      end)
    end)
    |> Enum.into(Map.new)
  end
end
