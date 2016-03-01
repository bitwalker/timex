defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "1.0.2",
      elixir: "~> 1.0",
      description: description,
      package: package,
      deps: deps,
      docs: docs,
      test_coverage: [tool: ExCoveralls] ]

  end

  def application do
    [applications: [:logger, :tzdata],
     included_applications: [:combine],
     env: [local_timezone: nil]]
  end

  defp description do
    """
    A date/time library for Elixir

    Fully timezone-aware, using the Olson Timezone database

    - Supports local-timezone lookups
    - Supports POSIX-style timezones

    Provides a broad array of Date helper functions

    - shifting/adding/subtracting
    - diffing
    - comparing
    - conversions
    - get day of week, week of year, ISO dates, and names for each
    - get the beginning or ending of a given week
    - get the beginning or ending of a year, quarter, week, or month
    - get days in a given month
    - normalization

    Provides a broad array of Time helpers

    - convert to and from units: weeks, days, hours, seconds, ms, and nanoseconds
    - measure execution time
    - diff/compare
    - to/from 12/24 hour clock times
    - add/subtract

    Safe DateTime string formatting and parsing

    - Informative parser errors
    - Supports strftime, as well as an easier to read formatter, i.e. `{ISO:Basic}`, `{YYYY}`
    - Supports many formats out of the box: ISO8601 basic and extended, RFC822, RFC1123, RFC3339, ANSIC, UNIX

    Extendable

    - Protocols for core modules like the parser tokenizer
    - Easy to wrap to add extra functionality

    Can be used with Phoenix and Ecto when used with timex_ecto package
    """
  end

  defp package do
    [ files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Paul Schoenfelder"],
      licenses: ["MIT"],
      links: %{ "GitHub": "https://github.com/bitwalker/timex" } ]
  end

  def deps do
    [{:tzdata, "~> 0.1.8 or ~> 0.5"},
     {:combine, "~> 0.7"},
     {:ex_doc, "== 0.10.0", only: :dev},
     {:earmark, "== 0.1.19", only: :dev},
     {:benchfella, "~> 0.3", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:excoveralls, "~> 0.4", only: :test},
     {:inch_ex, "~> 0.4", only: :docs}]
  end

  defp docs do
    [main: "extra-getting-started",
     formatter_opts: [gfm: true],
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
