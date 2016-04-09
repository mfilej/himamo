defmodule Himamo.GridTest do
  use ExUnit.Case
  alias Himamo.Grid
  doctest Grid

  def grid do
    Grid.new(2,3)
    |> Grid.put({0, 0}, :a)
    |> Grid.put({0, 1}, :b)
    |> Grid.put({0, 2}, :c)
    |> Grid.put({1, 0}, :d)
    |> Grid.put({1, 1}, :e)
    |> Grid.put({1, 2}, :f)
  end

  test "accessing out of bounds coordinates" do
    assert_raise KeyError, fn -> Grid.get(grid, {  0,  3 }) end
    assert_raise KeyError, fn -> Grid.get(grid, {  0, -1 }) end
    assert_raise KeyError, fn -> Grid.get(grid, {  2,  0 }) end
    assert_raise KeyError, fn -> Grid.get(grid, { -1,  0 }) end
  end

  test "updating out of bounds coordinates" do
    assert_raise KeyError, fn -> Grid.put(grid, {  0,  3 }, :x) end
    assert_raise KeyError, fn -> Grid.put(grid, {  0, -1 }, :x) end
    assert_raise KeyError, fn -> Grid.put(grid, {  2,  0 }, :x) end
    assert_raise KeyError, fn -> Grid.put(grid, { -1,  0 }, :x) end
  end
end
