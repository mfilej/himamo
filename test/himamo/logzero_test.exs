defmodule Himamo.LogzeroTest do
  use ExUnit.Case, async: false
  use ExCheck
  alias Himamo.Logzero

  @e 2.718281828459045

  test "ext_exp returns 0 the operand is :logzero" do
    assert Logzero.ext_exp(:logzero) == 0
  end

  property :ext_exp do
    for_all x in real do
      Logzero.ext_exp(x) == :math.exp(x)
    end
  end

  test "ext_log returns :logzero when the operand is 0" do
    assert Logzero.ext_log(0.0) == :logzero
  end

  property :ext_log do
    for_all x in such_that(x in real when x > 0) do
      Logzero.ext_log(x) == :math.log(x)
    end
  end

  test "ext_log_sum when one of the operands is :logzero" do
    assert Logzero.ext_log_sum(1, :logzero) == 1
    assert Logzero.ext_log_sum(:logzero, 1) == 1
  end

  test "ext_log_sum on positive real numbers" do
    import Logzero, only: [ext_log: 1]

    assert verify_property(
      for_all {x, y} in such_that({xx, yy} in {real, real} when xx > 0 and yy > 0) do
        result = Logzero.ext_log_sum(ext_log(x), ext_log(y))
        expected = :math.log(x + y)

        abs(result - expected) < 1.0e-15
      end
    )
  end

  test "ext_log_product when one of the operands is :logzero" do
    assert Logzero.ext_log_product(1, :logzero) == :logzero
    assert Logzero.ext_log_product(:logzero, 1) == :logzero
  end

  test "ext_log_product on positive real numbers" do
    import Logzero, only: [ext_log: 1]

    assert verify_property(
      for_all {x, y} in such_that({xx, yy} in {real, real} when xx > 0 and yy > 0) do
        result = Logzero.ext_log_product(ext_log(x), ext_log(y))
        expected = :math.log(x) + :math.log(y)

        abs(result - expected) < 1.0e-15
      end
    )
  end
end
