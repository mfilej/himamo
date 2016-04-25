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

  @type stats_list(obs_seq, stats) :: [{obs_seq, stats}]

  alias Himamo.BaumWelch.{StepE, StepM}

  @doc ~S"""
  Computes variables for Baum-Welch E-step:

    * `α` - `compute_alpha/2`
    * `ß` - `compute_beta/2`
    * `γ` - `compute_gamma/3`
    * `ξ` - `compute_xi/3`
  """
  @spec compute_stats(Himamo.Model.t, Himamo.ObsSeq.t) :: Stats.t
  def compute_stats(model, obs_seq) do
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

  @spec compute_stats_list(Himamo.Model.t, list(Himamo.ObsSeq.t)) :: stats_list(Himamo.ObsSeq.t, Stats.t)
  def compute_stats_list(model, obs_seq_list) do
    for obs_seq <- obs_seq_list, do: {obs_seq, compute_stats(model, obs_seq)}
  end

  @doc ~S"""
  Returns a new HMM with re-estimated parameters `A`, `B`, and `π`.
  """
  @spec reestimate_model(Himamo.Model.t, Himamo.ObsSeq.t, Stats.t) :: Himamo.Model.t
  def reestimate_model(model, obs_seq, stats) do
    import StepM
    %{model |
      a: reestimate_a(model, [obs_seq], stats),
      b: reestimate_b(model, obs_seq, stats),
      pi: reestimate_pi(model, stats),
    }
  end

end
