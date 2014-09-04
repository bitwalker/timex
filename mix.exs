defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "0.12.5",
      elixir: "~> 1.0.0-rc1",
      description: "A date/time library for Elixir",
      package: package,
      deps: [] ]

  end
  def application, do: []

  defp package do
    [ files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      contributors: ["Paul Schoenfelder", "Alexei Sholik"],
      licenses: ["MIT"],
      links: [ { "GitHub", "https://github.com/bitwalker/timex" } ] ]
  end
end
