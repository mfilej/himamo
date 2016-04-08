defmodule Himamo.Model.ObsProb do
  @moduledoc ~S"""
  An intermediate representation of an observation sequence.

  In this intermediate representation the observed symbols are replaced with
  their respective probabilities of occurence for each possible state of the
  model, as given by `B`.

  Internal representation uses a tuple of tuples of size `N×T` where

  * `N` - number of states in the model
  * `T` - observation sequence

  This intermediate representation is used by the Baum-Welch algorithm.
  """

  defstruct [:states]

  @type t :: %__MODULE__{states: tuple}

  alias Himamo.Model.B

  @doc ~S"""
  Creates an `ObsProb` where its `states` are computed (using `b_map/2`) based
  on the given `B` and sequence of observed symbols.
  """
  @spec new(B.t, list(Himamo.Model.symbol)) :: t
  def new(b, observations) when is_list(observations) do
    states = b_map(b, observations)
    %__MODULE__{states: states}
  end

  @doc ~S"""
  Translates a list of observations into a list of their occurence
  probabilities for each model state.
  """
  @spec b_map(B.t, list(Himamo.Model.symbol)) :: tuple
  def b_map(%B{n: num_states} = b, observations) when is_list(observations) do
    observations = List.to_tuple(observations)
    obs_size = tuple_size(observations)

    Stream.map(0..num_states-1, fn j ->
      Stream.map(0..obs_size-1, fn t ->
        B.get(b, {j, elem(observations, t)})
      end)
      |> Enum.to_list
      |> List.to_tuple
    end)
    |> Enum.to_list
    |> List.to_tuple
  end
end
