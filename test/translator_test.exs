defmodule Timex.TranslatorTest do
  use ExUnit.Case, async: true
  doctest Timex.Translator

  test "with_locale macro uses the specified locale" do
    use Timex
    duration = Duration.from_seconds(Timex.to_unix({2016, 2, 29}))

    in_dutch =
      Timex.Translator.with_locale "nl" do
        Timex.format_duration(duration, :humanized)
      end

    assert in_dutch == "46 jaren, 2 maanden, 1 week, 3 dagen"
  end
end
