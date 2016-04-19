defmodule Himamo.BaumWelch do
  alias Himamo.BaumWelch.{StepE, StepM}
  @moduledoc ~S"""
  Defines the Baum-Welch algorithm.

  See `Himamo.BaumWelch.StepE` and `Himamo.BaumWelch.StepM` for details on its
  respective expectation and maximization steps.
  """

  @doc ~S"""
  Returns a new model, maximized according to the given observation sequence.
  """
  @spec perform(Himamo.Model.t, Himamo.ObsSeq.t) :: Himamo.Model.t
  def perform(model, obs_seq) do
    stats = StepE.compute(model, obs_seq)
    StepM.reestimate(model, obs_seq, stats)
  end
end
