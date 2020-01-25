defmodule DurationFormatDefaultTest do
  use ExUnit.Case, async: true
  use Timex

  alias Timex.Format.Duration.Formatters

  doctest Formatters.Default

  defp format(megaseconds, seconds, microseconds) do
    Duration.from_erl({megaseconds, seconds, microseconds})
    |> Formatters.Default.format()
  end

  test "format negative duration" do
    assert "PT0.9S" = format(0, -2, 1_100_000)
    assert "PT2.0001S" = format(0, -1, -1_000_100)
    assert "P45Y6M5DT21H12M34.590264S" = format(-1435, -180_354, -590_264)
  end
end
