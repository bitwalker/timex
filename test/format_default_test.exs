defmodule DateFormatTest.FormatDefault do
  use ExUnit.Case, async: true
  use Timex

  alias Timex.Format.DateTime.Formatters.Default

  test "format year" do
    date = Date.from({2013,8,18})
    old_date = Date.from({3,8,18})

    assert { :ok, "2013" } = format(date, "{YYYY}")
    assert { :ok, "13" }   = format(date, "{YY}")
    assert { :ok, "3" }    = format(old_date, "{YYYY}")
    assert { :ok, "0003" } = format(old_date, "{0YYYY}")
    assert { :ok, "   3" } = format(old_date, "{_YYYY}")
    assert { :ok, "3" }    = format(old_date, "{YY}")
    assert { :ok, "03" }   = format(old_date, "{0YY}")
    assert { :ok, " 3" }   = format(old_date, "{_YY}")
  end

  test "format century" do
    date = Date.from({2013,8,18})
    old_date = Date.from({3,8,18})

    assert { :ok, "20" }   = format(date, "{C}")
    assert { :ok, "0" }    = format(old_date, "{C}")
    assert { :ok, "00" }   = format(old_date, "{0C}")
    assert { :ok, " 0" }   = format(old_date, "{_C}")
  end

  test "format ISO year" do
    date = Date.from({2007,11,19})
    assert { :ok, "2007" } = format(date, "{WYYYY}")
    assert { :ok, "7" }    = format(date, "{WYY}")
    assert { :ok, "07" }   = format(date, "{0WYY}")
    assert { :ok, " 7" }   = format(date, "{_WYY}")

    date = Date.from({2006,1,1})
    assert { :ok, "2005" } = format(date, "{WYYYY}")
    assert { :ok, "5" }    = format(date, "{WYY}")
    assert { :ok, "05" }   = format(date, "{0WYY}")
    assert { :ok, " 5" }   = format(date, "{_WYY}")
  end

  test "format month" do
    date = Date.from({3,3,8})
    assert { :ok, "3" }  = format(date, "{M}")
    assert { :ok, "03" } = format(date, "{0M}")
    assert { :ok, " 3" } = format(date, "{_M}")
  end

  test "format full/abbreviated month name" do
    date = Date.from({2013,11,18})
    old_date = Date.from({3,3,8})

    assert { :ok, "Nov" }      = format(date, "{Mshort}")
    assert { :ok, "November" } = format(date, "{Mfull}")
    assert { :ok, "Mar" }      = format(old_date, "{Mshort}")
    assert { :ok, "March" }    = format(old_date, "{Mfull}")

    assert { :ok, "November" } = format(date, "{0Mfull}")
    assert { :ok, " Mar" } = format(old_date, " {_Mshort}")
  end

  test "format day of month" do
    date = Date.from({2013,8,18})
    old_date = Date.from({3,8,8})

    assert { :ok, "18" } = format(date, "{D}")
    assert { :ok, "18" } = format(date, "{0D}")
    assert { :ok, "18" } = format(date, "{_D}")
    assert { :ok, "8" }  = format(old_date, "{D}")
    assert { :ok, "08" } = format(old_date, "{0D}")
    assert { :ok, " 8" } = format(old_date, "{_D}")
  end

  test "format day of year" do
    date = Date.from({3,2,1})

    assert { :ok, "32" }  = format(date, "{Dord}")
    assert { :ok, "032" } = format(date, "{0Dord}")
    assert { :ok, " 32" } = format(date, "{_Dord}")

    date = Date.from({3,12,31})
    assert { :ok, "365" } = format(date, "{Dord}")

    date = Date.from({3,1,1})
    assert { :ok, "001" } = format(date, "{0Dord}")
  end

  test "format day of week" do
    date = Date.from({2007,11,18})
    assert { :ok, "6" } = format(date, "{WDsun}")
    assert { :ok, "7" } = format(date, "{WDmon}")
    assert { :ok, "6" } = format(date, "{0WDsun}")
    assert { :ok, "7" } = format(date, "{0WDmon}")
    assert { :ok, "6" } = format(date, "{_WDsun}")
    assert { :ok, "7" } = format(date, "{_WDmon}")
  end

  test "format full/abbreviated weekday name" do
    assert { :ok, "Mon" } = format(Date.from({2012,12,31}), "{WDshort}")
    assert { :ok, "Tue" } = format(Date.from({2013,1,1}), "{WDshort}")
    assert { :ok, "Wed" } = format(Date.from({2013,1,2}), "{WDshort}")
    assert { :ok, "Thu" } = format(Date.from({2013,1,3}), "{WDshort}")
    assert { :ok, "Fri" } = format(Date.from({2013,1,4}), "{WDshort}")
    assert { :ok, "Sat" } = format(Date.from({2013,1,5}), "{WDshort}")
    assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "{WDshort}")
    assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "{0WDshort}")
    assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "{_WDshort}")

    assert { :ok, "Monday" }    = format(Date.from({2012,12,31}), "{WDfull}")
    assert { :ok, "Tuesday" }   = format(Date.from({2013,1,1}), "{WDfull}")
    assert { :ok, "Wednesday" } = format(Date.from({2013,1,2}), "{WDfull}")
    assert { :ok, "Thursday" }  = format(Date.from({2013,1,3}), "{WDfull}")
    assert { :ok, "Friday" }    = format(Date.from({2013,1,4}), "{WDfull}")
    assert { :ok, "Saturday" }  = format(Date.from({2013,1,5}), "{WDfull}")
    assert { :ok, "Sunday" }    = format(Date.from({2013,1,6}), "{WDfull}")
    assert { :ok, "Sunday" } = format(Date.from({2013,1,6}), "{0WDfull}")
    assert { :ok, "Sunday" } = format(Date.from({2013,1,6}), "{_WDfull}")
  end

  test "format ISO week" do
    date = Date.from({2007,11,19})
    assert { :ok, "47" } = format(date, "{Wiso}")
    assert { :ok, "47" } = format(date, "{0Wiso}")
    assert { :ok, "47" } = format(date, "{_Wiso}")

    date = Date.from({2007,1,1})
    assert { :ok, "01" }  = format(date, "{Wiso}")
    assert { :ok, "01" } = format(date, "{0Wiso}")
    assert { :ok, " 1" } = format(date, "{_Wiso}")
  end

  test "format week number" do
    date = Date.from({2013,1,1})
    assert { :ok, "1" } = format(date, "{Wmon}")
    assert { :ok, "1" } = format(date, "{Wsun}")

    date = Date.from({2013,1,6})
    assert { :ok, "01" } = format(date, "{0Wmon}")
    assert { :ok, "02" } = format(date, "{0Wsun}")

    date = Date.from({2013,1,7})
    assert { :ok, " 2" } = format(date, "{_Wmon}")
    assert { :ok, " 2" } = format(date, "{_Wsun}")

    date = Date.from({2012,1,1})
    assert { :ok, "52" } = format(date, "{Wmon}") # Is actually part of previous year
    assert { :ok, "1" } = format(date, "{Wsun}")

    date = Date.from({2012,1,2})
    assert { :ok, "1" } = format(date, "{Wmon}")
    assert { :ok, "1" } = format(date, "{Wsun}")

    date = Date.from({2012,12,30})
    assert { :ok, "52" } = format(date, "{Wmon}")
    assert { :ok, "1" } = format(date, "{Wsun}")
  end

  test "format simple compound date formats" do
    date = Date.from({2013,8,18})
    old_date = Date.from({3,8,8})

    assert { :ok, "2013-8-18" } = format(date, "{YYYY}-{M}-{D}")
    assert { :ok, "3/08/08" } = format(old_date, "{YYYY}/{0M}/{0D}")
    assert { :ok, "03 8 8" } = format(old_date, "{0YY}{_M}{_D}")

    assert { :ok, "8 2013 18" } = format(date, "{M} {YYYY} {D}")
    assert { :ok, " 8/08/ 3" } = format(old_date, "{_D}/{0M}/{_YY}")
    assert { :ok, "8" } = format(date, "{M}")
    assert { :ok, "18" } = format(date, "{D}")
  end

  test "format time" do
    date = Date.from({{2013,8,18}, {16,28,27}})
    date_midnight = Date.from({{2013,8,18}, {0,3,4}})

    assert { :ok, "0" }  = format(date_midnight, "{h24}")
    assert { :ok, "00" } = format(date_midnight, "{0h24}")
    assert { :ok, " 0" } = format(date_midnight, "{_h24}")

    assert { :ok, "4" }  = format(date, "{h12}")
    assert { :ok, "04" } = format(date, "{0h12}")
    assert { :ok, " 4" } = format(date, "{_h12}")

    date = Date.from({{2013,8,18}, {12,3,4}})
    assert { :ok, "12: 3: 4" }    = format(date, "{h24}:{_m}:{_s}")
    assert { :ok, "12:03:04" }    = format(date, "{h12}:{0m}:{0s}")
    assert { :ok, "12:03:04 PM" } = format(date, "{h12}:{0m}:{0s} {AM}")
    assert { :ok, "pm 12:03:04" }   = format(date, "{am} {h24}:{m}:{s}")
    assert { :ok, "am 12" }       = format(date_midnight, "{am} {h12}")
    assert { :ok, "AM 00" }       = format(date_midnight, "{AM} {0h24}")

    assert { :ok, "am" } = format(date_midnight, "{0am}")
    assert { :ok, "AM" } = format(date_midnight, "{_AM}")
  end

  test "format seconds since epoch" do
    date = Date.from({{2013,8,18}, {12,3,4}})
    invalid_flag_err = {:error, {:formatter, "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}
    assert { :ok, "1376827384" }  = format(date, "{s-epoch}")
    assert ^invalid_flag_err = format(date, "{0s-epoch}")
    assert ^invalid_flag_err = format(date, "{_s-epoch}")

    date = Date.from({{2001,9,9},{1,46,40}})
    assert { :ok, "1000000000" } = format(date, "{s-epoch}")

    date = Date.epoch()
    assert { :ok, "0" }   = format(date, "{s-epoch}")
    assert ^invalid_flag_err = format(date, "{0s-epoch}")
    assert ^invalid_flag_err = format(date, "{_s-epoch}")
  end

  test "format timezone name/offset" do
    date = Date.from({2007,11,19}, "Europe/Athens")
    assert { :ok, "EET" } = format(date, "{Zname}")
    assert { :ok, "+0200" } = format(date, "{Z}")
    assert { :ok, "+02:00" } = format(date, "{Z:}")
    assert { :ok, "+02:00:00" } = format(date, "{Z::}")

    date = Date.from({2007,11,19}, "America/New_York")
    assert { :ok, "EST" } = format(date, "{Zname}")
    assert { :ok, "-0500" } = format(date, "{Z}")
    assert { :ok, "-05:00" } = format(date, "{Z:}")
    assert { :ok, "-05:00:00" } = format(date, "{Z::}")

    assert { :ok, "EST" } = format(date, "{0Zname}")
    assert {:error,
            {:formatter,
             "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}} = format(date, "{_Z}")
    assert { :ok, "-05:00" } = format(date, "{0Z:}")
    assert {:error,
            {:formatter,
             "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}} = format(date, "{_Z::}")
  end

  test "format ISO8601" do
    date = Date.from({{2013,3,5},{23,25,19}}, "Europe/Athens")
    assert { :ok, "2013-03-05T23:25:19+0200" } = format(date, "{ISO}")
    assert { :ok, "2013-03-05T21:25:19Z" }     = format(date, "{ISOz}")

    local = {{2013,3,5},{23,25,19}}
    assert { :ok, "2013-03-05T23:25:19-0800" } = format(Date.from(local, "America/Los_Angeles"), "{ISO}")
    assert { :ok, "2013-03-05T23:25:19+0000" } = format(Date.from(local, :utc), "{ISO}")
  end

  test "format ISO date" do
    date = Date.from({{2007,11,19}, {1,37,48}}, "Europe/Athens")

    assert { :ok, "2007-11-19" } = format(date, "{ISOdate}")
    assert { :ok, "20071119" }   = format(date, "{0YYYY}{0M}{0D}")
    assert { :ok, "0007-01-02" } = format(Date.from({7,1,2}), "{ISOdate}")
  end

  test "format ISO time" do
    date = Date.from({{2007,11,19}, {1,37,48}}, "Europe/Athens")

    assert { :ok, "01:37:48" } = format(date, "{ISOtime}")
    assert { :ok, "01:37:48" } = format(date, "{0h24}:{0m}:{0s}")
    assert { :ok, "23:03:09" } = format(Date.from({{1,2,3},{23,3,9}}), "{ISOtime}")
    assert { :ok, "23:03:09" } = format(Date.from({{1,2,3},{23,3,9}}), "{0h24}:{0m}:{0s}")
  end

  test "format ISOweek" do
    date = Date.from({{2007,11,19}, {1,37,48}}, "Europe/Athens")

    assert { :ok, "2007-W47" }   = format(date, "{ISOweek}")
    assert { :ok, "2007-W47-1" } = format(date, "{ISOweek}-{WDmon}")
    assert { :ok, "2007-W47-1" } = format(date, "{ISOweek-day}")
    assert { :ok, "2007W471" }   = format(date, "{0WYYYY}W{0Wiso}{WDmon}")
  end

  test "format ISO day of year" do
    date = Date.from({{2007,11,19}, {1,37,48}}, "Europe/Athens")

    assert { :ok, "2007-323" }   = format(date, "{ISOord}")
    assert { :ok, "2007-323" }   = format(date, "{0YYYY}-{0Dord}")
  end

  test "format RFC1123" do
    date = Date.from({{2013,3,5},{23,25,19}})
    assert { :ok, "Tue, 05 Mar 2013 23:25:19 +0000" } = format(date, "{RFC1123}")
    assert {:ok, "Tue, 05 Mar 2013 23:25:19 Z"} = format(date, "{RFC1123z}")

    date = Date.from({{2013,3,5},{23,25,19}}, "Europe/Athens")
    assert { :ok, "Tue, 05 Mar 2013 23:25:19 +0200" } = format(date, "{RFC1123}")
    assert { :ok, "Tue, 05 Mar 2013 21:25:19 Z" } = format(date, "{RFC1123z}")

    date = Date.from({{2013,3,5},{23,25,19}}, "America/Los_Angeles")
    assert { :ok, "Tue, 05 Mar 2013 23:25:19 -0800" } = format(date, "{RFC1123}")
    assert { :ok, "Wed, 06 Mar 2013 07:25:19 Z" } = format(date, "{RFC1123z}")
  end

  test "format RFC3339" do
    local = {{2013,3,5},{23,25,19}}
    date = Date.from(local)

    assert { :ok, "2013-03-05T23:25:19Z" } = format(date, "{RFC3339z}")

    assert { :ok, "2013-03-05T23:25:19+02:00" } = format(Date.from(local, "Europe/Athens"), "{RFC3339}")
    assert { :ok, "2013-03-05T23:25:19-08:00" } = format(Date.from(local, "America/Los_Angeles"), "{RFC3339}")
  end

  test "format ANSIC" do
    local = {{2013,3,5},{23,25,19}}
    date = Date.from(local, :utc)

    assert { :ok, "Tue Mar  5 23:25:19 2013" } = format(date, "{ANSIC}")
  end

  test "format UNIX" do
    local = {{2013,3,5},{23,25,19}}
    date = Date.from(local, :utc)

    assert { :ok, "Tue Mar  5 23:25:19 UTC 2013" } = format(date, "{UNIX}")
    assert { :ok, "Tue Mar  5 23:25:19 PST 2013" } = format(Date.from(local, "America/Los_Angeles"), "{UNIX}")
  end

  test "format kitchen" do
    date = Date.from({{2013,3,5},{15,25,19}})
    assert { :ok, "3:25PM" } = DateFormat.format(date, "{kitchen}")
  end

  # References:
  # http://www.ruby-doc.org/core-2.0/Time.html#method-i-strftime
  # http://golang.org/pkg/time/#pkg-constants
  test "can properly format various complex compound formats" do
    date = Date.from({{2007,11,19}, {8,37,48}}, "Etc/GMT-6")

    assert { :ok, "083748+0600" } = format(date, "{0h24}{0m}{0s}{Z}")
    assert { :ok, "08:37:48+06:00" } = format(date, "{0h24}:{0m}:{0s}{Z:}")
    assert { :ok, "20071119T083748+0600" } = format(date, "{YYYY}{M}{D}T{0h24}{m}{s}{Z}")
    assert { :ok, "2007-11-19T08:37:48+06:00" } = format(date, "{YYYY}-{M}-{D}T{0h24}:{m}:{s}{Z:}")
    assert { :ok, "2007323T083748+0600" } = format(date, "{YYYY}{Dord}T{0h24}{m}{s}{Z}")
    assert { :ok, "2007-323T08:37:48+06:00" } = format(date, "{YYYY}-{Dord}T{0h24}:{m}:{s}{Z:}")
    assert { :ok, "2007W471T083748+0600" } = format(date, "{WYYYY}W{Wiso}{WDmon}T{0h24}{m}{s}{Z}")
    assert { :ok, "2007-W47-1T08:37:48+06:00" } = format(date, "{WYYYY}-W{Wiso}-{WDmon}T{0h24}:{m}:{s}{Z:}")

    date = Date.from({{2007,11,9}, {8,37,48}}, "America/Denver")

    assert { :ok, "20071109T0837" } = format(date, "{YYYY}{M}{0D}T{0h24}{m}")
    assert { :ok, "2007-11-09T08:37" } = format(date, "{YYYY}-{M}-{0D}T{0h24}:{m}")

    assert { :ok, "Fri Nov  9 08:37:48 2007" } = format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {YYYY}")
    assert { :ok, "Fri Nov  9 08:37:48 MST 2007" } = format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {Zname} {YYYY}")
    assert { :ok, "Fri Nov  9 08:37:48 -0700 2007" } = format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {Z} {YYYY}")
    assert { :ok, "09 Nov 07 08:37" } = format(date, "{0D} {Mshort} {0YY} {0h24}:{0m}")

    assert { :ok, "8:37AM" } = format(date, "{h12}:{0m}{AM}")
  end

  test "can support unicode format strings" do
    date = Date.from({{2007,11,9}, {8,37,48}})
    assert {:error, {:format, "Expected end of input at line 1, column 31"}} = format(date, "{WDshort} å∫ç∂ {{{0h24}…{m}…{s}} ¿{Zname}?")
  end

  test "tokenization errors" do
    date = Date.now()
    expected_err = {:error, {:format, "Invalid format string, must contain at least one directive."}}
    empty_err = {:error, {:format, "Format string cannot be empty."}}
    unexpected_end_err = {:error, {:format, "Expected end of input at line 1, column 4"}}
    assert ^empty_err = format(date, "")
    assert ^expected_err = format(date, "abc")
    assert ^expected_err = format(date, "Use {{ as oft{{en as you like{{")
    assert ^expected_err = format(date, "Same go}}es for }}")
    assert ^expected_err = format(date, "{{{{abc}}")
    assert ^unexpected_end_err = format(date, "abc } def")
  end

  defp format(date, fmt) do
    DateFormat.format(date, fmt, Default)
  end
end
