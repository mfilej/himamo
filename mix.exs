defmodule Himamo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :himamo,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
      description: "Discrete Hidden Markov Models.",
      source_url: "https://github.com/mfilej/himamo",
      docs: [main: "Himamo"],
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.13", only: :dev},

      {:excheck, "~> 0.5", only: :test},
      {:triq, github: "krestenkrab/triq", only: :test},
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs README.md LICENSE),
      maintainers: ["Miha Filej"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/mfilej/himamo"},
    ]
  end
end
