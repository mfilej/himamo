defmodule Himamo.Logzero do
  @type ext_float :: float | :logzero

  @doc ~S"""
  Returns the `:logzero` constant.
  """
  @spec const() :: :logzero
  def const, do: :logzero

  @doc ~S"""
  Extended exponential function.

  Standard exponential function `e^x`, extended to handle the input `0`:

    * `e^LOGZERO = 0`
  """
  @spec ext_exp(ext_float) :: float
  def ext_exp(:logzero), do: 0.0
  def ext_exp(x), do: :math.exp(x)

  @doc ~S"""
  Extended (natural) logarithm function.

  Standard natural logarithm function `ln(x)`, extended to handle the input
  `0`:

    * `log(0) = LOGZERO`

  Function is named `log` instead of `ln` to be consistent with erlang's
  `:math.log`.
  """
  @spec ext_log(float) :: ext_float
  def ext_log(0.0), do: :logzero
  def ext_log(x) when is_float(x), do: :math.log(x)

  @doc ~S"""
  Extended (natural) logarithm sum function.

  Computes the extended natural logarithm of the sum of `x` and `y` (inputs
  are given as extended logarithms):

    * `ext_log_sum(ext_log(x), ext_log(y)) = ext_log(x + y)`
    * `ext_log_sum(LOGZERO, ext_log(y)) = ext_log(y)`
    * `ext_log_sum(ext_log(x), LOGZERO) = ext_log(x)`
  """
  @spec ext_log_sum(ext_float, ext_float) :: ext_float
  def ext_log_sum(log_x, :logzero), do: log_x
  def ext_log_sum(:logzero, log_y), do: log_y
  def ext_log_sum(log_x, log_y) do
    if log_x > log_y do
      log_x + ext_log(1 + :math.exp(log_y - log_x))
    else
      log_y + ext_log(1 + :math.exp(log_x - log_y))
    end
  end

  @doc ~S"""
  Extended (natural) logarithm product function.

  Computes the extended natural logarithm of the product of x and y:

    * `ext_log_product(ext_log(x), ext_log(y)) = ext_log(x) + ext_log(y)`
    * `ext_log_product(LOGZERO, ext_log(y)) = LOGZERO`
    * `ext_log_product(ext_log(x), LOGZERO) = LOGZERO`
  """
  @spec ext_log_product(ext_float, ext_float) :: ext_float
  def ext_log_product(_log_x, :logzero), do: :logzero
  def ext_log_product(:logzero, _log_y), do: :logzero
  def ext_log_product(log_x, log_y) when is_float(log_x) and is_float(log_y) do
    log_x + log_y
  end

  @doc false
  def sum_log_values(enum) do
    Enum.reduce(enum, const, fn element, sum ->
      ext_log_sum(sum, element)
    end)
  end
end
