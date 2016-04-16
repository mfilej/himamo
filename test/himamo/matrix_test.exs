defmodule Himamo.MatrixTest do
  use ExUnit.Case
  alias Himamo.Matrix
  doctest Matrix

  test "accessing positions that were not set" do
    matrix = Matrix.new({2, 3})

    assert_raise KeyError, fn ->
      Matrix.get(matrix, {0, 0})
    end

    assert_raise KeyError, fn ->
      Matrix.get(matrix, {4, 4})
    end
  end

  test "inserting into positions out of bounds" do
    matrix = Matrix.new({2, 3, 4})

    assert_raise ArgumentError, fn ->
      Matrix.put(matrix, {2, 0, 0}, 0.1)
    end

    assert_raise ArgumentError, fn ->
      Matrix.put(matrix, {0, 3, 0}, 0.1)
    end

    assert_raise ArgumentError, fn ->
      Matrix.put(matrix, {0, 0, 4}, 0.1)
    end

    assert_raise ArgumentError, fn ->
      Matrix.put(matrix, {-1, 0, 0}, 0.1)
    end

    assert_raise ArgumentError, fn ->
      Matrix.put(matrix, {0, -1, 0}, 0.1)
    end

    assert_raise ArgumentError, fn ->
      Matrix.put(matrix, {0, 0, -1}, 0.1)
    end
  end

  test "comforms to the Collectable protocol" do
    matrix = [
      {{0, 0}, 0.7},
      {{0, 1}, 0.3},
      {{1, 0}, 0.1},
      {{1, 1}, 0.9},
    ] |> Enum.into(Matrix.new({2, 2}))

    assert Matrix.get(matrix, {0, 0}) == 0.7
    assert Matrix.get(matrix, {0, 1}) == 0.3
    assert Matrix.get(matrix, {1, 0}) == 0.1
    assert Matrix.get(matrix, {1, 1}) == 0.9
  end
end
