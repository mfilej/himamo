defmodule Himamo.BaumWelch do
  alias Himamo.BaumWelch.{StepE, StepM}
  @moduledoc ~S"""
  Defines the Baum-Welch algorithm.

  See `Himamo.BaumWelch.StepE` and `Himamo.BaumWelch.StepM` for details on its
  respective expectation and maximization steps.
  """

  defmodule Stats do
    @moduledoc ~S"""
    Defines the statistical properties of an HMM.

    See functions in `Himamo.BaumWelch.StepE` for their definitions.
    """

    defstruct [:alpha, :beta, :gamma, :xi]
    @type t :: %__MODULE__{
      alpha: Matrix.t,
      beta: Matrix.t,
      gamma: Matrix.t,
      xi: Matrix.t,
    }
  end

  @doc ~S"""
  Returns a new model, maximized according to the given observation sequence.
  """
  @spec perform(Himamo.Model.t, Himamo.ObsSeq.t) :: Himamo.Model.t
  def perform(model, obs_seq) do
    stats = StepE.compute(model, obs_seq)
    StepM.reestimate(model, obs_seq, stats)
  end
end
