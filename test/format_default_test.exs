defmodule DateFormatTest.FormatDefault do
  use ExUnit.Case, async: true
  use Timex

  test "exceptions" do
    date = Timex.to_datetime({2013, 8, 18})

    assert_raise(Timex.Format.FormatError, fn ->
      Timex.format!(date, "{FOO}")
    end)
  end

  test "format Erlang date" do
    assert {:ok, _} = Timex.format({2015, 6, 24}, "{YYYY}-{M}-{D}")
  end

  test "format year" do
    date = Timex.to_datetime({2013, 8, 18})
    old_date = Timex.to_datetime({3, 8, 18})

    assert {:ok, "2013"} = format(date, "{YYYY}")
    assert {:ok, "13"} = format(date, "{YY}")
    assert {:ok, "3"} = format(old_date, "{YYYY}")
    assert {:ok, "0003"} = format(old_date, "{0YYYY}")
    assert {:ok, "   3"} = format(old_date, "{_YYYY}")
    assert {:ok, "3"} = format(old_date, "{YY}")
    assert {:ok, "03"} = format(old_date, "{0YY}")
    assert {:ok, " 3"} = format(old_date, "{_YY}")
  end

  test "format century" do
    date = Timex.to_datetime({2013, 8, 18})
    old_date = Timex.to_datetime({3, 8, 18})

    assert {:ok, "20"} = format(date, "{C}")
    assert {:ok, "0"} = format(old_date, "{C}")
    assert {:ok, "00"} = format(old_date, "{0C}")
    assert {:ok, " 0"} = format(old_date, "{_C}")
  end

  test "format ISO year" do
    date = Timex.to_datetime({2007, 11, 19})
    assert {:ok, "2007"} = format(date, "{WYYYY}")
    assert {:ok, "07"} = format(date, "{WYY}")
    assert {:ok, "07"} = format(date, "{0WYY}")
    assert {:ok, " 7"} = format(date, "{_WYY}")

    date = Timex.to_datetime({2006, 1, 1})
    assert {:ok, "2005"} = format(date, "{WYYYY}")
    assert {:ok, "05"} = format(date, "{WYY}")
    assert {:ok, "05"} = format(date, "{0WYY}")
    assert {:ok, " 5"} = format(date, "{_WYY}")
  end

  test "format month" do
    date = Timex.to_datetime({3, 3, 8})
    assert {:ok, "3"} = format(date, "{M}")
    assert {:ok, "03"} = format(date, "{0M}")
    assert {:ok, " 3"} = format(date, "{_M}")
  end

  test "format full/abbreviated month name" do
    date = Timex.to_datetime({2013, 11, 18})
    old_date = Timex.to_datetime({3, 3, 8})

    assert {:ok, "Nov"} = format(date, "{Mshort}")
    assert {:ok, "November"} = format(date, "{Mfull}")
    assert {:ok, "Mar"} = format(old_date, "{Mshort}")
    assert {:ok, "March"} = format(old_date, "{Mfull}")

    assert {:ok, "November"} = format(date, "{0Mfull}")
    assert {:ok, " Mar"} = format(old_date, " {_Mshort}")
  end

  test "format day of month" do
    date = Timex.to_datetime({2013, 8, 18})
    old_date = Timex.to_datetime({3, 8, 8})

    assert {:ok, "18"} = format(date, "{D}")
    assert {:ok, "18"} = format(date, "{0D}")
    assert {:ok, "18"} = format(date, "{_D}")
    assert {:ok, "8"} = format(old_date, "{D}")
    assert {:ok, "08"} = format(old_date, "{0D}")
    assert {:ok, " 8"} = format(old_date, "{_D}")
  end

  test "format day of year" do
    date = Timex.to_datetime({3, 2, 1})

    assert {:ok, "32"} = format(date, "{Dord}")
    assert {:ok, "032"} = format(date, "{0Dord}")
    assert {:ok, " 32"} = format(date, "{_Dord}")

    date = Timex.to_datetime({3, 12, 31})
    assert {:ok, "365"} = format(date, "{Dord}")

    date = Timex.to_datetime({3, 1, 1})
    assert {:ok, "001"} = format(date, "{0Dord}")
  end

  test "format day of week" do
    date = Timex.to_datetime({2007, 11, 18})
    assert {:ok, "0"} = format(date, "{WDsun}")
    assert {:ok, "7"} = format(date, "{WDmon}")
    assert {:ok, "0"} = format(date, "{0WDsun}")
    assert {:ok, "7"} = format(date, "{0WDmon}")
    assert {:ok, "0"} = format(date, "{_WDsun}")
    assert {:ok, "7"} = format(date, "{_WDmon}")
  end

  test "format full/abbreviated weekday name" do
    assert {:ok, "Mon"} = format(Timex.to_datetime({2012, 12, 31}), "{WDshort}")
    assert {:ok, "Tue"} = format(Timex.to_datetime({2013, 1, 1}), "{WDshort}")
    assert {:ok, "Wed"} = format(Timex.to_datetime({2013, 1, 2}), "{WDshort}")
    assert {:ok, "Thu"} = format(Timex.to_datetime({2013, 1, 3}), "{WDshort}")
    assert {:ok, "Fri"} = format(Timex.to_datetime({2013, 1, 4}), "{WDshort}")
    assert {:ok, "Sat"} = format(Timex.to_datetime({2013, 1, 5}), "{WDshort}")
    assert {:ok, "Sun"} = format(Timex.to_datetime({2013, 1, 6}), "{WDshort}")
    assert {:ok, "Sun"} = format(Timex.to_datetime({2013, 1, 6}), "{0WDshort}")
    assert {:ok, "Sun"} = format(Timex.to_datetime({2013, 1, 6}), "{_WDshort}")

    assert {:ok, "Monday"} = format(Timex.to_datetime({2012, 12, 31}), "{WDfull}")
    assert {:ok, "Tuesday"} = format(Timex.to_datetime({2013, 1, 1}), "{WDfull}")
    assert {:ok, "Wednesday"} = format(Timex.to_datetime({2013, 1, 2}), "{WDfull}")
    assert {:ok, "Thursday"} = format(Timex.to_datetime({2013, 1, 3}), "{WDfull}")
    assert {:ok, "Friday"} = format(Timex.to_datetime({2013, 1, 4}), "{WDfull}")
    assert {:ok, "Saturday"} = format(Timex.to_datetime({2013, 1, 5}), "{WDfull}")
    assert {:ok, "Sunday"} = format(Timex.to_datetime({2013, 1, 6}), "{WDfull}")
    assert {:ok, "Sunday"} = format(Timex.to_datetime({2013, 1, 6}), "{0WDfull}")
    assert {:ok, "Sunday"} = format(Timex.to_datetime({2013, 1, 6}), "{_WDfull}")
  end

  test "format ISO week" do
    date = Timex.to_datetime({2007, 11, 19})
    assert {:ok, "47"} = format(date, "{Wiso}")
    assert {:ok, "47"} = format(date, "{0Wiso}")
    assert {:ok, "47"} = format(date, "{_Wiso}")

    date = Timex.to_datetime({2007, 1, 1})
    assert {:ok, "01"} = format(date, "{Wiso}")
    assert {:ok, "01"} = format(date, "{0Wiso}")
    assert {:ok, " 1"} = format(date, "{_Wiso}")
  end

  test "format week number" do
    date = Timex.to_datetime({2013, 1, 1})
    assert {:ok, "0"} = format(date, "{Wmon}")
    assert {:ok, "0"} = format(date, "{Wsun}")

    date = Timex.to_datetime({2013, 1, 6})
    assert {:ok, "00"} = format(date, "{0Wmon}")
    assert {:ok, "01"} = format(date, "{0Wsun}")

    date = Timex.to_datetime({2013, 1, 7})
    assert {:ok, " 1"} = format(date, "{_Wmon}")
    assert {:ok, " 1"} = format(date, "{_Wsun}")

    date = Timex.to_datetime({2012, 1, 1})
    # Is actually part of previous year
    assert {:ok, "0"} = format(date, "{Wmon}")
    assert {:ok, "1"} = format(date, "{Wsun}")

    date = Timex.to_datetime({2012, 1, 2})
    assert {:ok, "1"} = format(date, "{Wmon}")
    assert {:ok, "1"} = format(date, "{Wsun}")

    date = Timex.to_datetime({2012, 12, 30})
    assert {:ok, "52"} = format(date, "{Wmon}")
    assert {:ok, "53"} = format(date, "{Wsun}")
  end

  test "format simple compound date formats" do
    date = Timex.to_datetime({2013, 8, 18})
    old_date = Timex.to_datetime({3, 8, 8})

    assert {:ok, "2013-8-18"} = format(date, "{YYYY}-{M}-{D}")
    assert {:ok, "3/08/08"} = format(old_date, "{YYYY}/{0M}/{0D}")
    assert {:ok, "03 8 8"} = format(old_date, "{0YY}{_M}{_D}")

    assert {:ok, "8 2013 18"} = format(date, "{M} {YYYY} {D}")
    assert {:ok, " 8/08/ 3"} = format(old_date, "{_D}/{0M}/{_YY}")
    assert {:ok, "8"} = format(date, "{M}")
    assert {:ok, "18"} = format(date, "{D}")
  end

  test "format time" do
    date = Timex.to_datetime({{2013, 8, 18}, {16, 28, 27}})
    date_midnight = Timex.to_datetime({{2013, 8, 18}, {0, 3, 4}})

    assert {:ok, "00"} = format(date_midnight, "{h24}")
    assert {:ok, "00"} = format(date_midnight, "{0h24}")
    assert {:ok, " 0"} = format(date_midnight, "{_h24}")

    assert {:ok, "4"} = format(date, "{h12}")
    assert {:ok, "04"} = format(date, "{0h12}")
    assert {:ok, " 4"} = format(date, "{_h12}")

    date = Timex.to_datetime({{2013, 8, 18}, {12, 3, 4}})
    assert {:ok, "12: 3: 4"} = format(date, "{h24}:{_m}:{_s}")
    assert {:ok, "12:03:04"} = format(date, "{h12}:{0m}:{0s}")
    assert {:ok, "12:03:04 PM"} = format(date, "{h12}:{0m}:{0s} {AM}")
    assert {:ok, "pm 12:03:04"} = format(date, "{am} {h24}:{m}:{s}")
    assert {:ok, "am 12"} = format(date_midnight, "{am} {h12}")
    assert {:ok, "AM 00"} = format(date_midnight, "{AM} {0h24}")

    assert {:ok, "am"} = format(date_midnight, "{0am}")
    assert {:ok, "AM"} = format(date_midnight, "{_AM}")
  end

  test "format seconds since epoch" do
    date = Timex.to_datetime({{2013, 8, 18}, {12, 3, 4}})

    invalid_flag_err =
      {:error,
       {:formatter,
        "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}

    assert {:ok, "1376827384"} = format(date, "{s-epoch}")
    assert ^invalid_flag_err = format(date, "{0s-epoch}")
    assert ^invalid_flag_err = format(date, "{_s-epoch}")

    date = Timex.to_datetime({{2001, 9, 9}, {1, 46, 40}})
    assert {:ok, "1000000000"} = format(date, "{s-epoch}")

    date = Timex.epoch()
    assert {:ok, "0"} = format(date, "{s-epoch}")
    assert ^invalid_flag_err = format(date, "{0s-epoch}")
    assert ^invalid_flag_err = format(date, "{_s-epoch}")
  end

  test "format timezone name/offset" do
    date = Timex.to_datetime({2007, 11, 19}, "Europe/Athens")
    assert {:ok, "Europe/Athens"} = format(date, "{Zname}")
    assert {:ok, "EET"} = format(date, "{Zabbr}")
    assert {:ok, "+0200"} = format(date, "{Z}")
    assert {:ok, "+02:00"} = format(date, "{Z:}")
    assert {:ok, "+02:00:00"} = format(date, "{Z::}")

    date = Timex.to_datetime({2007, 11, 19}, "America/New_York")
    assert {:ok, "America/New_York"} = format(date, "{Zname}")
    assert {:ok, "EST"} = format(date, "{Zabbr}")
    assert {:ok, "-0500"} = format(date, "{Z}")
    assert {:ok, "-05:00"} = format(date, "{Z:}")
    assert {:ok, "-05:00:00"} = format(date, "{Z::}")

    assert {:ok, "America/New_York"} = format(date, "{0Zname}")
    assert {:ok, "EST"} = format(date, "{0Zabbr}")

    assert {:error,
            {:formatter,
             "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}} =
             format(date, "{_Z}")

    assert {:ok, "-05:00"} = format(date, "{0Z:}")

    assert {:error,
            {:formatter,
             "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}} =
             format(date, "{_Z::}")
  end

  test "format ISO8601 (Extended)" do
    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "Europe/Athens")
    assert {:ok, "2013-03-05T23:25:19+02:00"} = format(date, "{ISO:Extended}")
    assert {:ok, "2013-03-05T21:25:19Z"} = format(date, "{ISO:Extended:Z}")

    local = {{2013, 3, 5}, {23, 25, 19}}

    assert {:ok, "2013-03-05T23:25:19-08:00"} =
             format(Timex.to_datetime(local, "America/Los_Angeles"), "{ISO:Extended}")

    assert {:ok, "2013-03-05T23:25:19+00:00"} =
             format(Timex.to_datetime(local, :utc), "{ISO:Extended}")
  end

  test "format ISO8601 (Basic)" do
    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "Europe/Athens")
    assert {:ok, "20130305T232519+0200"} = format(date, "{ISO:Basic}")
    assert {:ok, "20130305T212519Z"} = format(date, "{ISO:Basic:Z}")

    local = {{2013, 3, 5}, {23, 25, 19}}

    assert {:ok, "20130305T232519-0800"} =
             format(Timex.to_datetime(local, "America/Los_Angeles"), "{ISO:Basic}")

    assert {:ok, "20130305T232519+0000"} = format(Timex.to_datetime(local, :utc), "{ISO:Basic}")
  end

  test "format ISO date" do
    date = Timex.to_datetime({{2007, 11, 19}, {1, 37, 48}}, "Europe/Athens")

    assert {:ok, "2007-11-19"} = format(date, "{ISOdate}")
    assert {:ok, "20071119"} = format(date, "{0YYYY}{0M}{0D}")
    assert {:ok, "0007-01-02"} = format(Timex.to_datetime({7, 1, 2}), "{ISOdate}")
  end

  test "format ISO time" do
    date = Timex.to_datetime({{2007, 11, 19}, {1, 37, 48}}, "Europe/Athens")

    assert {:ok, "01:37:48"} = format(date, "{ISOtime}")
    assert {:ok, "01:37:48"} = format(date, "{0h24}:{0m}:{0s}")
    assert {:ok, "23:03:09"} = format(Timex.to_datetime({{1, 2, 3}, {23, 3, 9}}), "{ISOtime}")

    assert {:ok, "23:03:09"} =
             format(Timex.to_datetime({{1, 2, 3}, {23, 3, 9}}), "{0h24}:{0m}:{0s}")
  end

  test "format ISOweek" do
    date = Timex.to_datetime({{2007, 11, 19}, {1, 37, 48}}, "Europe/Athens")

    assert {:ok, "2007-W47"} = format(date, "{ISOweek}")
    assert {:ok, "2007-W47-1"} = format(date, "{ISOweek}-{WDmon}")
    assert {:ok, "2007-W47-1"} = format(date, "{ISOweek-day}")
    assert {:ok, "2007W471"} = format(date, "{0WYYYY}W{0Wiso}{WDmon}")
  end

  test "format ISO day of year" do
    date = Timex.to_datetime({{2007, 11, 19}, {1, 37, 48}}, "Europe/Athens")

    assert {:ok, "2007-323"} = format(date, "{ISOord}")
    assert {:ok, "2007-323"} = format(date, "{0YYYY}-{0Dord}")
  end

  test "format RFC1123" do
    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}})
    assert {:ok, "Tue, 05 Mar 2013 23:25:19 +0000"} = format(date, "{RFC1123}")
    assert {:ok, "Tue, 05 Mar 2013 23:25:19 Z"} = format(date, "{RFC1123z}")

    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "Europe/Athens")
    assert {:ok, "Tue, 05 Mar 2013 23:25:19 +0200"} = format(date, "{RFC1123}")
    assert {:ok, "Tue, 05 Mar 2013 21:25:19 Z"} = format(date, "{RFC1123z}")

    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "America/Los_Angeles")
    assert {:ok, "Tue, 05 Mar 2013 23:25:19 -0800"} = format(date, "{RFC1123}")
    assert {:ok, "Wed, 06 Mar 2013 07:25:19 Z"} = format(date, "{RFC1123z}")
  end

  test "format RFC3339" do
    local = {{2013, 3, 5}, {23, 25, 19}}

    assert {:ok, "2013-03-05T23:25:19Z"} = format(Timex.to_datetime(local), "{RFC3339z}")

    assert {:ok, "2014-09-26T17:10:20Z"} =
             format(Timex.to_datetime({{2014, 9, 26}, {17, 10, 20}}, "Etc/UTC"), "{RFC3339z}")

    assert {:ok, "2014-09-26T07:00:02Z"} =
             format(Timex.to_datetime({{2014, 9, 26}, {7, 0, 2}}, "UTC"), "{RFC3339z}")

    assert {:ok, "2013-03-05T23:25:19+02:00"} =
             format(Timex.to_datetime(local, "Europe/Athens"), "{RFC3339}")

    assert {:ok, "2013-03-05T23:25:19-08:00"} =
             format(Timex.to_datetime(local, "America/Los_Angeles"), "{RFC3339}")

    date = Timex.to_datetime({{2014, 9, 26}, {17, 10, 20}}, "America/Montevideo")
    assert format(date, "{RFC3339}") == {:ok, "2014-09-26T17:10:20-03:00"}
    date = Timex.to_datetime({{2014, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert format(date, "{RFC3339}") == {:ok, "2014-09-26T07:00:02+02:00"}
    date = Timex.to_datetime({{10, 9, 26}, {7, 0, 2}}, "Europe/Copenhagen")
    assert format(date, "{RFC3339}") == {:ok, "0010-09-26T07:00:02+00:50"}
  end

  test "format ANSIC" do
    local = {{2013, 3, 5}, {23, 25, 19}}
    date = Timex.to_datetime(local, :utc)

    assert {:ok, "Tue Mar  5 23:25:19 2013"} = format(date, "{ANSIC}")
  end

  test "format ASN1 UTC Time" do
    local = {{2013, 3, 5}, {23, 25, 19}}
    date = Timex.to_datetime(local, :utc)

    assert {:ok, "130305232519Z"} = format(date, "{ASN1:UTCtime}")
  end

  test "format ASN1 Generalized Time" do
    local = {{2013, 3, 5}, {23, 25, 19}}
    date = Timex.to_datetime(local, :local)

    assert {:ok, "20130305232519"} = format(date, "{ASN1:GeneralizedTime}")

    date = Timex.to_datetime(local)

    assert {:ok, "20130305232519"} = format(date, "{ASN1:GeneralizedTime}")
  end

  test "format ASN1 Generalized Time Z" do
    local = {{2013, 3, 5}, {23, 25, 19}}
    date = Timex.to_datetime(local, :utc)

    assert {:ok, "20130305232519Z"} = format(date, "{ASN1:GeneralizedTime:Z}")

    date = Timex.to_datetime(local)

    assert {:ok, "20130305232519Z"} = format(date, "{ASN1:GeneralizedTime:Z}")
  end

  test "format ASN1 Generalized Time TZ" do
    local = {{2013, 3, 5}, {23, 25, 19}}
    date = Timex.to_datetime(local, "-0500")

    assert {:ok, "20130305232519-0500"} = format(date, "{ASN1:GeneralizedTime:TZ}")
  end

  test "format UNIX" do
    local = {{2013, 3, 5}, {23, 25, 19}}
    date = Timex.to_datetime(local, :utc)

    assert {:ok, "Tue Mar  5 23:25:19 UTC 2013"} = format(date, "{UNIX}")

    assert {:ok, "Tue Mar  5 23:25:19 PST 2013"} =
             format(Timex.to_datetime(local, "America/Los_Angeles"), "{UNIX}")

    local = {{2015, 11, 16}, {22, 23, 48}}
    date = Timex.to_datetime(local, :utc)

    assert {:ok, "Mon Nov 16 22:23:48 UTC 2015"} = format(date, "{UNIX}")

    assert {:ok, "Mon Nov 16 22:23:48 PST 2015"} =
             format(Timex.to_datetime(local, "America/Los_Angeles"), "{UNIX}")
  end

  test "format kitchen" do
    date = Timex.to_datetime({{2013, 3, 5}, {15, 25, 19}})
    assert {:ok, "3:25PM"} = Timex.format(date, "{kitchen}")
  end

  # References:
  # http://www.ruby-doc.org/core-2.0/Time.html#method-i-strftime
  # http://golang.org/pkg/time/#pkg-constants
  test "can properly format various complex compound formats" do
    date = Timex.to_datetime({{2007, 11, 19}, {8, 37, 48}}, "Etc/GMT-6")

    assert {:ok, "083748+0600"} = format(date, "{0h24}{0m}{0s}{Z}")
    assert {:ok, "08:37:48+06:00"} = format(date, "{0h24}:{0m}:{0s}{Z:}")
    assert {:ok, "20071119T083748+0600"} = format(date, "{YYYY}{M}{D}T{0h24}{m}{s}{Z}")
    assert {:ok, "2007-11-19T08:37:48+06:00"} = format(date, "{YYYY}-{M}-{D}T{0h24}:{m}:{s}{Z:}")
    assert {:ok, "2007323T083748+0600"} = format(date, "{YYYY}{Dord}T{0h24}{m}{s}{Z}")
    assert {:ok, "2007-323T08:37:48+06:00"} = format(date, "{YYYY}-{Dord}T{0h24}:{m}:{s}{Z:}")
    assert {:ok, "2007W471T083748+0600"} = format(date, "{WYYYY}W{Wiso}{WDmon}T{0h24}{m}{s}{Z}")

    assert {:ok, "2007-W47-1T08:37:48+06:00"} =
             format(date, "{WYYYY}-W{Wiso}-{WDmon}T{0h24}:{m}:{s}{Z:}")

    date = Timex.to_datetime({{2007, 11, 9}, {8, 37, 48}}, "America/Denver")

    assert {:ok, "20071109T0837"} = format(date, "{YYYY}{M}{0D}T{0h24}{m}")
    assert {:ok, "2007-11-09T08:37"} = format(date, "{YYYY}-{M}-{0D}T{0h24}:{m}")

    assert {:ok, "Fri Nov  9 08:37:48 2007"} =
             format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {YYYY}")

    assert {:ok, "Fri Nov  9 08:37:48 MST 2007"} =
             format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {Zabbr} {YYYY}")

    assert {:ok, "Fri Nov  9 08:37:48 -0700 2007"} =
             format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {Z} {YYYY}")

    assert {:ok, "09 Nov 07 08:37"} = format(date, "{0D} {Mshort} {0YY} {0h24}:{0m}")

    assert {:ok, "8:37AM"} = format(date, "{h12}:{0m}{AM}")
  end

  test "can support unicode format strings" do
    date = Timex.to_datetime({{2007, 11, 9}, {8, 37, 48}})

    assert {:error, {:format, "Expected end of input at line 1, column 31"}} =
             format(date, "{WDshort} å∫ç∂ {{{0h24}…{m}…{s}} ¿{Zname}?")
  end

  test "tokenization errors" do
    date = Timex.now()

    expected_err =
      {:error, {:format, "Invalid format string, must contain at least one directive."}}

    empty_err = {:error, {:format, "Format string cannot be empty."}}
    unexpected_end_err = {:error, {:format, "Expected end of input at line 1, column 4"}}
    assert empty_err == format(date, "")
    assert expected_err == format(date, "abc")
    assert expected_err == format(date, "Use {{ as oft{{en as you like{{")
    assert expected_err == format(date, "Same go}}es for }}")
    assert expected_err == format(date, "{{{{abc}}")
    assert unexpected_end_err == format(date, "abc } def")
  end

  test "milliseconds as fractional seconds via {ss}" do
    date = Timex.to_datetime({{2015, 11, 9}, {8, 37, 48}})
    date = %{date | :microsecond => {065_000, 3}}
    assert {:ok, "2015-11-09T08:37:48.065"} = format(date, "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}{ss}")
  end

  test "issue #79 - invalid ISO 8601 string with fractional ms" do
    date = Timex.to_datetime({{2015, 1, 14}, {12, 0, 0}}, "Etc/UTC")
    date = %{date | :microsecond => {10, 6}}
    formatted = format(date, "{ISO:Extended}")
    expected = {:ok, "2015-01-14T12:00:00.000010+00:00"}
    assert expected == formatted
  end

  test "issue #228 - update of gettext causes exception" do
    date = Timex.to_datetime({{2015, 1, 14}, {12, 0, 0}}, "Etc/UTC")
    formatted = Timex.format!(date, "{Mfull} {D} {YYYY}, {h12}:{m}{am}")
    expected = "January 14 2015, 12:00pm"
    assert expected == formatted
  end

  defp format(date, fmt) do
    Timex.format(date, fmt)
  end
end
