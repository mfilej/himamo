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
      iex> b = Himamo.Model.B.new(3, 4)
      ...> b = Himamo.Model.B.put(b, {1, 2}, 0.1)
      ...> Himamo.Model.B.get(b, {1, 2})
      0.1
  """
  defstruct [:map, :m, :n]

  @type t :: %__MODULE__{map: map, m: pos_integer, n: pos_integer}
  @type emission :: {Himamo.Model.state, Himamo.Model.symbol}

  @doc ~S"""
  Creates a representation of symbol emission probabilities by state (`m×n`).
  """
  @spec new(pos_integer, pos_integer) :: Himamo.Model.B.t
  def new(m, n) when m > 0 and n > 0 do
    %__MODULE__{map: Map.new, m: m, n: n}
  end

  @doc ~S"""
  Returns probability of emitting symbol `v_k` when model is in state `S_j`.
  """
  @spec get(Himamo.Model.B.t, emission) :: Himamo.Model.probability
  def get(%__MODULE__{map: map, m: m, n: n}, {j, v} = key)
    when j >= 0 and j < n and v >= 0 and v < m,
    do: Map.get(map, key)

  @doc ~S"""
  Updates probability of emitting symbol `v_k` when model is in state `S_j`.
  """
  @spec put(Himamo.Model.B.t, emission, Himamo.Model.probability) :: Himamo.Model.B.t
  def put(%__MODULE__{map: map, m: m, n: n} = b, {j, v} = key, val)
    when j >= 0 and j < n and v >= 0 and v < m,
    do: %{b | map: Map.put(map, key, val)}
end
