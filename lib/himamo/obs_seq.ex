defmodule Himamo.ObsSeq do
  defstruct [:seq, :seq_len, :prob]

  @type sequence :: list(Himamo.Model.symbol)
  @type t :: %__MODULE__{
    seq: sequence,
    seq_len: non_neg_integer,
    prob: Himamo.Model.ObsProb.t,
  }

  @spec new(sequence) :: t
  def new(sequence) do
    %__MODULE__{seq: sequence, seq_len: length(sequence)}
  end

  @spec compute_prob(t, Himamo.Model.B.t) :: t
  def compute_prob(%__MODULE__{seq: sequence} = obs, b) do
    %{obs | prob: Himamo.Model.ObsProb.new(b, sequence)}
  end
end
