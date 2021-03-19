defmodule PosixTimezoneParsing.Tests do
  use ExUnit.Case, async: true
  alias Timex.Parse.Timezones.Posix
  alias Timex.PosixTimezone, as: TZ

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
      name: "CST6CDT",
      std_offset: std_offset,
      dst_offset: std_offset + 3600,
      std_abbr: "CST",
      dst_abbr: "CDT",
      dst_start: {{:mwd, {3, 2, 0}}, ~T[02:00:00]},
      dst_end: {{:mwd, {11, 1, 0}}, ~T[02:00:00]}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst,[start/time,end/time]], julian dates" do
    tz = "CST-2CEST,J1/1:00,J110/1:00"

    std_offset = 2 * 3600

    res = %TZ{
      name: "CST-2CEST",
      std_offset: std_offset,
      dst_offset: std_offset + 3600,
      std_abbr: "CST",
      dst_abbr: "CEST",
      dst_start: {{:julian, 1}, ~T[01:00:00]},
      dst_end: {{:julian, 110}, ~T[01:00:00]}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst,[start/time,end/time]], julian dates (leap)" do
    tz = "CST-2CEST,0/1:00,110/1:00"

    std_offset = 2 * 3600

    res = %TZ{
      name: "CST-2CEST",
      std_offset: std_offset,
      dst_offset: std_offset + 3600,
      std_abbr: "CST",
      dst_abbr: "CEST",
      dst_start: {{:julian_leap, 0}, ~T[01:00:00]},
      dst_end: {{:julian_leap, 110}, ~T[01:00:00]}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end

  test "stdoffset[dst[offset],[start/time,end/time]]" do
    tz = "CST-2CEST-3,M3.2.0/2:00:00,M11.1.0/2:00:00"

    std_offset = 2 * 3600

    res = %TZ{
      name: "CST-2CEST-3",
      std_offset: std_offset,
      dst_offset: 3 * 3600,
      std_abbr: "CST",
      dst_abbr: "CEST",
      dst_start: {{:mwd, {3, 2, 0}}, ~T[02:00:00]},
      dst_end: {{:mwd, {11, 1, 0}}, ~T[02:00:00]}
    }

    assert {:ok, ^res, ""} = Posix.parse(tz)
  end
end
