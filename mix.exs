defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "0.19.5",
      elixir: "~> 1.0",
      description: "A date/time library for Elixir",
      package: package,
      deps: deps ]

  end

  def application do
    [applications: [:tzdata], included_applications: [:combine], local_timezone: nil]
  end

  defp package do
    [ files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      contributors: ["Paul Schoenfelder", "Alexei Sholik"],
      licenses: ["MIT"],
      links: %{ "GitHub": "https://github.com/bitwalker/timex" } ]
  end

  def deps do
    [{:tzdata, "~> 0.5.2"},
     {:combine, "~> 0.5"},
     {:ex_doc, "~> 0.9", only: :dev},
     {:benchfella, "~> 0.2", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:inch_ex, "== 0.3.3", only: :docs}]
  end

end
