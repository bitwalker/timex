defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "0.14.3",
      elixir: "~> 1.0.0",
      description: "A date/time library for Elixir",
      package: package,
      deps: deps ]

  end
  def application, do: []

  defp package do
    [ files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      contributors: ["Paul Schoenfelder", "Alexei Sholik"],
      licenses: ["MIT"],
      links: %{ "GitHub": "https://github.com/bitwalker/timex" } ]
  end

  def deps do 
    [{:tzdata, "~> 0.1.6"},
     {:earmark, "~> 0.1", only: :dev},
     {:ex_doc, "~> 0.5", only: :dev}]
  end 

end
