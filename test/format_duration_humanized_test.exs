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

  test "format/2 across Pacific/Norfolk permanent UTC offset change" do
    # Pacific/Norfolk permanently changed its UTC offset from +11:30 to +11:00
    # on 4 October 2015 (a one-time tzdata rule change, not a recurring DST
    # transition). format/1, given only a raw elapsed Duration, has no way to
    # know the true offset delta and misattributes it as spurious trailing
    # hours/minutes (see format_duration_humanized_bug_test.exs). format/2
    # takes both datetimes and computes years/months via real calendar
    # arithmetic, so the distance comes out clean.
    {:ok, start} =
      DateTime.new(~D[2015-01-15], ~T[00:00:00], "Pacific/Norfolk", Tzdata.TimeZoneDatabase)

    {:ok, finish} =
      DateTime.new(~D[2016-03-15], ~T[00:00:00], "Pacific/Norfolk", Tzdata.TimeZoneDatabase)

    assert "1 year, 2 months" = Formatters.Humanized.format(start, finish)
  end

  test "format/2 across Europe/Dublin DST transition" do
    # 2024-10-27 00:59:30 UTC is 01:59:30 IST in Dublin, one second before the
    # "fall back" transition to GMT.
    {:ok, dstart_utc} = DateTime.new(~D[2024-10-27], ~T[00:59:30], "Etc/UTC")
    {:ok, dstart} = DateTime.shift_zone(dstart_utc, "Europe/Dublin", Tzdata.TimeZoneDatabase)
    dfinish_utc = DateTime.add(dstart_utc, 60, :second)
    {:ok, dfinish} = DateTime.shift_zone(dfinish_utc, "Europe/Dublin", Tzdata.TimeZoneDatabase)

    assert dstart.zone_abbr == "IST"
    assert dfinish.zone_abbr == "GMT"
    assert "1 minute" = Formatters.Humanized.format(dstart, dfinish)
  end

  test "format/2 is order-independent, like format/1" do
    # format/1 always returns the same string for a duration regardless of
    # sign (see "format negative duration" above). format/2 should behave the
    # same way regardless of whether `finish` is chronologically before
    # `start` -- previously this raised, because a negative :years/:months
    # count was passed straight into Gettext's plural translation, which
    # requires n >= 0.
    {:ok, start} =
      DateTime.new(~D[2015-01-15], ~T[00:00:00], "Pacific/Norfolk", Tzdata.TimeZoneDatabase)

    {:ok, finish} =
      DateTime.new(~D[2016-03-15], ~T[00:00:00], "Pacific/Norfolk", Tzdata.TimeZoneDatabase)

    assert "1 year, 2 months" = Formatters.Humanized.format(finish, start)
  end
end

