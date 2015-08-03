defmodule DateFormatTest.FormatStrftime do
  use ExUnit.Case, async: true
  use Timex

  @date2013 Date.from({{2013,8,18}, {12,30,5}})
  @date0003 Date.from({{3,8,18}, {12,30,5}})
  @jan12015 Date.from({{2015,1,1}, {0,0,0}})
  @jan152015 Date.from({{2015,1,15}, {0,0,0}})
  @dec312015 Date.from({{2015,12,31}, {0,0,0}})

  test "format %Y" do
    assert { :ok, "2013" } = format(@date2013, "%Y")
    assert { :ok, "0003" } = format(@date0003, "%Y")
    assert { :ok, "3" }    = format(@date0003, "%-Y")
    assert { :ok, "0003" } = format(@date0003, "%0Y")
    assert { :ok, "   3" } = format(@date0003, "%_Y")
  end

  test "format %y" do
    assert { :ok, "13" }   = format(@date2013, "%y")
    assert { :ok, "3" }    = format(@date0003, "%-y")
    assert { :ok, "03" }   = format(@date0003, "%y")
    assert { :ok, "03" }   = format(@date0003, "%0y")
    assert { :ok, " 3" }   = format(@date0003, "%_y")
  end

  test "format %C" do
    assert { :ok, "20" }   = format(@date2013, "%C")
    assert { :ok, "0" }    = format(@date0003, "%-C")
    assert { :ok, "00" }   = format(@date0003, "%C")
    assert { :ok, "00" }   = format(@date0003, "%0C")
    assert { :ok, " 0" }   = format(@date0003, "%_C")
  end

  test "format %G" do
    assert { :ok, "2013" } = format(@date2013, "%G")
    assert { :ok, "2015" } = format(@jan12015, "%G")
    assert { :ok, "0003" } = format(@date0003, "%G")
    assert { :ok, "2015" } = format(@jan12015, "%-G")
    assert { :ok, "3" }    = format(@date0003, "%-G")
    assert { :ok, "2015" } = format(@jan12015, "%0G")
    assert { :ok, "0003" } = format(@date0003, "%0G")
    assert { :ok, "2015" } = format(@jan12015, "%_G")
    assert { :ok, "   3" } = format(@date0003, "%_G")
  end

  test "format %g" do
    assert { :ok, "15" }   = format(@jan12015, "%g")
    assert { :ok, "03" }   = format(@date0003, "%g")
    assert { :ok, "15" }   = format(@jan12015, "%-g")
    assert { :ok, "3" }    = format(@date0003, "%-g")
    assert { :ok, "15" }   = format(@jan12015, "%0g")
    assert { :ok, "03" }   = format(@date0003, "%0g")
    assert { :ok, "15" }   = format(@jan12015, "%_g")
    assert { :ok, " 3" }   = format(@date0003, "%_g")
  end

  test "format %m" do
    assert { :ok, "08" } = format(@date0003, "%m")
    assert { :ok, "8" }  = format(@date0003, "%-m")
    assert { :ok, "08" } = format(@date0003, "%0m")
    assert { :ok, " 8" } = format(@date0003, "%_m")
  end

  test "format %b" do
    assert { :ok, "Aug" } = format(@date2013, "%b")
    assert { :ok, "Jan" } = format(@jan12015, "%b")
    assert { :ok, "Aug" } = format(@date2013, "%0b")
  end

  test "format %B" do
    assert { :ok, "August" }  = format(@date2013, "%B")
    assert { :ok, "January" } = format(@jan12015, "%B")
    assert { :ok, "August" }  = format(@date2013, "%-B")
  end

  test "format %h" do
    assert { :ok, "Jan" } = format(@jan12015, "%h")
    assert { :ok, "Jan" } = format(@jan12015, "%_h")
  end

  test "format %d" do
    assert { :ok, "18" } = format(@date2013, "%d")
    assert { :ok, "8" }  = format(@date0003, "%-d")
    assert { :ok, "08" } = format(@date0003, "%d")
    assert { :ok, "08" } = format(@date0003, "%0d")
    assert { :ok, " 8" } = format(@date0003, "%_d")
  end

  test "format %e" do
    assert { :ok, "18" } = format(@date2013, "%e")
    assert { :ok, " 8" } = format(@date0003, "%e")
    assert { :ok, "08" } = format(@date0003, "%0e")
  end

  test "format %j" do
    assert { :ok, "15" }  = format(@jan152015, "%-j")
    assert { :ok, "015" } = format(@jan152015, "%j")
    assert { :ok, "015" } = format(@jan152015, "%0j")
    assert { :ok, " 15" } = format(@jan152015, "%_j")
    assert { :ok, "366" } = format(@dec312015, "%j")
    assert { :ok, "001" } = format(@jan12015, "%j")
  end

  test "format %w" do
    assert { :ok, "7" } = format(@date2013, "%w")
    assert { :ok, "7" } = format(@date2013, "%0w")
    assert { :ok, "7" } = format(@date2013, "%_w")
  end

  test "format %u" do
    assert { :ok, "1" } = format(@date2013, "%u")
    assert { :ok, "1" } = format(@date2013, "%-u")
  end

  test "format %a" do
    assert { :ok, "Mon" } = format(Date.from({2012,12,31}), "%a")
    assert { :ok, "Tue" } = format(Date.from({2013,1,1}), "%a")
    assert { :ok, "Wed" } = format(Date.from({2013,1,2}), "%a")
    assert { :ok, "Thu" } = format(Date.from({2013,1,3}), "%a")
    assert { :ok, "Fri" } = format(Date.from({2013,1,4}), "%a")
    assert { :ok, "Sat" } = format(Date.from({2013,1,5}), "%a")
    assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "%a")
    assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "%0a")
    assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "%-a")
  end

  test "format %A" do
    assert { :ok, "Monday" }    = format(Date.from({2012,12,31}), "%A")
    assert { :ok, "Tuesday" }   = format(Date.from({2013,1,1}), "%A")
    assert { :ok, "Wednesday" } = format(Date.from({2013,1,2}), "%A")
    assert { :ok, "Thursday" }  = format(Date.from({2013,1,3}), "%A")
    assert { :ok, "Friday" }    = format(Date.from({2013,1,4}), "%A")
    assert { :ok, "Saturday" }  = format(Date.from({2013,1,5}), "%A")
    assert { :ok, "Sunday" }    = format(Date.from({2013,1,6}), "%A")
    assert { :ok, "Sunday" } = format(Date.from({2013,1,6}), "%_A")
    assert { :ok, "Sunday" } = format(Date.from({2013,1,6}), "%0A")
  end

  test "format %V" do
    date = Date.from({2007,11,19})
    assert { :ok, "47" } = format(date, "%V")
    assert { :ok, "47" } = format(date, "%0V")
    assert { :ok, "47" } = format(date, "%-V")

    date = Date.from({2007,1,1})
    assert { :ok, "1" }  = format(date, "%-V")
    assert { :ok, "01" } = format(date, "%V")
    assert { :ok, "01" } = format(date, "%0V")
    assert { :ok, " 1" } = format(date, "%_V")
  end

  test "format %W" do
    date = Date.from({2015,12,28})
    assert { :ok, "53" } = format(date, "%W")
    assert { :ok, "53" } = format(date, "%-W")
    date = Date.from({2013,1,6})
    assert { :ok, "01" } = format(date, "%W")
    assert { :ok, "1" } = format(date, "%-W")
    assert { :ok, " 1" } = format(date, "%_W")
    date = Date.from({2013,1,7})
    assert { :ok, "02" } = format(date, "%W")
    assert { :ok, "2" } = format(date, "%-W")
  end

  test "format %U" do
    date = Date.from({2015,12,28})
    assert { :ok, "52" } = format(date, "%U")
    assert { :ok, "52" } = format(date, "%-U")
    date = Date.from({2013,1,6})
    assert { :ok, "02" } = format(date, "%U")
    assert { :ok, "2" } = format(date, "%-U")
    assert { :ok, " 2" } = format(date, "%_U")
    date = Date.from({2013,1,7})
    assert { :ok, "02" } = format(date, "%U")
    assert { :ok, "2" } = format(date, "%-U")
  end

  test "various simple date combinations" do
    date = Date.from({2013,8,18})
    old_date = Date.from({3,8,8})

    assert { :ok, "2013-8-18" } = format(date, "%Y-%-m-%d")
    assert { :ok, "3/08/08" } = format(old_date, "%-Y/%m/%d")
    assert { :ok, "3/08/08" } = format(old_date, "%-Y/%0m/%0d")
    assert { :ok, "03 8 8" } = format(old_date, "%y%_m%_d")

    assert { :ok, "8 2013 18" } = format(date, "%-m %Y %e")
    assert { :ok, " 8/08/ 3" } = format(old_date, "%_e/%m/%_y")
    assert { :ok, "8" } = format(date, "%-m")
    assert { :ok, "18" } = format(date, "%-d")
  end

  test "format %H" do
    date = Date.from({{2013,8,18}, {16,28,27}})
    date_midnight = Date.from({{2013,8,18}, {0,3,4}})

    assert { :ok, "0" }  = format(date_midnight, "%-H")
    assert { :ok, "00" } = format(date_midnight, "%H")
    assert { :ok, "00" } = format(date_midnight, "%0H")
    assert { :ok, " 0" } = format(date_midnight, "%_H")
    assert { :ok, "16" } = format(date, "%H")
  end

  test "format %k" do
    date = Date.from({{2013,8,18}, {16,28,27}})
    date_midnight = Date.from({{2013,8,18}, {0,3,4}})

    assert { :ok, " 0" } = format(date_midnight, "%k")
    assert { :ok, "16" } = format(date, "%k")
  end

  test "format %I" do
    date = Date.from({{2013,8,18}, {16,28,27}})

    assert { :ok, "4" }  = format(date, "%-I")
    assert { :ok, "04" } = format(date, "%I")
    assert { :ok, "4" }  = format(date, "%-I")
    assert { :ok, "04" } = format(date, "%I")
    assert { :ok, "04" } = format(date, "%0I")
    assert { :ok, " 4" } = format(date, "%_I")
  end

  test "format %l" do
    date = Date.from({{2013,8,18}, {16,28,27}})

    assert { :ok, " 4" } = format(date, "%l")
    assert { :ok, "4" }  = format(date, "%-l")
    assert { :ok, " 4" } = format(date, "%l")
  end

  test "various time combinations" do
    date = Date.from({{2013,8,18}, {12,3,4}})
    date_midnight = Date.from({{2013,8,18}, {0,3,4}})

    assert { :ok, "12: 3: 4" } = format(date, "%H:%_M:%_S")
    assert { :ok, "12:03:04" } = format(date, "%k:%M:%S")
    assert { :ok, "12:03:04 PM" } = format(date, "%I:%0M:%0S %p")
    assert { :ok, "pm 12:3:4" } = format(date, "%P %l:%-M:%-S")
    assert { :ok, "am 12" } = format(date_midnight, "%P %I")
    assert { :ok, "am 12" } = format(date_midnight, "%P %l")
    assert { :ok, "AM 0" } = format(date_midnight, "%p %-H")
    assert { :ok, "AM 0" } = format(date_midnight, "%p %-k")
    assert { :ok, "AM 00" } = format(date_midnight, "%p %H")
    assert { :ok, "AM  0" } = format(date_midnight, "%p %k")
  end

  test "format %p" do
    date_midnight = Date.from({{2013,8,18}, {0,3,4}})

    assert { :ok, "AM" } = format(date_midnight, "%0p")
    assert { :ok, "am" } = format(date_midnight, "%_P")
  end

  test "format %s" do
    date = Date.from({{2013,8,18}, {12,3,4}})

    assert { :ok, "1376827384" }  = format(date, "%s")
    assert { :ok, "1376827384" }  = format(date, "%-s")
    assert {:error,
            {:formatter,
             "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}  = format(date, "%_s")

    date = Date.from({{2001,9,9},{1,46,40}})
    assert { :ok, "1000000000" } = format(date, "%s")

    date = Date.epoch()
    cannot_pad_err = {:error, {:formatter, "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}
    assert { :ok, "0" }  = format(date, "%-s")
    assert { :ok, "0" }  = format(date, "%s")
    assert ^cannot_pad_err = format(date, "%0s")
    assert ^cannot_pad_err  = format(date, "%_s")
  end

  test "format timezones" do
    date = Date.from({2007,11,19}, "Europe/Athens")
    assert { :ok, "EET" } = format(date, "%Z")
    assert { :ok, "+0200" } = format(date, "%z")
    assert { :ok, "+02:00" } = format(date, "%:z")
    assert { :ok, "+02:00:00" } = format(date, "%::z")

    date = Date.from({2007,11,19}, "America/Los_Angeles")
    assert { :ok, "PST" } = format(date, "%Z")
    assert { :ok, "-0800" } = format(date, "%z")
    assert { :ok, "-08:00" } = format(date, "%:z")
    assert { :ok, "-08:00:00" } = format(date, "%::z")

    assert { :ok, "PST" } = format(date, "%0Z")
    assert { :ok, "PST" } = format(date, "%_Z")
    assert { :ok, "-08:00"} = format(date, "%0:z")
    assert {:error, {:formatter, "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}} = format(date, "%_::z")
  end

  test "format pre-defined directives" do
    date = Date.from({{2013,8,18}, {16,28,27}})
    assert { :ok, "08/18/13" }    = format(date, "%D")
    assert { :ok, "2013-08-18" }  = format(date, "%F")
    assert { :ok, "16:28" }       = format(date, "%R")
    assert { :ok, "04:28:27 PM" } = format(date, "%r")
    assert { :ok, "16:28:27" }    = format(date, "%T")

    date = Date.from({{2013,8,1}, {16,28,27}})
    assert { :ok, " 1-Aug-2013" } = format(date, "%v")
  end

  test "supports unicode format strings" do
    date = Date.from({{2007,11,9}, {8,37,48}})
    assert { :ok, "Fri å∫ç∂ {%08…37…48%} ¿UTC?" } = format(date, "%a å∫ç∂ {%%%H…%M…%S%%} ¿%Z?")
  end

  test "tokenization errors" do
    date = Date.now()
    assert {:error, {:format, "Format string cannot be empty."}} = format(date, "")
    assert {:error, {:format, "Invalid format string, must contain at least one directive."}} = format(date, "abc")
    assert {:error, {:format, "Invalid format string, must contain at least one directive."}} = format(date, "Use %% as oft{{en as you like%%")
    assert {:error, {:format, "Invalid format string, must contain at least one directive."}} = format(date, "%%%%abc%%")
  end

  defp format(date, fmt) do
    DateFormat.format(date, fmt, :strftime)
  end
end
