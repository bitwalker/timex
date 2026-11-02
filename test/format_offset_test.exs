defmodule Timex.Format.OffsetTest do
  use ExUnit.Case, async: true

  @offsets [
    {0, 0, "+0000", "+00:00", "+00:00:00"},
    {34_200, 0, "+0930", "+09:30", "+09:30:00"},
    {-34_200, 0, "-0930", "-09:30", "-09:30:00"},
    {-20_700, 0, "-0545", "-05:45", "-05:45:00"},
    {-1_800, 0, "-0030", "-00:30", "-00:30:00"},
    {-1, 0, "-0000", "-00:00", "-00:00:01"},
    {1, 0, "+0000", "+00:00", "+00:00:01"},
    {-3_661, 0, "-0101", "-01:01", "-01:01:01"},
    {3_661, 0, "+0101", "+01:01", "+01:01:01"},
    {-3_600, 1_800, "-0030", "-00:30", "-00:30:00"},
    {-3_600, 3_601, "+0000", "+00:00", "+00:00:01"},
    {3_600, -3_601, "-0000", "-00:00", "-00:00:01"}
  ]

  test "timezone info renders one total-offset sign with unsigned components" do
    for {utc, std, _basic, _minutes, seconds} <- @offsets do
      info = %Timex.TimezoneInfo{offset_utc: utc, offset_std: std}
      assert Timex.TimezoneInfo.format_offset(info) == seconds
    end
  end

  test "datetime offset directives render one total-offset sign with unsigned components" do
    for {utc, std, basic, minutes, seconds} <- @offsets do
      datetime = %{~U[2022-01-01 00:00:00Z] | utc_offset: utc, std_offset: std}

      assert Timex.format!(datetime, "{Z}") == basic
      assert Timex.format!(datetime, "{Z:}") == minutes
      assert Timex.format!(datetime, "{Z::}") == seconds
      assert Timex.format!(datetime, "%z", :strftime) == basic
      assert Timex.format!(datetime, "%:z", :strftime) == minutes
      assert Timex.format!(datetime, "%::z", :strftime) == seconds
    end
  end
end
