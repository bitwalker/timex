defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "1.0.0-pre",
      elixir: "~> 1.0",
      description: "A date/time library for Elixir",
      package: package,
      deps: deps ]

  end

  def application do
    [applications: [:logger, :tzdata],
     included_applications: [:combine], local_timezone: nil]
  end

  defp package do
    [ files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Paul Schoenfelder"],
      licenses: ["MIT"],
      links: %{ "GitHub": "https://github.com/bitwalker/timex" } ]
  end

  def deps do
    [{:tzdata, "== 0.1.8 or ~> 0.5"},
     {:combine, "~> 0.5"},
     {:ex_doc, "~> 0.10", only: :dev},
     {:benchfella, "~> 0.2", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:inch_ex, "~> 0.4", only: :docs}]
  end

end
