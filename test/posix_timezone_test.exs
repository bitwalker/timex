defmodule PosixTimezoneTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.Timezones.Posix
  alias Timex.PosixTimezone, as: TZ

  test "month rules select the requested occurrence, with week five meaning the last" do
    for {rule, year, expected} <- [
          {"M3.1.0", 2024, ~N[2024-03-03 02:00:00]},
          {"M3.2.0", 2024, ~N[2024-03-10 02:00:00]},
          {"M3.3.0", 2024, ~N[2024-03-17 02:00:00]},
          {"M3.4.0", 2024, ~N[2024-03-24 02:00:00]},
          {"M3.5.0", 2024, ~N[2024-03-31 02:00:00]},
          {"M2.5.0", 2024, ~N[2024-02-25 02:00:00]},
          {"M2.5.2", 2023, ~N[2023-02-28 02:00:00]},
          {"M6.1.6", 2024, ~N[2024-06-01 02:00:00]},
          {"M6.2.6", 2024, ~N[2024-06-08 02:00:00]},
          {"M6.3.6", 2024, ~N[2024-06-15 02:00:00]},
          {"M6.4.6", 2024, ~N[2024-06-22 02:00:00]},
          {"M6.5.6", 2024, ~N[2024-06-29 02:00:00]}
        ] do
      tz = parse!("ABC0DEF,#{rule},J300")
      assert TZ.dst_start(tz, Date.new!(year, 1, 1)) == expected
    end
  end

  test "Julian rules distinguish one-based no-leap dates from zero-based calendar days" do
    for {rule, year, expected} <- [
          {"J1", 2023, ~N[2023-01-01 02:00:00]},
          {"J60", 2023, ~N[2023-03-01 02:00:00]},
          {"J60", 2024, ~N[2024-03-01 02:00:00]},
          {"J365", 2023, ~N[2023-12-31 02:00:00]},
          {"J365", 2024, ~N[2024-12-31 02:00:00]},
          {"0", 2024, ~N[2024-01-01 02:00:00]},
          {"59", 2023, ~N[2023-03-01 02:00:00]},
          {"59", 2024, ~N[2024-02-29 02:00:00]},
          {"60", 2024, ~N[2024-03-01 02:00:00]},
          {"365", 2023, ~N[2024-01-01 02:00:00]},
          {"365", 2024, ~N[2024-12-31 02:00:00]}
        ] do
      tz = parse!("ABC0DEF,#{rule},J300")
      assert TZ.dst_start(tz, Date.new!(year, 1, 1)) == expected
    end
  end

  test "daylight offsets are adjustments to standard time in both public model views" do
    for {zone, date, utc, adjustment} <- [
          {"ABC5DEF,J60,J300", ~N[2024-07-01 12:00:00], -18_000, 3600},
          {"ABC-5:30DEF-6,J60,J300", ~N[2024-07-01 12:00:00], 19_800, 1800},
          {"ABC0DEF0:30,J60,J300", ~N[2024-07-01 12:00:00], 0, -1800},
          {"ABC5DEF5,J60,J300", ~N[2024-07-01 12:00:00], -18_000, 0}
        ] do
      tz = parse!(zone)

      assert %{offset_utc: ^utc, offset_std: ^adjustment, abbreviation: "DEF"} =
               TZ.to_timezone_info(tz, date)

      assert %{utc_offset: ^utc, std_offset: ^adjustment, zone_abbr: "DEF"} =
               TZ.to_period_for_date(tz, date)
    end
  end

  test "UTC evaluation uses the pre-transition offset and an exclusive end" do
    tz = parse!("ABC5DEF,M3.2.0,M11.1.0")

    for {utc, adjustment, abbreviation} <- [
          {~N[2024-03-10 06:59:59.999999], 0, "ABC"},
          {~N[2024-03-10 07:00:00], 3600, "DEF"},
          {~N[2024-11-03 05:59:59.999999], 3600, "DEF"},
          {~N[2024-11-03 06:00:00], 0, "ABC"}
        ] do
      assert {:ok, %{utc_offset: -18_000, std_offset: ^adjustment, zone_abbr: ^abbreviation}} =
               TZ.period_from_utc(tz, utc)
    end
  end

  test "southern seasons cross New Year and use the daylight offset at their end" do
    tz = parse!("ABC-10:30DEF-11,M10.1.0,M4.1.0")

    for {utc, adjustment, abbreviation} <- [
          {~N[2024-01-01 00:00:00], 1800, "DEF"},
          {~N[2024-04-06 14:59:59.999999], 1800, "DEF"},
          {~N[2024-04-06 15:00:00], 0, "ABC"},
          {~N[2024-10-05 15:29:59.999999], 0, "ABC"},
          {~N[2024-10-05 15:30:00], 1800, "DEF"},
          {~N[2024-12-31 23:59:59.999999], 1800, "DEF"}
        ] do
      assert {:ok, %{utc_offset: 37_800, std_offset: ^adjustment, zone_abbr: ^abbreviation}} =
               TZ.period_from_utc(tz, utc)
    end
  end

  test "wall resolution returns exact gap bounds and both overlap periods" do
    tz = parse!("ABC5DEF,M3.2.0,M11.1.0")

    for wall <- [~N[2024-03-10 02:00:00], ~N[2024-03-10 02:59:59.999999]] do
      assert {:gap, {%{std_offset: 0}, ~N[2024-03-10 02:00:00]},
              {%{std_offset: 3600}, ~N[2024-03-10 03:00:00]}} =
               TZ.periods_from_wall_datetime(tz, wall)
    end

    for wall <- [~N[2024-11-03 01:00:00], ~N[2024-11-03 01:59:59.999999]] do
      assert {:ambiguous, %{std_offset: 3600}, %{std_offset: 0}} =
               TZ.periods_from_wall_datetime(tz, wall)
    end

    assert {:ok, %{std_offset: 3600}} = TZ.periods_from_wall_datetime(tz, ~N[2024-03-10 03:00:00])
    assert {:ok, %{std_offset: 0}} = TZ.periods_from_wall_datetime(tz, ~N[2024-11-03 02:00:00])
  end

  test "negative daylight adjustment reverses the gap and overlap transitions" do
    tz = parse!("ABC0DEF0:30,M3.2.0,M11.1.0")

    assert {:ambiguous, %{std_offset: 0}, %{std_offset: -1800}} =
             TZ.periods_from_wall_datetime(tz, ~N[2024-03-10 01:45:00])

    assert {:gap, {%{std_offset: -1800}, ~N[2024-11-03 02:00:00]},
            {%{std_offset: 0}, ~N[2024-11-03 02:30:00]}} =
             TZ.periods_from_wall_datetime(tz, ~N[2024-11-03 02:15:00])
  end

  test "zero daylight adjustment changes abbreviation without creating ambiguity" do
    tz = parse!("ABC5DEF5,M3.2.0,M11.1.0")

    assert {:ok, %{std_offset: 0, zone_abbr: "DEF"}} =
             TZ.periods_from_wall_datetime(tz, ~N[2024-03-10 02:00:00])

    assert {:ok, %{std_offset: 0, zone_abbr: "ABC"}} =
             TZ.periods_from_wall_datetime(tz, ~N[2024-11-03 02:00:00])
  end

  test "all-year negative daylight saving has no artificial New Year standard period" do
    tz = parse!("XXX3EDT4,0/0,J365/23")

    for utc <- [
          ~N[2023-01-01 02:59:59],
          ~N[2023-01-01 03:00:00],
          ~N[2024-01-01 03:00:00],
          ~N[2024-07-01 00:00:00]
        ] do
      assert {:ok, %{utc_offset: -10_800, std_offset: -3600, zone_abbr: "EDT"}} =
               TZ.period_from_utc(tz, utc)
    end
  end

  test "zones without explicit transitions keep their standard period" do
    for zone <- ["ABC5", "ABC5DEF"] do
      tz = parse!(zone)

      assert {:ok, %{utc_offset: -18_000, std_offset: 0, zone_abbr: "ABC"}} =
               TZ.period_from_utc(tz, ~N[2024-07-01 00:00:00])

      refute TZ.is_dst?(tz, ~D[2024-07-01])
    end
  end

  test "UTC period and DST queries honor the offset of aware inputs" do
    tz = parse!("ABC5DEF,M3.2.0,M11.1.0")
    date = DateTime.from_naive!(~N[2024-03-10 03:00:00], "Etc/UTC-5", Timex.Timezone.Database)
    assert {:ok, %{std_offset: 3600}} = TZ.period_from_utc(tz, date)
    assert TZ.is_dst?(tz, date)
    assert %{offset_std: 3600} = TZ.to_timezone_info(tz, date)
  end

  test "seasons spilling past New Year retain the previous year's active period" do
    tz = parse!("ABC24DEF23,J365/23,J365/23:30")

    assert {:ok, %{std_offset: 3600, zone_abbr: "DEF"}} =
             TZ.period_from_utc(tz, ~N[2024-01-01 00:00:00])

    assert {:ok, %{std_offset: 0, zone_abbr: "ABC"}} =
             TZ.period_from_utc(tz, ~N[2024-01-01 22:30:00])

    assert {:ok, %{std_offset: 3600, zone_abbr: "DEF"}} =
             TZ.period_from_utc(tz, ~N[2024-01-01 23:00:00])
  end

  test "neighboring rule years do not overflow the supported query date range" do
    tz = parse!("ABC5DEF,M3.2.0,M11.1.0")

    for date <- [~N[-9999-01-01 00:00:00], ~N[9999-12-31 23:59:59]] do
      assert {:ok, %{utc_offset: -18_000, std_offset: 0}} = TZ.period_from_utc(tz, date)
    end
  end

  test "DST predicate requires a unique daylight interpretation of a wall time" do
    tz = parse!("ABC5DEF,M3.2.0,M11.1.0")
    refute TZ.is_dst?(tz, ~N[2024-03-10 02:30:00])
    refute TZ.is_dst?(tz, ~N[2024-11-03 01:30:00])
    assert TZ.is_dst?(tz, ~D[2024-07-01])
    refute TZ.is_dst?(tz, ~D[2024-01-01])
  end

  defp parse!(zone) do
    assert {:ok, %TZ{} = tz, ""} = Posix.parse(zone)
    tz
  end
end
