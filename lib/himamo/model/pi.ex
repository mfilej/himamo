defmodule Himamo.Model.Pi do
  @moduledoc ~S"""
  Defines initial state distribution.

  Initial state distribution, commonly denoted by `π`, defines the probability
  that the model will start in state `S_i`.

  * `i ∈ [0, N)` where `N` is the total number of states.

  ## Examples

      iex> pi = Himamo.Model.Pi.new([0.3, 0.2, 0.5])
      ...> Himamo.Model.Pi.get(pi, 1)
      0.2
  """
  defstruct [:probs, :n]

  @type t :: %__MODULE__{probs: tuple}
  @type list_of_probabilities :: list(Himamo.Model.probability)

  @doc ~S"""
  Creates a representation of the initial state probabilities.
  """
  @spec new(list_of_probabilities) :: Himamo.Model.Pi.t
  def new(probs) when is_list(probs) do
    probs = List.to_tuple(probs)
    size = tuple_size(probs)
    %__MODULE__{probs: probs, n: size}
  end

  @doc ~S"""
  Returns probability of model starting in state `S_i`.
  """
  @spec get(Himamo.Model.Pi.t, Himamo.Model.state) :: Himamo.Model.probability
  def get(%__MODULE__{probs: probs, n: n}, i)
    when i >= 0 and i < n,
    do: elem(probs, i)
end
