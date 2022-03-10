defmodule Timex.Mixfile do
  use Mix.Project

  @version "3.7.7"

  def project do
    [
      app: :timex,
      version: @version,
      elixir: "~> 1.8",
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      compilers: [:gettext] ++ Mix.compilers(),
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env()),
      preferred_cli_env: [
        "hex.publish": :docs,
        docs: :docs,
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.detail": :test,
        "coveralls.json": :test,
        "coveralls.post": :test
      ]
    ]
  end

  def application do
    [
      env: [local_timezone: nil],
      mod: {Timex, []}
    ]
  end

  defp description do
    """
    Timex is a rich, comprehensive Date/Time library for Elixir projects, with full timezone support via the :tzdata package.
    If you need to manipulate dates, times, datetimes, timestamps, etc., then Timex is for you!
    """
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README.md", "LICENSE.md"],
      maintainers: ["Paul Schoenfelder", "Chris Hildebrand"],
      licenses: ["MIT"],
      links: %{
        Changelog: "https://github.com/bitwalker/timex/blob/master/CHANGELOG.md",
        GitHub: "https://github.com/bitwalker/timex"
      }
    ]
  end

  def deps do
    [
      {:tzdata, "~> 1.0"},
      {:combine, "~> 0.10"},
      {:gettext, "~> 0.10"},
      {:ex_doc, "~> 0.13", only: [:docs]},
      {:benchfella, "~> 0.3", only: [:bench]},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.4", only: [:test]},
      {:stream_data, "~> 0.4", only: [:test]}
    ]
  end

  defp docs do
    [
      main: "getting-started",
      formatter_opts: [gfm: true],
      source_ref: @version,
      source_url: "https://github.com/bitwalker/timex",
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
      ]
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/helpers"]
  defp elixirc_paths(_), do: ["lib"]
end
