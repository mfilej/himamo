ExUnit.start()

defmodule TestHelpers.AllInDelta do
  import ExUnit.Assertions, only: [assert_in_delta: 3, assert_in_delta: 4]

  def assert_all_in_delta(actual, expected, delta \\ 1.0e-10)
  def assert_all_in_delta(actual, expected, delta)
    when tuple_size(actual) == length(expected) do
    actual = Tuple.to_list(actual)

    Enum.zip(actual, expected)
    |>Enum.each(fn {{actual_p1, actual_p2}, {expected_p1, expected_p2}} ->
      assert_in_delta(actual_p1, expected_p1, delta)
      assert_in_delta(actual_p2, expected_p2, delta)
    end)
  end
  def assert_all_in_delta(%Himamo.Matrix{map: map} = _actual, expected, delta)
    when map_size(map) == map_size(expected) do
    Enum.each(map, fn({position, entry}) ->
      expected_value = Map.fetch!(expected, position)
      assert_in_delta(entry, expected_value, delta)
    end)
  end
end
