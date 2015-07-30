defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "0.17.0",
      elixir: "~> 1.0",
      description: "A date/time library for Elixir",
      package: package,
      deps: deps ]

  end

  def application do
    [included_applications: [:tzdata, :combine], timezone: nil]
  end

  defp package do
    [ files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      contributors: ["Paul Schoenfelder", "Alexei Sholik"],
      licenses: ["MIT"],
      links: %{ "GitHub": "https://github.com/bitwalker/timex" } ]
  end

  def deps do
    [{:tzdata, "~> 0.1.6"},
     {:combine, "~> 0.3"},
     {:ex_doc, "~> 0.5", only: :dev},
     {:inch_ex, only: :docs}]
  end

end
