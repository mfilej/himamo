# HiMaMo

Discrete **Hi**dden **Ma**rkov **Mo**dels for Elixir.

## Installation

Add `himamo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:himamo, "~> 0.0.1"}]
end
```

## Usage

See [docs].

## Credits

The fundamentals of hidden markov models would not be understandable to me if
it wasn't for Rabiner's excellent [A tutorial on hidden Markov models and
selected applications in speech recognition][rabiner] (also see [errata]).
Reading the source of [guyz/HMM][guyz] was crucial to understand how to port
these equations to code. The article [Numerically Stable Hidden Markov Model
Implementation][numstable] was essential for fighting underflow issues.

[docs]: https://hexdocs.pm/himamo
[rabiner]: http://www.ece.ucsb.edu/Faculty/Rabiner/ece259/Reprints/tutorial%20on%20hmm%20and%20applications.pdf
[errata]: http://www.media.mit.edu/~rahimi/rabiner/rabiner-errata/
[numstable]: https://core.ac.uk/download/pdf/22865757.pdf
[guyz]: https://github.com/guyz/HMM

## Licence

MIT, see [LICENSE](LICENSE).
