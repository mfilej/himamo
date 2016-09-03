defmodule Himamo.Matrix do
  @moduledoc ~S"""
  Defines a two- or three-dimensional matrix.

  ## Examples

      iex> matrix = Himamo.Matrix.new({2, 3})
      ...> matrix = Himamo.Matrix.put(matrix, {1, 0}, 0.1)
      ...> Himamo.Matrix.get(matrix, {1, 0})
      0.1


  Implements the `Collectable` protocol.

  ## Examples

      iex> matrix = [{{0, 1}, 0.1}] |> Enum.into(Himamo.Matrix.new({2, 2}))
      ...> Himamo.Matrix.get(matrix, {0, 1})
      0.1

  """

  defstruct [:map, :size]

  @type entry :: term
  @type index :: non_neg_integer
  @type position :: {index, index} | {index, index, index}
  @type t :: %__MODULE__{map: map, size: tuple}

  @doc ~S"""
  Creates a `Matrix`.

  The `size` argument is a tuple that specifies the dimensions. For example,
  `new({5, 3})` creates a 5×3 two-dimensional matrix and `new({7, 5, 4})`
  creates a 7×5×4 three-dimensional matrix.
  """
  @spec new(tuple) :: t
  def new(size) do
    %__MODULE__{map: Map.new, size: size}
  end

  @doc ~S"""
  Returns entry at `position`.

  `position` is a tuple of indices.

  Raises `KeyError` when accessing a position that was not previously set.
  """
  @spec get(t, position) :: entry
  def get(%__MODULE__{map: map}, position) do
    case Map.fetch(map, position) do
      {:ok, entry} -> entry
      :error -> raise(KeyError, key: position, term: map)
    end
  end

  @doc ~S"""
  Updates entry at `position`.

  `position` is a tuple of indices.

  Raises `ArgumentError` when updating a position that is out of bounds of the
  matrix.
  """
  @spec put(t, position, entry) :: t
  def put(%__MODULE__{map: map, size: size} = matrix, position, entry) do
    validate_position_within_size!(position, size)
    new_map = Map.put(map, position, entry)
    %__MODULE__{size: size, map: new_map}
  end

  defp validate_position_within_size!(position, size) do
    case validate_position_within_size(position, size) do
      :ok -> :ok
      error -> raise(ArgumentError, error)
    end
  end

  defp validate_position_within_size({x, y, z}, {width, height, depth}) do
    cond do
      x < 0 || x >= width ->
        "x position out of bounds (got #{x}, expected 0..#{width-1})"
      y < 0 || y >= height ->
        "y position out of bounds (got #{y}, expected 0..#{height-1})"
      z < 0 || z >= depth ->
        "z position out of bounds (got #{z}, expected 0..#{depth-1})"
      true -> :ok
    end
  end

  defp validate_position_within_size({x, y}, {width, height}) do
    validate_position_within_size({x, y, 0}, {width, height, 1})
  end
end

defimpl Collectable, for: Himamo.Matrix do
  alias Himamo.Matrix

  def into(original) do
    {
      original,
      fn
        matrix, {:cont, {pos, entry}} -> Matrix.put(matrix, pos, entry)
        matrix, :done -> matrix
        _, :halt -> :ok
      end
    }
  end
end
