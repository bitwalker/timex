defmodule DurationFormatHumanizedTest do
  use ExUnit.Case, async: true
  use Timex

  alias Timex.Format.Duration.Formatters

  doctest Formatters.Humanized

  defp format(megaseconds, seconds, microseconds) do
    Duration.from_erl({megaseconds, seconds, microseconds})
    |> Formatters.Humanized.format()
  end

  test "format negative duration" do
    assert "900.0 milliseconds" = format(0, -2, 1_100_000)
    assert "2 seconds, 100 microseconds" = format(0, -1, -1_000_100)

    assert "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds" =
             format(-1435, -180_354, -590_264)
  end

  test "format zero duration" do
    assert "0 microseconds" = format(0, 0, 0)
  end
end
