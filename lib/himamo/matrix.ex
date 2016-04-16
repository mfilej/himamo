defmodule Himamo.Matrix do
  @moduledoc ~S"""

  Implements the `Collectable` protocol.

  ## Examples

      iex> matrix = Himamo.Matrix.new({2, 3})
      ...> matrix = Himamo.Matrix.put(matrix, {1, 0}, 0.1)
      ...> Himamo.Matrix.get(matrix, {1, 0})
      0.1
  """

  defstruct [:map, :size]

  @type entry :: term
  @type index :: non_neg_integer
  @type dimension :: pos_integer
  @type size :: tuple
  @type t :: %__MODULE__{map: map, size: size}

  @spec new(size) :: t
  def new(size) do
    %__MODULE__{map: Map.new, size: size}
  end

  def put(%__MODULE__{map: map, size: size} = matrix, position, entry) do
    validate_position_within_size!(position, size)
    new_map = Map.put(map, position, entry)
    %__MODULE__{matrix | map: new_map}
  end

  def get(%__MODULE__{map: map}, position) do
    case Map.fetch(map, position) do
      {:ok, entry} -> entry
      :error -> raise(KeyError, key: position, term: map)
    end
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
