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

    defstruct [:alpha, :beta, :gamma, :xi, :alpha_times_beta]
    @type t :: %__MODULE__{
      alpha: Himamo.Matrix.t,
      beta: Himamo.Matrix.t,
      gamma: Himamo.Matrix.t,
      xi: Himamo.Matrix.t,
      alpha_times_beta: Himamo.Matrix.t,
    }
  end

  @type stats_list :: [{Himamo.ObsSeq.t, Himamo.Model.probability, Stats.t}]

  alias Himamo.BaumWelch.{StepE, StepM}

  @doc ~S"""
  Computes variables for Baum-Welch E-step.
  """
  @spec compute_stats(Himamo.Model.t, Himamo.ObsSeq.t) :: Stats.t
  def compute_stats(model, obs_seq) do
    import StepE
    alpha = compute_alpha(model, obs_seq)
    beta = compute_beta(model, obs_seq)
    xi = compute_xi(model, obs_seq, alpha: alpha, beta: beta)
    gamma = compute_gamma(model, obs_seq, xi: xi)
    alpha_times_beta = compute_alpha_times_beta(alpha, beta)
    %Stats{
      alpha: alpha,
      beta: beta,
      gamma: gamma,
      xi: xi,
      alpha_times_beta: alpha_times_beta,
    }
  end

  @spec compute_stats_list(Himamo.Model.t, list(Himamo.ObsSeq.t)) :: stats_list
  def compute_stats_list(model, obs_seq_list) do
    for obs_seq <- obs_seq_list do
      stats = compute_stats(model, obs_seq)
      prob = Himamo.ForwardBackward.compute(stats.alpha)
      {obs_seq, prob, stats}
    end
  end

  @doc ~S"""
  Returns a new HMM with re-estimated parameters `A`, `B`, and `π`.
  """
  @spec reestimate_model(Himamo.Model.t, Himamo.BaumWelch.stats_list) :: Himamo.Model.t
  def reestimate_model(model, stats_list) do
    import StepM
    %{model |
      a: reestimate_a(model, stats_list),
      b: reestimate_b(model, stats_list),
      pi: reestimate_pi(model, stats_list),
    }
  end
end
