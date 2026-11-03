defmodule PosixTimezoneParsing.Tests do
  use ExUnit.Case, async: true
  alias Timex.Parse.Timezones.Posix
  alias Timex.PosixTimezone, as: TZ

  test "classic transition syntax rejects lexical signs and hours above24" do
    for time <- ["+0", "-0", "+2", "-1", "25"] do
      assert {:error, _, _} =
               Posix.parse("ABC0DEF,J60/#{time},J300", extended_transition_times: false)
    end

    for time <- ["0", "24", "24:59:59"] do
      assert {:ok, %TZ{}, ""} =
               Posix.parse("ABC0DEF,J60/#{time},J300", extended_transition_times: false)
    end

    assert {:ok, %TZ{}, ""} = Posix.parse("ABC0DEF,J60/-1,J300")
  end

  test "standard offset is required even when both abbreviations are quoted" do
    for zone <- ["<abc><def>", "<abc>+<def>", "<abc>-<def>"] do
      assert {:error, _, _} = Posix.parse(zone)
    end
  end

  test "quoted abbreviations allow only portable alphanumerics and signs" do
    for zone <- ["<ab:c>0DEF", "ABC0<d ef>", "<ab_c>0DEF", "<ééé>0DEF"] do
      assert {:error, _, _} = Posix.parse(zone)
    end
  end

  test "fixed zones and signed fractional offsets retain their designation" do
    for {zone, abbreviation, offset} <- [
          {"ABC0", "ABC", 0},
          {"ABC+5:30", "ABC", -19_800},
          {"ABC-0:30:15", "ABC", 1815},
          {"<+0545>-5:45", "+0545", 20_700},
          {"ABC24", "ABC", -86_400}
        ] do
      assert {:ok, %TZ{std_abbr: ^abbreviation, std_offset: ^offset, dst_offset: ^offset}, ""} =
               Posix.parse(zone)
    end
  end

  test "malformed numeric components cannot fall back to a shorter offset or rule" do
    for zone <- [
          "ABC1:DEF",
          "ABC1:60DEF",
          "ABC1:2:DEF",
          "ABC1:2:60DEF",
          "ABC0DEF+",
          "ABC0DEF-",
          "ABC0DEF,M3junk.2.0,M11.1.0",
          "ABC0DEF,M3.2.+0,M11.1.0",
          "ABC0DEF,M3.2.0junk,M11.1.0",
          "ABC0DEF,M3.2.0/168,M11.1.0"
        ] do
      assert {:error, _, _} = Posix.parse(zone)
    end
  end

  test "low level parsing retains data after a complete final rule or newline" do
    assert {:ok, %TZ{}, "suffix"} = Posix.parse("ABC0DEF,M3.2.0,M11.1.0suffix")
    assert {:ok, %TZ{}, "payload"} = Posix.parse("ABC0DEF\npayload")
    assert {:ok, nil, "payload"} = Posix.parse("\npayload")
  end

  test "canonical names preserve quoted and fractional offsets when parsed again" do
    for {zone, offset, dst_offset} <- [
          {"ABC+5:30DEF4:30", -19_800, -16_200},
          {"ABC-0:30:15DEF-1:30:15", 1815, 5415},
          {"<+0545>-5:45<+0645>", 20_700, 24_300},
          {"ABC5DEF6", -18_000, -21_600}
        ] do
      assert {:ok, %TZ{name: name, std_offset: ^offset, dst_offset: ^dst_offset}, ""} =
               Posix.parse(zone)

      assert {:ok, %TZ{std_offset: ^offset, dst_offset: ^dst_offset}, ""} = Posix.parse(name)
    end
  end

  test "stdoffset[dst]" do
    tz = "CST6CDT"

    res = %TZ{
      name: "CST6CDT",
      std_offset: 6 * 3600 * -1,
      dst_offset: 5 * 3600 * -1,
      std_abbr: "CST",
      dst_abbr: "CDT"
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst,[start/time,end/time]]" do
    tz = "CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00"

    std_offset = 6 * 3600 * -1

    res = %TZ{
      name: "CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00",
      std_offset: std_offset,
      dst_offset: std_offset + 3600,
      std_abbr: "CST",
      dst_abbr: "CDT",
      dst_start: {{:mwd, {3, 2, 0}}, 7200},
      dst_end: {{:mwd, {11, 1, 0}}, 7200}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst,[start/time,end/time]], julian dates" do
    tz = "CST-2CEST,J1/1:00,J110/1:00"

    std_offset = 2 * 3600

    res = %TZ{
      name: "CST-2CEST,J1/1:00,J110/1:00",
      std_offset: std_offset,
      dst_offset: std_offset + 3600,
      std_abbr: "CST",
      dst_abbr: "CEST",
      dst_start: {{:julian, 1}, 3600},
      dst_end: {{:julian, 110}, 3600}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst,[start/time,end/time]], julian dates (leap)" do
    tz = "CST-2CEST,0/1:00,110/1:00"

    std_offset = 2 * 3600

    res = %TZ{
      name: "CST-2CEST,0/1:00,110/1:00",
      std_offset: std_offset,
      dst_offset: std_offset + 3600,
      std_abbr: "CST",
      dst_abbr: "CEST",
      dst_start: {{:julian_leap, 0}, 3600},
      dst_end: {{:julian_leap, 110}, 3600}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst[offset],[start/time,end/time]]" do
    tz = "CST-2CEST-3,M3.2.0/2:00:00,M11.1.0/2:00:00"

    std_offset = 2 * 3600

    res = %TZ{
      name: "CST-2CEST-3,M3.2.0/2:00:00,M11.1.0/2:00:00",
      std_offset: std_offset,
      dst_offset: 3 * 3600,
      std_abbr: "CST",
      dst_abbr: "CEST",
      dst_start: {{:mwd, {3, 2, 0}}, 7200},
      dst_end: {{:mwd, {11, 1, 0}}, 7200}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end
end
