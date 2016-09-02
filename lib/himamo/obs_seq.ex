defmodule Himamo.ObsSeq do
  @moduledoc ~S"""
  Defines an observation sequence.

  ## Examples

      iex> Himamo.ObsSeq.new([0, 0, 1, 0, 1])
      %Himamo.ObsSeq{len: 5, prob: nil, seq: [0, 0, 1, 0, 1]}
  """

  defstruct [:seq, :len, :prob]

  @type sequence :: list(Himamo.Model.symbol)
  @type t :: %__MODULE__{
    seq: sequence,
    len: non_neg_integer,
    prob: Himamo.Model.ObsProb.t,
  }

  @spec new(sequence) :: t
  def new(sequence) do
    %__MODULE__{seq: sequence, len: length(sequence)}
  end

  @spec compute_prob(t, Himamo.Model.B.t) :: t
  def compute_prob(%__MODULE__{seq: sequence} = obs, b) do
    %{obs | prob: Himamo.Model.ObsProb.new(b, sequence)}
  end
end
