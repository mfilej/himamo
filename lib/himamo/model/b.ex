defmodule Himamo.Model.B do
  @moduledoc ~S"""
  Defines symbol emission probability distribution.

  Symbol emission probability distribution, commonly denoted by `B`, defines
  the probability of the model emitting the symbol `v_k` when in state `S_j`.

  * `0 ≤ j < N` where `N` is the number of states.
  * `0 ≤ k < M` where `M` is the number of distinct observation symbols, i.e.
    the alphabet size.

  ## Examples

      # Distribution with 3 states and 4 symbols
      iex> b = Himamo.Model.B.new(n: 3, m: 4)
      ...> b = Himamo.Model.B.put(b, {1, 2}, 0.1)
      ...> Himamo.Model.B.get(b, {1, 2})
      0.1
  """
  @type emission :: {Himamo.Model.state, Himamo.Model.symbol}
  @type t :: Himamo.Grid

  @doc ~S"""
  Creates a representation of symbol emission probabilities by state (`m×n`).
  """
  @spec new([m: pos_integer, n: pos_integer]) :: t
  def new(kwargs) do
    m = Keyword.fetch!(kwargs, :m)
    n = Keyword.fetch!(kwargs, :n)
    Himamo.Grid.new(m, n)
  end

  @doc ~S"""
  Returns probability of emitting symbol `v_k` when model is in state `S_j`.
  """
  @spec get(t, emission) :: Himamo.Model.probability
  def get(b, {j, v}) do
    Himamo.Grid.get(b, {v, j})
  end

  @doc ~S"""
  Updates probability of emitting symbol `v_k` when model is in state `S_j`.
  """
  @spec put(t, emission, Himamo.Model.probability) :: t
  def put(b, {j, v} ,val) do
    Himamo.Grid.put(b, {v, j}, val)
  end

  @doc ~S"""
  Returns total number of states.
  """
  @spec num_states(t) :: pos_integer
  def num_states(%Himamo.Grid{height: num}), do: num
end
