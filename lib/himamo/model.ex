defmodule Himamo.Model do
  @moduledoc ~S"""
  Defines a Hidden Markov Model.

  An HMM, often denoted by ` λ`, is characterized by the following:
  * `N` - number of states in the model
  * `M` - number of distinct observation symbols, i.e. the discrete alphabet
    size
  * `A` - state transition probability distribution
  * `B` - observation symbol probability distribution
  * `π` - initial state distribution
  """
  defstruct [:n, :m, :a, :b, :pi]

  @type probability :: float
  @type state :: non_neg_integer
  @type symbol :: any
  @type t :: %__MODULE__{
    a: Himamo.Model.A.t,
    b: Himamo.Model.B.t,
    pi: Himamo.Model.Pi.t,
    n: pos_integer,
    m: pos_integer,
  }
end
