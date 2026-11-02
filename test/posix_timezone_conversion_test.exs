defmodule PosixTimezoneConversionTest do
  use ExUnit.Case, async: true

  alias Timex.{AmbiguousDateTime, AmbiguousTimezoneInfo, Timezone, TimezoneInfo}
  alias Timex.Timezone.Database

  @north "ABC5DEF,M3.2.0,M11.1.0"
  @south "ABC-10:30DEF-11,M10.1.0,M4.1.0"

  test "lookup retains rule identity and applies northern and southern seasons" do
    for {zone, wall, total, abbreviation} <- [
          {@north, ~N[2024-01-01 12:00:00], -18_000, "ABC"},
          {@north, ~N[2024-07-01 12:00:00], -14_400, "DEF"},
          {@south, ~N[2024-01-01 12:00:00], 39_600, "DEF"},
          {@south, ~N[2024-07-01 12:00:00], 37_800, "ABC"}
        ] do
      assert %TimezoneInfo{full_name: ^zone, abbreviation: ^abbreviation} =
               info = Timezone.get(zone, wall)

      assert info.offset_utc + info.offset_std == total
    end
  end

  test "lookup honors UTC basis and aware input offsets around transitions" do
    for {instant, total} <- [
          {~U[2024-03-10 06:30:00Z], -18_000},
          {~U[2024-03-10 07:00:00Z], -14_400},
          {~U[2024-11-03 05:30:00Z], -14_400},
          {~U[2024-11-03 06:00:00Z], -18_000}
        ] do
      for date <- [instant, DateTime.shift_zone!(instant, "Etc/UTC+3", Database)] do
        assert %TimezoneInfo{} = info = Timezone.get(@north, date)
        assert info.offset_utc + info.offset_std == total
      end

      assert %TimezoneInfo{} = info = Timezone.get(@north, DateTime.to_naive(instant), :utc)
      assert info.offset_utc + info.offset_std == total
    end

    assert %TimezoneInfo{offset_std: 3600} = Timezone.get(@north, ~U[2024-03-10 06:30:00Z], :wall)
  end

  test "calendar and Timex conversions preserve aware instants and precision" do
    for {zone, instant, local, total} <- [
          {@north, ~U[2024-03-10 06:59:59.999999Z], ~N[2024-03-10 01:59:59.999999], -18_000},
          {@north, ~U[2024-03-10 07:00:00Z], ~N[2024-03-10 03:00:00], -14_400},
          {@north, ~U[2024-11-03 06:00:00.123Z], ~N[2024-11-03 01:00:00.123], -18_000},
          {@south, ~U[2024-04-06 15:00:00Z], ~N[2024-04-07 01:30:00], 37_800},
          {@south, ~U[2024-10-05 15:30:00Z], ~N[2024-10-06 02:30:00], 39_600}
        ] do
      assert {:ok, native} = DateTime.shift_zone(instant, zone, Database)

      for date <- [native, Timezone.convert(instant, zone), Timex.to_datetime(instant, zone)] do
        assert %DateTime{time_zone: ^zone} = date
        assert DateTime.compare(date, instant) == :eq
        assert DateTime.to_naive(date) == local
        assert date.microsecond == instant.microsecond
        assert date.utc_offset + date.std_offset == total
      end
    end
  end

  test "gaps expose adjacent valid instants through Calendar and Timex" do
    for {zone, wall, before_wall, after_wall, before_total, after_total} <- [
          {@north, ~N[2024-03-10 02:30:00.123], ~N[2024-03-10 01:59:59.999999],
           ~N[2024-03-10 03:00:00], -18_000, -14_400},
          {@south, ~N[2024-10-06 02:15:00], ~N[2024-10-06 01:59:59.999999],
           ~N[2024-10-06 02:30:00], 37_800, 39_600},
          {"ABC0DEF0:30,M3.2.0,M11.1.0", ~N[2024-11-03 02:15:00], ~N[2024-11-03 01:59:59.999999],
           ~N[2024-11-03 02:30:00], -1800, 0}
        ] do
      assert {:gap, earlier, later} = DateTime.from_naive(wall, zone, Database)
      assert_gap(earlier, later, before_wall, after_wall, before_total, after_total)

      for target <- [zone, %TimezoneInfo{full_name: zone}],
          convert <- [&Timezone.convert/2, &Timex.to_datetime/2] do
        assert %AmbiguousDateTime{type: :gap, before: before_gap, after: after_gap} =
                 convert.(wall, target)

        assert_gap(before_gap, after_gap, before_wall, after_wall, before_total, after_total)
      end
    end
  end

  test "overlaps return both interpretations in UTC order" do
    for {zone, wall, earlier_total, later_total, separation} <- [
          {@north, ~N[2024-11-03 01:30:00.123], -14_400, -18_000, 3600},
          {@south, ~N[2024-04-07 01:45:00.123], 39_600, 37_800, 1800},
          {"ABC0DEF0:30,M3.2.0,M11.1.0", ~N[2024-03-10 01:45:00.123], 0, -1800, 1800}
        ] do
      assert {:ambiguous, earlier, later} = DateTime.from_naive(wall, zone, Database)

      for {a, b} <- [{earlier, later}, timex_overlap(wall, zone)] do
        assert DateTime.to_naive(a) == wall
        assert DateTime.to_naive(b) == wall
        assert a.microsecond == {123_000, 3}
        assert b.microsecond == {123_000, 3}
        assert a.utc_offset + a.std_offset == earlier_total
        assert b.utc_offset + b.std_offset == later_total
        assert DateTime.diff(b, a) == separation
      end

      assert %AmbiguousTimezoneInfo{before: %TimezoneInfo{}, after: %TimezoneInfo{}} =
               Timezone.get(zone, wall)
    end
  end

  test "timezone info lookup reports gaps without selecting a period" do
    assert {:error, {:could_not_resolve_timezone, @north, _, :wall}} =
             Timezone.get(@north, ~N[2024-03-10 02:30:00])
  end

  test "GMT-prefixed POSIX rules are not mistaken for fixed GMT offset aliases" do
    for {zone, canonical, total} <- [
          {"GMT-1ABC,M3.2.0,M11.1.0", "GMT-1ABC,M3.2.0,M11.1.0", 7200},
          {"GMT+1ABC,M3.2.0,M11.1.0", "GMT1ABC,M3.2.0,M11.1.0", 0}
        ] do
      assert %TimezoneInfo{full_name: ^canonical, abbreviation: "ABC"} =
               info = Timezone.get(zone, ~N[2024-07-01 12:00:00])

      assert info.offset_utc + info.offset_std == total

      assert %DateTime{time_zone: ^canonical, zone_abbr: "ABC"} =
               Timezone.convert(~U[2024-07-01 12:00:00Z], zone)
    end

    for {zone, canonical, total} <- [
          {"GMT+4", "Etc/UTC+4", 14_400},
          {"GMT-4", "Etc/UTC-4", -14_400},
          {"GMT+05:30", "Etc/UTC+5:30", 19_800},
          {"Etc/GMT+4", "Etc/GMT+4", -14_400}
        ] do
      assert %TimezoneInfo{full_name: ^canonical, offset_utc: ^total} =
               Timezone.get(zone, ~N[2024-07-01 12:00:00])
    end
  end

  test "carried transitions work through public conversion and Date midnight policy" do
    zone = "ABC0DEF,J60/24,J300/24"
    assert %DateTime{hour: 1, std_offset: 3600} = Timex.to_datetime(~D[2024-03-02], zone)
    assert %AmbiguousDateTime{type: :gap} = Timezone.convert(~N[2024-03-02 00:30:00], zone)

    zone = "ABC0DEF,0/-1,J300"
    instant = ~U[2023-12-31 23:00:00Z]
    assert {:ok, date} = DateTime.shift_zone(instant, zone, Database)
    assert DateTime.to_naive(date) == ~N[2024-01-01 00:00:00]
    assert date.std_offset == 3600
  end

  test "far-future periods and supported date edges use the same recurring rules" do
    for {instant, adjustment} <- [
          {~U[0000-01-01 00:00:00Z], 0},
          {~U[2100-07-01 00:00:00Z], 3600},
          {~U[9999-07-01 00:00:00Z], 3600}
        ] do
      assert %TimezoneInfo{offset_std: ^adjustment} = Timezone.get(@north, instant)

      assert {:ok, %{std_offset: ^adjustment}} =
               Database.time_zone_period_from_utc_iso_days(
                 Calendar.ISO.naive_datetime_to_iso_days(
                   instant.year,
                   instant.month,
                   instant.day,
                   instant.hour,
                   instant.minute,
                   instant.second,
                   instant.microsecond
                 ),
                 @north
               )
    end
  end

  test "custom process-state fallback remains available for unknown zone names" do
    zone = "Custom/Zone"
    info = %TimezoneInfo{full_name: zone, abbreviation: "CUSTOM", offset_utc: 3600}
    Process.put(Database, info)
    assert {:ok, date} = DateTime.from_naive(~N[2024-01-01 12:00:00], zone, Database)
    assert {date.utc_offset, date.zone_abbr} == {3600, "CUSTOM"}
    Process.put(Database, info)
    assert {:ok, shifted} = DateTime.shift_zone(~U[2024-01-01 12:00:00Z], zone, Database)
    assert DateTime.to_naive(shifted) == ~N[2024-01-01 13:00:00]
  end

  defp assert_gap(earlier, later, before_wall, after_wall, before_total, after_total) do
    assert DateTime.to_naive(earlier) == before_wall
    assert DateTime.to_naive(later) == after_wall
    assert earlier.utc_offset + earlier.std_offset == before_total
    assert later.utc_offset + later.std_offset == after_total
    assert DateTime.diff(later, earlier, :microsecond) == 1
  end

  defp timex_overlap(wall, zone) do
    assert %AmbiguousDateTime{type: :ambiguous, before: a, after: b} =
             Timezone.convert(wall, zone)

    {a, b}
  end
end
