defmodule Himamo.BaumWelch do
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

  alias Himamo.BaumWelch.{StepE, StepM}

  @doc ~S"""
  Computes variables for Baum-Welch E-step:

    * `α` - `compute_alpha/2`
    * `ß` - `compute_beta/2`
    * `γ` - `compute_gamma/3`
    * `ξ` - `compute_xi/3`
  """
  @spec compute(Himamo.Model.t, Himamo.ObsSeq.t) :: Stats.t
  def compute(model, obs_seq) do
    import StepE
    alpha = compute_alpha(model, obs_seq)
    beta = compute_beta(model, obs_seq)
    xi = compute_xi(model, obs_seq, alpha: alpha, beta: beta)
    gamma = compute_gamma(model, obs_seq, xi: xi)
    %Stats{
      alpha: alpha,
      beta: beta,
      xi: xi,
      gamma: gamma,
    }
  end

  @doc ~S"""
  Returns a new HMM with re-estimated parameters `A`, `B`, and `π`.
  """
  @spec reestimate(Model.t, ObsSeq.t, Stats.t) :: Model.t
  def reestimate(model, obs_seq, step_e) do
    import StepM
    %{model |
      a: reestimate_a(model, [obs_seq], step_e),
      b: reestimate_b(model, obs_seq, step_e),
      pi: reestimate_pi(model, step_e),
    }
  end

end
