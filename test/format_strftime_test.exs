defmodule DateFormatTest.FormatStrftime do
  use ExUnit.Case, async: true
  use Timex

  @aug182013 Timex.to_datetime({{2013, 8, 18}, {12, 30, 5}})
  @aug180003 Timex.to_datetime({{3, 8, 18}, {12, 30, 5}})
  @jan12015 Timex.to_datetime({{2015, 1, 1}, {0, 0, 0}})
  @jan152015 Timex.to_datetime({{2015, 1, 15}, {0, 0, 0}})
  @dec312012 Timex.to_datetime({{2012, 12, 31}, {0, 0, 0}})

  test "exceptions" do
    date = Timex.to_datetime({2013, 03, 02})

    formatter = Timex.Format.DateTime.Formatters.Strftime

    assert_raise(Timex.Format.FormatError, fn ->
      formatter.format!(date, "%.")
    end)
  end

  test "success! (to hit line 115 in datetime/formatters/strftime.ex)" do
    date = Timex.to_datetime({2013, 03, 02})

    formatter = Timex.Format.DateTime.Formatters.Strftime
    assert "2013-03-02" == formatter.format!(date, "%Y-%m-%d")
  end

  test "error returned when invalid directive is given" do
    date = Timex.to_datetime({2013, 03, 02})

    formatter = Timex.Format.DateTime.Formatters.Strftime

    assert {:error, {:format, "Expected at least one parser to succeed at line 1, column 0."}} ==
             formatter.format(date, "%.")
  end

  test "format %Y" do
    assert {:ok, "2013"} = format(@aug182013, "%Y")
    assert {:ok, "0003"} = format(@aug180003, "%Y")
    assert {:ok, "3"} = format(@aug180003, "%-Y")
    assert {:ok, "0003"} = format(@aug180003, "%0Y")
    assert {:ok, "   3"} = format(@aug180003, "%_Y")
  end

  test "format %y" do
    assert {:ok, "13"} = format(@aug182013, "%y")
    assert {:ok, "3"} = format(@aug180003, "%-y")
    assert {:ok, "03"} = format(@aug180003, "%y")
    assert {:ok, "03"} = format(@aug180003, "%0y")
    assert {:ok, " 3"} = format(@aug180003, "%_y")
  end

  test "format %C" do
    assert {:ok, "20"} = format(@aug182013, "%C")
    assert {:ok, "0"} = format(@aug180003, "%-C")
    assert {:ok, "00"} = format(@aug180003, "%C")
    assert {:ok, "00"} = format(@aug180003, "%0C")
    assert {:ok, " 0"} = format(@aug180003, "%_C")
  end

  test "format %G" do
    assert {:ok, "2013"} = format(@aug182013, "%G")
    assert {:ok, "2015"} = format(@jan12015, "%G")
    assert {:ok, "0003"} = format(@aug180003, "%G")
    assert {:ok, "2015"} = format(@jan12015, "%-G")
    assert {:ok, "3"} = format(@aug180003, "%-G")
    assert {:ok, "2015"} = format(@jan12015, "%0G")
    assert {:ok, "0003"} = format(@aug180003, "%0G")
    assert {:ok, "2015"} = format(@jan12015, "%_G")
    assert {:ok, "   3"} = format(@aug180003, "%_G")
  end

  test "format %g" do
    assert {:ok, "15"} = format(@jan12015, "%g")
    assert {:ok, "03"} = format(@aug180003, "%g")
    assert {:ok, "15"} = format(@jan12015, "%-g")
    assert {:ok, "3"} = format(@aug180003, "%-g")
    assert {:ok, "15"} = format(@jan12015, "%0g")
    assert {:ok, "03"} = format(@aug180003, "%0g")
    assert {:ok, "15"} = format(@jan12015, "%_g")
    assert {:ok, " 3"} = format(@aug180003, "%_g")
  end

  test "format %m" do
    assert {:ok, "08"} = format(@aug180003, "%m")
    assert {:ok, "8"} = format(@aug180003, "%-m")
    assert {:ok, "08"} = format(@aug180003, "%0m")
    assert {:ok, " 8"} = format(@aug180003, "%_m")
  end

  test "format %b" do
    assert {:ok, "Aug"} = format(@aug182013, "%b")
    assert {:ok, "Jan"} = format(@jan12015, "%b")
    assert {:ok, "Aug"} = format(@aug182013, "%0b")
  end

  test "format %B" do
    assert {:ok, "August"} = format(@aug182013, "%B")
    assert {:ok, "January"} = format(@jan12015, "%B")
    assert {:ok, "August"} = format(@aug182013, "%-B")
  end

  test "format %h" do
    assert {:ok, "Jan"} = format(@jan12015, "%h")
    assert {:ok, "Jan"} = format(@jan12015, "%_h")
  end

  test "format %d" do
    assert {:ok, "01"} = format(@jan12015, "%d")
    assert {:ok, "1"} = format(@jan12015, "%-d")
    assert {:ok, "01"} = format(@jan12015, "%d")
    assert {:ok, "01"} = format(@jan12015, "%0d")
    assert {:ok, " 1"} = format(@jan12015, "%_d")
  end

  test "format %e" do
    assert {:ok, " 1"} = format(@jan12015, "%e")
    assert {:ok, "1"} = format(@jan12015, "%-e")
    assert {:ok, "01"} = format(@jan12015, "%0e")
  end

  test "format %j" do
    assert {:ok, "15"} = format(@jan152015, "%-j")
    assert {:ok, "015"} = format(@jan152015, "%j")
    assert {:ok, "015"} = format(@jan152015, "%0j")
    assert {:ok, " 15"} = format(@jan152015, "%_j")
    assert {:ok, "366"} = format(@dec312012, "%j")
    assert {:ok, "001"} = format(@jan12015, "%j")
  end

  test "format %w" do
    assert {:ok, "0"} = format(@aug182013, "%w")
    assert {:ok, "0"} = format(@aug182013, "%0w")
    assert {:ok, "0"} = format(@aug182013, "%_w")
  end

  test "format %u" do
    assert {:ok, "7"} = format(@aug182013, "%u")
    assert {:ok, "7"} = format(@aug182013, "%-u")
  end

  test "format %a" do
    assert {:ok, "Mon"} = format(Timex.to_datetime({2012, 12, 31}), "%a")
    assert {:ok, "Tue"} = format(Timex.to_datetime({2013, 1, 1}), "%a")
    assert {:ok, "Wed"} = format(Timex.to_datetime({2013, 1, 2}), "%a")
    assert {:ok, "Thu"} = format(Timex.to_datetime({2013, 1, 3}), "%a")
    assert {:ok, "Fri"} = format(Timex.to_datetime({2013, 1, 4}), "%a")
    assert {:ok, "Sat"} = format(Timex.to_datetime({2013, 1, 5}), "%a")
    assert {:ok, "Sun"} = format(Timex.to_datetime({2013, 1, 6}), "%a")
    assert {:ok, "Sun"} = format(Timex.to_datetime({2013, 1, 6}), "%0a")
    assert {:ok, "Sun"} = format(Timex.to_datetime({2013, 1, 6}), "%-a")
  end

  test "format %A" do
    assert {:ok, "Monday"} = format(Timex.to_datetime({2012, 12, 31}), "%A")
    assert {:ok, "Tuesday"} = format(Timex.to_datetime({2013, 1, 1}), "%A")
    assert {:ok, "Wednesday"} = format(Timex.to_datetime({2013, 1, 2}), "%A")
    assert {:ok, "Thursday"} = format(Timex.to_datetime({2013, 1, 3}), "%A")
    assert {:ok, "Friday"} = format(Timex.to_datetime({2013, 1, 4}), "%A")
    assert {:ok, "Saturday"} = format(Timex.to_datetime({2013, 1, 5}), "%A")
    assert {:ok, "Sunday"} = format(Timex.to_datetime({2013, 1, 6}), "%A")
    assert {:ok, "Sunday"} = format(Timex.to_datetime({2013, 1, 6}), "%_A")
    assert {:ok, "Sunday"} = format(Timex.to_datetime({2013, 1, 6}), "%0A")
  end

  test "format %V" do
    date = Timex.to_datetime({2007, 11, 19})
    assert {:ok, "47"} = format(date, "%V")
    assert {:ok, "47"} = format(date, "%0V")
    assert {:ok, "47"} = format(date, "%-V")

    date = Timex.to_datetime({2007, 1, 1})
    assert {:ok, "1"} = format(date, "%-V")
    assert {:ok, "01"} = format(date, "%V")
    assert {:ok, "01"} = format(date, "%0V")
    assert {:ok, " 1"} = format(date, "%_V")
  end

  test "format %W" do
    date = Timex.to_datetime({2013, 10, 21})
    assert {:ok, "42"} = format(date, "%W")
    date = Timex.to_datetime({2017, 1, 1})
    assert {:ok, "00"} = format(date, "%W")
    date = Timex.to_datetime({2012, 12, 31})
    assert {:ok, "53"} = format(date, "%W")
    date = Timex.to_datetime({2015, 12, 28})
    assert {:ok, "52"} = format(date, "%W")
    assert {:ok, "52"} = format(date, "%-W")
    date = Timex.to_datetime({2013, 1, 6})
    assert {:ok, "00"} = format(date, "%W")
    assert {:ok, "0"} = format(date, "%-W")
    assert {:ok, " 0"} = format(date, "%_W")
    date = Timex.to_datetime({2013, 1, 7})
    assert {:ok, "01"} = format(date, "%W")
    assert {:ok, "1"} = format(date, "%-W")
  end

  test "format %U" do
    date = Timex.to_datetime({2015, 12, 28})
    assert {:ok, "52"} = format(date, "%U")
    assert {:ok, "52"} = format(date, "%-U")
    date = Timex.to_datetime({2013, 1, 6})
    assert {:ok, "01"} = format(date, "%U")
    assert {:ok, "1"} = format(date, "%-U")
    assert {:ok, " 1"} = format(date, "%_U")
    date = Timex.to_datetime({2013, 1, 7})
    assert {:ok, "01"} = format(date, "%U")
    assert {:ok, "1"} = format(date, "%-U")
  end

  test "various simple date combinations" do
    date = Timex.to_datetime({2013, 8, 18})
    old_date = Timex.to_datetime({3, 8, 8})

    assert {:ok, "2013-8-18"} = format(date, "%Y-%-m-%d")
    assert {:ok, "3/08/08"} = format(old_date, "%-Y/%m/%d")
    assert {:ok, "3/08/08"} = format(old_date, "%-Y/%0m/%0d")
    assert {:ok, "03 8 8"} = format(old_date, "%y%_m%_d")

    assert {:ok, "8 2013 18"} = format(date, "%-m %Y %e")
    assert {:ok, " 8/08/ 3"} = format(old_date, "%_e/%m/%_y")
    assert {:ok, "8"} = format(date, "%-m")
    assert {:ok, "18"} = format(date, "%-d")
  end

  test "format %H" do
    date = Timex.to_datetime({{2013, 8, 18}, {16, 28, 27}})
    date_midnight = Timex.to_datetime({{2013, 8, 18}, {0, 3, 4}})

    assert {:ok, "0"} = format(date_midnight, "%-H")
    assert {:ok, "00"} = format(date_midnight, "%H")
    assert {:ok, "00"} = format(date_midnight, "%0H")
    assert {:ok, " 0"} = format(date_midnight, "%_H")
    assert {:ok, "16"} = format(date, "%H")
  end

  test "format %k" do
    date = Timex.to_datetime({{2013, 8, 18}, {16, 28, 27}})
    date_midnight = Timex.to_datetime({{2013, 8, 18}, {0, 3, 4}})

    assert {:ok, " 0"} = format(date_midnight, "%k")
    assert {:ok, "16"} = format(date, "%k")
  end

  test "format %I" do
    date = Timex.to_datetime({{2013, 8, 18}, {16, 28, 27}})

    assert {:ok, "4"} = format(date, "%-I")
    assert {:ok, "04"} = format(date, "%I")
    assert {:ok, "04"} = format(date, "%0I")
    assert {:ok, "04"} = format(date, "%02I")
    assert {:ok, " 4"} = format(date, "%_2I")
  end

  test "format %l" do
    date = Timex.to_datetime({{2013, 8, 18}, {16, 28, 27}})

    assert {:ok, " 4"} = format(date, "%l")
    assert {:ok, "4"} = format(date, "%-l")
    assert {:ok, " 4"} = format(date, "%l")
  end

  test "format %f" do
    with_us_5 = {{2018, 8, 8}, {9, 24, 0, 12345}}
    with_us_6 = {{2018, 8, 8}, {9, 24, 0, 123_456}}
    without_us = {{2018, 8, 8}, {9, 24, 0}}
    dt_with_5 = Timex.to_datetime(with_us_5)
    dt_with_6 = Timex.to_datetime(with_us_6)
    dt_without = Timex.to_datetime(without_us)
    assert {:ok, "000000"} = format(dt_without, "%f")
    assert {:ok, "012345"} = format(dt_with_5, "%f")
    assert {:ok, "012345"} = format(dt_with_5, "%0f")
    assert {:ok, "123456"} = format(dt_with_6, "%f")
    assert {:ok, "0"} = format(dt_without, "%-f")
    assert {:ok, "12345"} = format(dt_with_5, "%-f")
    assert {:ok, " 12345"} = format(dt_with_5, "%_f")
  end

  test "format %L" do
    with_us_5 = {{2018, 8, 8}, {9, 24, 0, 12345}}
    with_us_6 = {{2018, 8, 8}, {9, 24, 0, 123_456}}
    without_us = {{2018, 8, 8}, {9, 24, 0}}
    dt_with_5 = Timex.to_datetime(with_us_5)
    dt_with_6 = Timex.to_datetime(with_us_6)
    dt_without = Timex.to_datetime(without_us)
    assert {:ok, "000"} = format(dt_without, "%L")
    assert {:ok, "012"} = format(dt_with_5, "%L")
    assert {:ok, "012"} = format(dt_with_5, "%0L")
    assert {:ok, "123"} = format(dt_with_6, "%L")
    assert {:ok, "0"} = format(dt_without, "%-L")
    assert {:ok, "12"} = format(dt_with_5, "%-L")
    assert {:ok, " 12"} = format(dt_with_5, "%_L")
  end

  test "format %L (rounding)" do
    with_us_5 = {{2018, 8, 8}, {9, 24, 0, 12945}}
    with_us_6 = {{2018, 8, 8}, {9, 24, 0, 129_456}}
    without_us = {{2018, 8, 8}, {9, 24, 0}}
    dt_with_5 = Timex.to_datetime(with_us_5)
    dt_with_6 = Timex.to_datetime(with_us_6)
    dt_without = Timex.to_datetime(without_us)
    assert {:ok, "000"} = format(dt_without, "%L")
    assert {:ok, "013"} = format(dt_with_5, "%L")
    assert {:ok, "013"} = format(dt_with_5, "%0L")
    assert {:ok, "129"} = format(dt_with_6, "%L")
    assert {:ok, "0"} = format(dt_without, "%-L")
    assert {:ok, "13"} = format(dt_with_5, "%-L")
    assert {:ok, " 13"} = format(dt_with_5, "%_L")
  end

  test "various time combinations" do
    date = Timex.to_datetime({{2013, 8, 18}, {12, 3, 4}})
    date_midnight = Timex.to_datetime({{2013, 8, 18}, {0, 3, 4}})

    assert {:ok, "12: 3: 4"} = format(date, "%H:%_M:%_S")
    assert {:ok, "12:03:04"} = format(date, "%k:%M:%S")
    assert {:ok, "12:03:04 PM"} = format(date, "%I:%0M:%0S %p")
    assert {:ok, "pm 12:3:4"} = format(date, "%P %l:%-M:%-S")
    assert {:ok, "am 12"} = format(date_midnight, "%P %I")
    assert {:ok, "am 12"} = format(date_midnight, "%P %l")
    assert {:ok, "AM 0"} = format(date_midnight, "%p %-H")
    assert {:ok, "AM 0"} = format(date_midnight, "%p %-k")
    assert {:ok, "AM 00"} = format(date_midnight, "%p %H")
    assert {:ok, "AM  0"} = format(date_midnight, "%p %k")
  end

  test "format %p" do
    date_midnight = Timex.to_datetime({{2013, 8, 18}, {0, 3, 4}})

    assert {:ok, "AM"} = format(date_midnight, "%0p")
    assert {:ok, "am"} = format(date_midnight, "%_P")
  end

  test "format %s" do
    date = Timex.to_datetime({{2013, 8, 18}, {12, 3, 4}})

    assert {:ok, "1376827384"} = format(date, "%s")
    assert {:ok, "1376827384"} = format(date, "%-s")

    assert {:error,
            {:formatter,
             "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}} =
             format(date, "%_s")

    date = Timex.to_datetime({{2001, 9, 9}, {1, 46, 40}})
    assert {:ok, "1000000000"} = format(date, "%s")

    date = Timex.epoch()

    cannot_pad_err =
      {:error,
       {:formatter,
        "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}

    assert {:ok, "0"} = format(date, "%-s")
    assert {:ok, "0"} = format(date, "%s")
    assert ^cannot_pad_err = format(date, "%0s")
    assert ^cannot_pad_err = format(date, "%_s")
  end

  test "format timezones" do
    date = Timex.to_datetime({2007, 11, 19}, "Europe/Athens")
    assert {:ok, "Europe/Athens"} = format(date, "%Z")
    assert {:ok, "+0200"} = format(date, "%z")
    assert {:ok, "+02:00"} = format(date, "%:z")
    assert {:ok, "+02:00:00"} = format(date, "%::z")

    date = Timex.to_datetime({2007, 11, 19}, "America/Los_Angeles")
    assert {:ok, "America/Los_Angeles"} = format(date, "%Z")
    assert {:ok, "-0800"} = format(date, "%z")
    assert {:ok, "-08:00"} = format(date, "%:z")
    assert {:ok, "-08:00:00"} = format(date, "%::z")

    assert {:ok, "America/Los_Angeles"} = format(date, "%0Z")
    assert {:ok, "America/Los_Angeles"} = format(date, "%_Z")
    assert {:ok, "-08:00"} = format(date, "%0:z")

    assert {:error,
            {:formatter,
             "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}} =
             format(date, "%_::z")
  end

  test "format pre-defined directives" do
    date = Timex.to_datetime({{2013, 8, 18}, {16, 28, 27}})
    assert {:ok, "08/18/13"} = format(date, "%D")
    assert {:ok, "2013-08-18"} = format(date, "%F")
    assert {:ok, "16:28"} = format(date, "%R")
    assert {:ok, "04:28:27 PM"} = format(date, "%r")
    assert {:ok, "16:28:27"} = format(date, "%T")

    date = Timex.to_datetime({{2013, 8, 1}, {16, 28, 27}})
    assert {:ok, " 1-Aug-2013"} = format(date, "%v")
  end

  test "supports unicode format strings" do
    date = Timex.to_datetime({{2007, 11, 9}, {8, 37, 48}})
    assert {:ok, "Fri å∫ç∂ {%08…37…48%} ¿Etc/UTC?"} = format(date, "%a å∫ç∂ {%%%H…%M…%S%%} ¿%Z?")
  end

  test "tokenization errors" do
    date = Timex.now()
    assert {:error, {:format, "Format string cannot be empty."}} = format(date, "")

    assert {:error, {:format, "Invalid format string, must contain at least one directive."}} =
             format(date, "abc")

    assert {:error, {:format, "Invalid format string, must contain at least one directive."}} =
             format(date, "Use %% as oft{{en as you like%%")

    assert {:error, {:format, "Invalid format string, must contain at least one directive."}} =
             format(date, "%%%%abc%%")
  end

  test "lau/calendar tests" do
    dt = Timex.to_datetime({{2014, 11, 3}, {1, 41, 2}})
    dt = %{dt | :microsecond => {012_000, 3}}
    dt_sunday = Timex.to_datetime({{2014, 11, 2}, {1, 41, 2}})
    assert format(dt, "%a") == {:ok, "Mon"}
    assert format(dt, "%A") == {:ok, "Monday"}
    assert format(dt, "%b") == {:ok, "Nov"}
    assert format(dt, "%h") == {:ok, "Nov"}
    assert format(dt, "%B") == {:ok, "November"}
    assert format(dt, "%d") == {:ok, "03"}
    assert format(dt, "%e") == {:ok, " 3"}
    assert format(dt, "%f") == {:ok, "012000"}
    assert format(dt, "%u") == {:ok, "1"}
    assert format(dt, "%w") == {:ok, "1"}
    assert format(dt_sunday, "%u") == {:ok, "7"}
    assert format(dt_sunday, "%w") == {:ok, "0"}
    assert format(dt, "%V") == {:ok, "45"}
    assert format(dt, "%G") == {:ok, "2014"}
    assert format(dt, "%g") == {:ok, "14"}
    assert format(dt, "%C") == {:ok, "20"}
    assert format(dt, "%k") == {:ok, " 1"}
    assert format(dt, "%I") == {:ok, "01"}
    assert format(dt, "%l") == {:ok, " 1"}
    assert format(dt, "%P") == {:ok, "am"}
    assert format(dt, "%p") == {:ok, "AM"}
    assert format(dt, "%r") == {:ok, "01:41:02 AM"}
    assert format(dt, "%R") == {:ok, "01:41"}
    assert format(dt, "%T") == {:ok, "01:41:02"}
    assert format(dt, "%F") == {:ok, "2014-11-03"}
    assert format(dt, "%Z") == {:ok, "Etc/UTC"}

    dt = Timex.to_datetime({{2014, 12, 31}, {21, 41, 2}})
    assert format(dt, "%l %P") == {:ok, " 9 pm"}
    assert format(dt, "%I %p") == {:ok, "09 PM"}
    dt = Timex.to_datetime({{2014, 12, 31}, {12, 41, 2}})
    assert format(dt, "%l %P") == {:ok, "12 pm"}
    assert format(dt, "%I %p") == {:ok, "12 PM"}
    dt = Timex.to_datetime({{2014, 12, 31}, {0, 41, 2}})
    assert format(dt, "%l %P") == {:ok, "12 am"}
    assert format(dt, "%I %p") == {:ok, "12 AM"}
    dt = Timex.to_datetime({{2014, 12, 31}, {9, 41, 2}})
    assert format(dt, "%l %P") == {:ok, " 9 am"}
    assert format(dt, "%I %p") == {:ok, "09 AM"}

    dt = Timex.to_datetime({{2014, 12, 31}, {21, 41, 2}})
    assert format(dt, "%j") == {:ok, "365"}
    dt = Timex.to_datetime({{2014, 1, 1}, {21, 41, 2}})
    assert format(dt, "%j") == {:ok, "001"}
    # Leap year
    dt = Timex.to_datetime({{2012, 12, 31}, {21, 41, 2}})
    assert format(dt, "%j") == {:ok, "366"}
  end

  defp format(date, fmt) do
    Timex.format(date, fmt, :strftime)
  end
end
