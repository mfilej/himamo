defmodule Himamo.Grid do
  @moduledoc ~S"""
  Defines a two-dimensional grid.

  A matrix-like data structure (or 2D-array if you will), except without any
  actual support for matrix operations.

  ## Examples

      iex> grid = Himamo.Grid.new(2, 5)
      ...> grid = Himamo.Grid.put(grid, {1, 3}, 0.1)
      ...> Himamo.Grid.get(grid, {1, 3})
      0.1
  """
  defstruct [:grid, :width, :height]

  @type coordinate :: pos_integer
  @type key :: {coordinate, coordinate}
  @type value :: any
  @type t :: %__MODULE__{grid: map, width: coordinate, height: coordinate}

  @doc ~S"""
  Creates a grid of size `width×height`.
  """
  @spec new(pos_integer, pos_integer) :: Himamo.Grid.t
  @spec new(pos_integer, pos_integer, map) :: Himamo.Grid.t
  def new(width, height) do
    %__MODULE__{grid: Map.new, width: width, height: height}
  end
  def new(width, height, grid) do
    %__MODULE__{grid: grid, width: width, height: height}
  end

  @doc ~S"""
  Returns value stored at coordinates `{x,y}`.
  """
  @spec get(Himamo.Grid.t, key) :: value
  def get(%__MODULE__{grid: map}, key) do
    Map.fetch!(map, key)
  end

  @doc ~S"""
  Returns new grid with updated value at coordinates `{x,y}`.
  """
  @spec put(Himamo.Grid.t, key, value) :: Himamo.Grid.t
  def put(%__MODULE__{grid: map, width: width, height: height} = grid, {x, y} = key, val)
  when x >= 0 and x < width and y >= 0 and y < height do
    %{grid | grid: Map.put(map, key, val)}
  end
  def put(%__MODULE__{} = term, {_, _} = key, _) do
    raise(KeyError, key: key, term: term)
  end
end
