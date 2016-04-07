defmodule Himamo.Model.A do
  @moduledoc ~S"""
  Defines state transition distribution.

  State transition distribution, commonly denoted by `A`, defines the
  probability of the model transitioning to state `S_j`, given its current
  state is `S_i`.

  * `i,j ∈ [0, N)` where `N` is the total number of states.

  ## Examples

      # Distribution with 3 states
      iex> a = Himamo.Model.A.new(3)
      ...> a = Himamo.Model.A.put(a, {1, 2}, 0.1)
      ...> Himamo.Model.A.get(a, {1, 2})
      0.1
  """
  defstruct [:map, :n]

  @type t :: %__MODULE__{map: map, n: pos_integer}
  @type transition :: {Himamo.Model.state, Himamo.Model.state}

  @doc ~S"""
  Creates a representation of state transitions between `n×n` states.
  """
  @spec new(pos_integer) :: Himamo.Model.A.t
  def new(n) when n > 0 do
    %__MODULE__{map: Map.new, n: n}
  end

  @doc ~S"""
  Returns probability of transition to state `S_j` when model is in state
  `S_i`.
  """
  @spec get(Himamo.Model.A.t, transition) :: Himamo.Model.probability
  def get(%__MODULE__{map: map, n: n}, {i, j} = key)
    when i >= 0 and i < n and j >= 0 and j < n,
    do: Map.get(map, key)

  @doc ~S"""
  Updates probability of transition to state `S_j` when model is in state
  `S_i`.
  """
  @spec put(Himamo.Model.A.t, transition, Himamo.Model.probability) :: Himamo.Model.A.t
  def put(%__MODULE__{map: map, n: n} = a, {i, j} = key, val)
    when i >= 0 and i < n and j >= 0 and j < n,
    do: %{a | map: Map.put(map, key, val)}
end
