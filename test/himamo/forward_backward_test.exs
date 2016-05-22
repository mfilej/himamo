defmodule Himamo.ForwardBackwardTest do
  use ExUnit.Case
  alias Himamo.ForwardBackward

  test "compute" do
    alpha = [
      {{0, 0}, :math.log(0.21000000000)},
      {{0, 1}, :math.log(0.24000000000)},
      {{1, 0}, :math.log(0.10260000000)},
      {{1, 1}, :math.log(0.01080000000)},
      {{2, 0}, :math.log(0.02138400000)},
      {{2, 1}, :math.log(0.00421200000)},
      {{3, 0}, :math.log(0.00664848000)},
      {{3, 1}, :math.log(0.00089748000)},
      {{4, 0}, :math.log(0.00143904600)},
      {{4, 1}, :math.log(0.00027491400)},
      {{5, 0}, :math.log(0.00033325506)},
      {{5, 1}, :math.log(0.00048248784)},
      {{6, 0}, :math.log(0.00019025763)},
      {{6, 1}, :math.log(1.8155081e-05)},
    ] |> Enum.into(Himamo.Matrix.new({7, 2}))

    assert_in_delta(ForwardBackward.compute(alpha), -8.4759902691381740387, 5.0e-8)
  end
end
