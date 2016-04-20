defmodule Himamo.ForwardBackwardTest do
  use ExUnit.Case
  alias Himamo.ForwardBackward

  test "compute" do
    alpha = [
      {{0, 0}, 0.21},
      {{0, 1}, 0.24},
      {{1, 0}, 0.1026},
      {{1, 1}, 0.0108},
      {{2, 0}, 0.021384},
      {{2, 1}, 0.004212},
      {{3, 0}, 0.00664848},
      {{3, 1}, 0.00089748},
      {{4, 0}, 0.001439046},
      {{4, 1}, 0.000274914},
      {{5, 0}, 0.00033325506},
      {{5, 1}, 0.00048248784},
      {{6, 0}, 0.00019025763},
      {{6, 1}, 1.8155081e-05},
    ] |> Enum.into(Himamo.Matrix.new({7, 2}))

    assert_in_delta(ForwardBackward.compute(alpha), -8.4759902691381740387, 5.0e-8)
  end
end
