defmodule TimezoneGapConversionTest do
  use ExUnit.Case, async: true

  alias Timex.{AmbiguousDateTime, AmbiguousTimezoneInfo, Timezone, TimezoneInfo}

  test "Toronto gap inputs return the adjacent valid boundaries for names and structs" do
    zone = "America/Toronto"

    for naive <- [
          ~N[2025-03-09 02:00:00],
          ~N[2025-03-09 02:30:00.123456],
          ~N[2025-03-09 02:59:59.999999]
        ],
        timezone <- [zone, %TimezoneInfo{full_name: zone}],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %AmbiguousDateTime{type: :gap, before: before_gap, after: after_gap} =
               convert.(naive, timezone)

      assert DateTime.to_naive(before_gap) == ~N[2025-03-09 01:59:59.999999]
      assert DateTime.to_naive(after_gap) == ~N[2025-03-09 03:00:00]
      assert before_gap.microsecond == {999_999, 6}
      assert after_gap.microsecond == {0, 0}

      assert {before_gap.utc_offset, before_gap.std_offset, before_gap.zone_abbr} ==
               {-18_000, 0, "EST"}

      assert {after_gap.utc_offset, after_gap.std_offset, after_gap.zone_abbr} ==
               {-18_000, 3600, "EDT"}

      assert before_gap.time_zone == zone
      assert after_gap.time_zone == zone
      assert DateTime.diff(after_gap, before_gap, :microsecond) == 1
    end
  end

  test "valid wall times immediately outside the Toronto gap remain unchanged" do
    for {naive, offset} <- [
          {~N[2025-03-09 01:59:59.999999], -18_000},
          {~N[2025-03-09 03:00:00], -14_400},
          {~N[2025-11-12 01:30:00.123], -18_000}
        ],
        timezone <- ["America/Toronto", %TimezoneInfo{full_name: "America/Toronto"}],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %DateTime{} = date = convert.(naive, timezone)
      assert DateTime.to_naive(date) == naive
      assert date.microsecond == naive.microsecond
      assert date.utc_offset + date.std_offset == offset
    end
  end

  test "a skipped calendar day has valid adjacent boundaries without assuming a one-hour gap" do
    assert %AmbiguousDateTime{type: :gap, before: earlier, after: later} =
             Timezone.convert(~N[2011-12-30 12:00:00], "Pacific/Apia")

    assert DateTime.to_naive(earlier) == ~N[2011-12-29 23:59:59.999999]
    assert DateTime.to_naive(later) == ~N[2011-12-31 00:00:00]
    assert earlier.utc_offset + earlier.std_offset == -36_000
    assert later.utc_offset + later.std_offset == 50_400
    assert DateTime.diff(later, earlier, :microsecond) == 1
  end

  test "date-only inputs retain their separate policy of selecting the later midnight result" do
    assert %DateTime{hour: 1, minute: 0, second: 0, time_zone: "Africa/Cairo"} =
             Timex.to_datetime(~D[2024-04-26], "Africa/Cairo")
  end

  test "overlaps retain both valid instants and the original fractional precision" do
    naive = ~N[2025-11-02 01:30:00.123]

    for timezone <- ["America/Toronto", %TimezoneInfo{full_name: "America/Toronto"}],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %AmbiguousDateTime{type: :ambiguous, before: earlier, after: later} =
               convert.(naive, timezone)

      assert DateTime.to_naive(earlier) == naive
      assert DateTime.to_naive(later) == naive
      assert earlier.microsecond == {123_000, 3}
      assert later.microsecond == {123_000, 3}
      assert earlier.utc_offset + earlier.std_offset == -14_400
      assert later.utc_offset + later.std_offset == -18_000
      assert DateTime.diff(later, earlier) == 3600
    end
  end

  test "same-zone ambiguous periods resolve once instead of nesting ambiguity results" do
    zone = "America/Toronto"
    before_period = Timezone.get(zone, ~N[2025-11-02 00:30:00])
    after_period = Timezone.get(zone, ~N[2025-11-02 02:30:00])
    periods = AmbiguousTimezoneInfo.new(before_period, after_period)

    for {naive, type} <- [
          {~N[2025-11-02 01:30:00], :ambiguous},
          {~N[2025-03-09 02:30:00], :gap}
        ],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %AmbiguousDateTime{type: ^type, before: %DateTime{}, after: %DateTime{}} =
               result = convert.(naive, periods)

      assert result == convert.(naive, zone)
    end

    assert %DateTime{hour: 12, zone_abbr: "EST"} =
             Timezone.convert(~N[2025-11-12 12:00:00], periods)
  end

  test "issue 691 gap reports expose boundaries in Melbourne, Chicago and Los Angeles" do
    for {zone, naive, before_gap, after_gap, before_offset, after_offset} <- [
          {"Australia/Melbourne", ~N[2021-10-03 02:31:07], ~N[2021-10-03 01:59:59.999999],
           ~N[2021-10-03 03:00:00], 36_000, 39_600},
          {"America/Chicago", ~N[2021-03-14 02:00:00], ~N[2021-03-14 01:59:59.999999],
           ~N[2021-03-14 03:00:00], -21_600, -18_000},
          {"America/Los_Angeles", ~N[2022-03-13 02:37:00], ~N[2022-03-13 01:59:59.999999],
           ~N[2022-03-13 03:00:00], -28_800, -25_200}
        ],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %AmbiguousDateTime{type: :gap, before: earlier, after: later} =
               convert.(naive, zone)

      assert DateTime.to_naive(earlier) == before_gap
      assert DateTime.to_naive(later) == after_gap
      assert earlier.utc_offset + earlier.std_offset == before_offset
      assert later.utc_offset + later.std_offset == after_offset
      assert DateTime.diff(later, earlier, :microsecond) == 1
    end
  end

  test "datetime tuples and maps expose the same gap through the public conversion APIs" do
    for input <- [
          {{2025, 3, 9}, {2, 30, 0}},
          %{year: 2025, month: 3, day: 9, hour: 2, minute: 30, second: 0}
        ],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %AmbiguousDateTime{type: :gap, before: earlier, after: later} =
               convert.(input, "America/Toronto")

      assert DateTime.to_naive(earlier) == ~N[2025-03-09 01:59:59.999999]
      assert DateTime.to_naive(later) == ~N[2025-03-09 03:00:00]
    end
  end

  test "normalization preserves aliases and canonical synthetic and POSIX labels" do
    naive = ~N[2025-03-09 02:30:00.123]

    for {timezone, name, offset} <- [
          {:utc, "Etc/UTC", 0},
          {0, "Etc/UTC", 0},
          {"UTC", "Etc/UTC", 0},
          {"Z", "Etc/UTC", 0},
          {"A", "Etc/UTC+1", 3600},
          {2, "Etc/UTC+2", 7200},
          {530, "Etc/UTC+5:30", 19_800},
          {-930, "Etc/UTC-9:30", -34_200},
          {"+02:00", "Etc/UTC+2", 7200},
          {"+05:45", "Etc/UTC+5:45", 20_700},
          {"+00", "Etc/UTC", 0},
          {"-00:00", "Etc/UTC", 0},
          {"Etc/GMT+4", "Etc/GMT+4", -14_400},
          {"Etc/GMT-4", "Etc/GMT-4", 14_400},
          {"EZT6EYT", "EZT6EYT", -21_600}
        ],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert %DateTime{time_zone: ^name} = date = convert.(naive, timezone)
      assert DateTime.to_naive(date) == naive
      assert date.microsecond == {123_000, 3}
      assert date.utc_offset + date.std_offset == offset
    end
  end

  test "unknown zones remain errors for names and structs" do
    for timezone <- ["No/Such_Zone", "", %TimezoneInfo{full_name: "No/Such_Zone"}],
        convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
      assert {:error, :time_zone_not_found} = convert.(~N[2025-03-09 02:30:00], timezone)
    end
  end

  test "issue 691 aware instant lookup does not interpret UTC digits as a Mexico City gap" do
    instant = ~U[2022-04-03 02:33:27.785095Z]

    assert %TimezoneInfo{abbreviation: "CST", offset_utc: -21_600, offset_std: 0} =
             Timezone.get("America/Mexico_City", instant)

    assert %DateTime{} = date = Timezone.convert(instant, "America/Mexico_City")
    assert DateTime.compare(date, instant) == :eq
    assert DateTime.to_naive(date) == ~N[2022-04-02 20:33:27.785095]
  end
end
