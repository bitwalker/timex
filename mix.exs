defmodule Timex.Mixfile do
  use Mix.Project

  def project do
    [ app: :timex,
      version: "3.0.3",
      elixir: "~> 1.3",
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      compilers: [:gettext] ++ Mix.compilers,
      test_coverage: [tool: ExCoveralls] ]

  end

  def application do
    [applications: [:logger, :tzdata, :gettext, :combine],
     env: [local_timezone: nil, default_locale: "en"]]
  end

  defp description do
    """
    Timex is a rich, comprehensive Date/Time library for Elixir projects, with full timezone support via the :tzdata package.
    If you need to manipulate dates, times, datetimes, timestamps, etc., then Timex is for you!
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
     {:gettext, "~> 0.10"},
     {:ex_doc, "~> 0.12", only: :dev},
     {:earmark, "~> 0.2", only: :dev},
     {:benchfella, "~> 0.3", only: :dev},
     {:dialyze, "~> 0.2", only: :dev},
     {:excoveralls, "~> 0.4", only: [:dev, :test]},
     {:inch_ex, "~> 0.4", only: [:dev, :test]}]
  end

  defp docs do
    [main: "getting-started",
     formatter_opts: [gfm: true],
     extras: [
       "docs/Getting Started.md",
       "CHANGELOG.md",
       "docs/Basic Usage.md",
       "docs/Erlang Interop.md",
       "docs/Formatting.md",
       "docs/Parsing.md",
       "docs/FAQ.md",
       "docs/Using with Ecto.md",
       "docs/Custom Parsers.md",
       "docs/Custom Formatters.md"
    ]]
  end

end
