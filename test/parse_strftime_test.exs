defmodule DateFormatTest.ParseStrftime do
  use ExUnit.Case, async: true
  use Timex

  test "parse datetime" do
    date = Timex.to_datetime({{2014,7,19},{14,20,34}}, "Etc/GMT-7")
    assert {:ok, ^date} = parse("Sat, 19 Jul 2014 14:20:34 +0700", "%a, %d %b %Y %T %z")
  end

  test "issue #215" do
    assert {:ok, _date} = parse("14-Dec-00", "%e-%b-%y")
  end

  test "issue #66" do
    date = Timex.to_datetime({{2015,7,6}, {0,0,0}}, "CST")
    assert {:ok, ^date} = parse("Mon Jul 06 2015 00:00:00 GMT+0200 (CST)", "%a %b %d %Y %H:%M:%S %Z%z (%Z)")

    date2 = Timex.to_datetime({{2015,7,6}, {0,0,0}}, "CST")
    assert {:ok, ^date2} = parse("Mon Jul 06 2015 00:00:00 GMT +0200 (CST)", "%a %b %d %Y %H:%M:%S %Z %z (%Z)")
  end

  test "issue #319 - should parse microseconds even if 0" do
    assert {:ok, %NaiveDateTime{microsecond: {0, 6}}} = parse("2017-06-15T12:42:20.000000", "%FT%T.%f")
  end

  test "parse format with microseconds" do
    date = Timex.to_naive_datetime({{2015,7,13}, {14,1,21}})
    date = %{date | :microsecond => {53021, 6}}
    assert {:ok, ^date} = parse("20150713 14:01:21.053021", "%Y%m%d %H:%M:%S.%f")

    assert {:ok, ~N[2017-04-05 15:34:37.348]} = parse("2017-04-05 15:34:37.348", "%Y-%m-%d %H:%M:%S.%f")
  end

  test "parse format with milliseconds" do
    date = Timex.to_naive_datetime({{2015,7,13}, {14,1,21}})
    date = %{date | :microsecond => {38000,3}}
    assert {:ok, ^date} = parse("20150713 14:01:21.038", "%Y%m%d %H:%M:%S.%L")
  end

  defp parse(date, fmt) do
    Timex.parse(date, fmt, :strftime)
  end
end
