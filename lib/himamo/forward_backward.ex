defmodule Himamo.ForwardBackward do
  alias Himamo.{Matrix, Logzero}

  @spec compute(Matrix.t) :: float
  def compute(%Matrix{size: {seq_len, num_states}} = alpha) do
    for i <- 0..num_states-1 do
      Matrix.get(alpha, {seq_len-1, i})
    end
    |> Logzero.sum_log_values
  end
end
