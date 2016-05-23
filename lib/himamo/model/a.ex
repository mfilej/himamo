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
  @type t :: Himamo.Matrix.t
  @type transition :: {Himamo.Model.state, Himamo.Model.state}

  @doc ~S"""
  Creates a representation of state transitions between `n×n` states.
  """
  @spec new(pos_integer) :: t
  def new(n) when n > 0 do
    Himamo.Matrix.new({n, n})
  end

  @doc ~S"""
  Returns probability of transition to state `S_j` when model is in state
  `S_i`.
  """
  @spec get(t, transition) :: Himamo.Model.probability
  def get(a, {i, j}) do
    Himamo.Matrix.get(a, {j, i})
  end

  @doc ~S"""
  Updates probability of transition to state `S_j` when model is in state
  `S_i`.
  """
  @spec put(t, transition, Himamo.Model.probability) :: t
  def put(a, {i, j}, val) do
    Himamo.Matrix.put(a, {j, i}, val)
  end
end
