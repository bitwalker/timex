defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "1.0.0-rc2",
      elixir: "~> 1.0",
      description: "A date/time library for Elixir",
      package: package,
      deps: deps,
      docs: docs,
      test_coverage: [tool: ExCoveralls] ]

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
     {:earmark, ">= 0.0.0", only: :dev},
     {:benchfella, "~> 0.2", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:excoveralls, "~> 0.4", only: :test},
     {:inch_ex, "~> 0.4", only: :docs},
     {:credo, "~> 0.1.9", only: [:dev, :test]}]
  end

  defp docs do
    [main: "extra-getting-started",
     extras: [
       "docs/Getting Started.md",
       "docs/Basic Usage.md",
       "docs/Erlang Interop.md",
       "docs/Working with DateTime.md",
       "docs/Working with Time.md",
       "docs/Formatting.md",
       "docs/Parsing.md",
       "docs/FAQ.md",
       "docs/Using with Ecto.md",
       "docs/Custom Parsers.md",
       "docs/Custom Formatters.md"
    ]]
  end

end
