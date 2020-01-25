defmodule DateFormatTest.GeneralFormatting do
  use ExUnit.Case, async: true
  use Timex

  test "from_now/1" do
    ref_date = Timex.to_datetime({{2016, 2, 8}, {12, 0, 0}})
    utc_date = Timex.to_datetime({{2016, 2, 8}, {12, 0, 1}})
    cst_date = Timex.Timezone.convert(utc_date, "America/Chicago")
    assert Timex.from_now(utc_date, ref_date) == Timex.from_now(cst_date, ref_date)
  end

  test "converts maps and tuples before formatting" do
    map = %{day: 9, hour: 15, min: 40, month: 7, sec: 33, usec: 0, year: 2017}
    tuple = {{2017, 7, 9}, {15, 40, 33}} = Timex.to_erl(map)
    assert "15:40:33" == Timex.format!(map, "{h24}:{m}:{s}")
    assert "15:40:33" == Timex.format!(tuple, "{h24}:{m}:{s}")
  end

  test "issue #358 - formatting a Time returns wrong result" do
    time = ~T[17:00:00]
    assert "17:00:00" == Timex.format!(time, "{h24}:{m}:{s}")
  end

  test "fractional seconds padding obeys formatting rules" do
    t = Timex.parse!("2017-06-28 20:21:22.012345", "%F %T.%f", :strftime)
    assert {12345, 6} = t.microsecond
    assert "012345" = Timex.format!(t, "%f", :strftime)
    assert "12345" = Timex.format!(t, "%03f", :strftime)

    t = Timex.to_datetime({2017, 6, 22})
    assert {0, 0} = t.microsecond
    assert "000000" = Timex.format!(t, "%f", :strftime)
    assert "000" = Timex.format!(t, "%03f", :strftime)
  end

  test "issue #402 - formatting a Time sometimes crashes for timezones" do
    assert Timex.to_datetime({{2016, 2, 8}, {12, 0, 0}})
           |> Timex.Timezone.convert("Canada/Newfoundland")
           |> Timex.format!("{ISO:Extended}") == "2016-02-08T08:30:00-03:30"

    assert Timex.to_datetime({{2016, 2, 8}, {12, 0, 0}})
           |> Timex.Timezone.convert("Pacific/Marquesas")
           |> Timex.format!("{ISO:Extended}") == "2016-02-08T02:30:00-09:30"
  end

  test "format wrong date" do
    assert_raise ArgumentError, "invalid_date", fn ->
      Timex.format!("", "{M}")
    end

    assert Timex.format("", "{M}") == {:error, "invalid_date"}
  end
end
