defmodule DateFormatTest.ParseDefault do
  use ExUnit.Case, async: true
  use Timex

  test "exceptions" do
    date = "2013-03-02"
    assert %NaiveDateTime{:year => 2013, :month => 3, :day => 2} = Timex.parse!(date, "{YYYY}-{0M}-{0D}")
    assert_raise(Timex.Parse.ParseError, fn ->
      Timex.parse!(date, "{FOO}")
    end)
  end

  test "produce an error if input string contains no directives" do
    err = {:error, "Invalid format string, must contain at least one directive."}
    assert ^err = parse("hello", "hello")
    assert ^err = parse("hello1", "hello")
    assert ^err = parse("áîü≤≥Ø", "áîü≤≥")

    assert ^err = parse("h", "hello")
  end

  test "parse year4 and year2" do
    date2013 = Timex.to_naive_datetime({2013,1,1})
    date2003 = Timex.to_naive_datetime({2003,1,1})
    date0003 = Timex.to_naive_datetime({3,1,1})

    assert {:ok, ^date2013} = parse("2013", "{YYYY}")
    assert {:ok, ^date2013} = parse("13", "{YY}")

    assert {:ok, ^date0003} = parse("3", "{YYYY}")
    assert {:ok, ^date0003} = parse("0003", "{YYYY}")
    assert {:error, "Expected `1-4 digit year` at line 1, column 1."} = parse("   3", "{YYYY}")
    assert {:ok, ^date0003} = parse("0003", "{0YYYY}")
    assert {:ok, ^date0003} = parse("   3", "{_YYYY}")
    assert {:ok, ^date2003} = parse("3", "{YY}")
    assert {:ok, ^date2003} = parse("03", "{YY}")
    assert {:error, "Expected `1-2 digit year` at line 1, column 1."} = parse(" 3", "{YY}")
    assert {:ok, ^date2003} = parse("03", "{0YY}")
    assert {:ok, ^date2003} = parse(" 3", "{_YY}")
  end

  test "parse century" do
    date2000 = Timex.to_naive_datetime({2000,1,1})
    date1900 = Timex.to_naive_datetime({1900,1,1})
    date0000 = Timex.to_naive_datetime({0,1,1})
    assert {:ok, ^date2000} = parse("20", "{C}")
    assert {:ok, ^date1900} = parse("19", "{C}")
    assert {:ok, ^date0000} = parse("0", "{C}")
    assert {:ok, ^date0000} = parse("00", "{0C}")
    assert {:ok, ^date0000} = parse(" 0", "{_C}")
  end

  test "parse month" do
    date = Timex.to_naive_datetime({0,3,1})
    assert {:ok, ^date} = parse("3", "{M}")
    assert {:ok, ^date} = parse("03", "{M}")
    assert {:error, "Expected `1-2 digit month` at line 1, column 1."} = parse(" 3", "{M}")
    assert {:ok, ^date} = parse("03", "{0M}")
    assert {:ok, ^date} = parse(" 3", "{_M}")
  end

  test "parse day" do
    date18 = Timex.to_naive_datetime({0,1,18})
    date8 = Timex.to_naive_datetime({0,1,8})

    assert {:ok, ^date18} = parse("18", "{D}")
    assert {:ok, ^date18} = parse("18", "{0D}")
    assert {:ok, ^date18} = parse("18", "{_D}")
    assert {:ok, ^date8} = parse("8", "{D}")
    assert {:ok, ^date8} = parse("08", "{0D}")
    assert {:ok, ^date8} = parse(" 8", "{_D}")
  end

  test "parse simple format YYYY-M-D, with padding variations" do
    date2013_11 = Timex.to_naive_datetime({2013,11,8})

    assert {:ok, ^date2013_11} = parse("2013-11-08", "{YYYY}-{M}-{D}")
    assert {:error, "Expected `2 digit month` at line 1, column 6."} = parse("2013- 1- 8", "{YYYY}-{0M}-{0D}")
    assert {:ok, ^date2013_11} = parse("20131108", "{0YYYY}{0M}{0D}")
  end

  test "parse ISO week" do
    assert ~N[2016-11-28 00:00:00] = Timex.parse!("2016-W48", "{ISOweek}")
    assert ~N[2009-12-28 00:00:00] = Timex.parse!("2009-W53", "{ISOweek}")
    assert ~N[2007-11-19 00:00:00] = Timex.parse!("2007-W47", "{ISOweek}")
  end

  test "parse ISO week with day" do
    assert ~N[2018-06-25 00:00:00] = Timex.parse!("2018-W26-1", "{ISOweek-day}")
    assert ~N[2018-06-26 00:00:00] = Timex.parse!("2018-W26-2", "{ISOweek-day}")
    assert ~N[2018-07-01 00:00:00] = Timex.parse!("2018-W26-7", "{ISOweek-day}")

    assert {:error, "Expected `ordinal weekday` at line 1, column 10."} =
             Timex.parse("2018-W26-0", "{ISOweek-day}")

    assert {:error, "Expected `ordinal weekday` at line 1, column 10."} =
             Timex.parse("2018-W26-8", "{ISOweek-day}")
  end

  test "parse ISO year4/year2" do
    date = Timex.to_naive_datetime({2007,1,1})
    year = date.year
    assert {:ok, %NaiveDateTime{year: ^year} } = parse("2007", "{WYYYY}")
    assert {:error, "Expected `2 digit year` at line 1, column 1."} = parse("7"   , "{WYY}")
    assert {:ok, %NaiveDateTime{year: ^year} } = parse("07"  , "{0WYY}")
    assert {:ok, %NaiveDateTime{year: ^year} } = parse(" 7"  , "{_WYY}")
  end

  test "parse full and abbreviated month names" do
    date_nov = Timex.to_naive_datetime({0,11,1})
    assert {:ok, ^date_nov} = parse("Nov", "{Mshort}")
    assert {:ok, ^date_nov} = parse("November", "{Mfull}")

    date_mar = Timex.to_naive_datetime({0,3,1})
    assert {:ok, ^date_mar} = parse("Mar", "{Mshort}")
    assert {:ok, ^date_mar} = parse("March", "{Mfull}")

    assert {:error, "Input datetime string cannot be empty!"} = parse("", "{0Mfull}")
    assert {:error, "Input datetime string cannot be empty!"} = parse("", " {_Mshort}")
    assert {:error, "Expected `full month name` at line 1, column 4."} = parse("Apr", "{Mfull}")
    assert {:error, "Expected ` `, but found `J` at line 1, column 1."} = parse("January", " {Mshort}")
  end

  test "parse simple variations of year, month, and day directives" do
    date = Timex.to_naive_datetime({2013,8,18})
    assert {:ok, ^date} = parse("2013-8-18", "{YYYY}-{M}-{D}")
    assert {:ok, ^date} = parse("8 2013 18", "{M} {YYYY} {D}")

    date0003 = Timex.to_naive_datetime({3,8,8})
    date2003 = Timex.to_naive_datetime({2003,8,8})
    assert {:ok, ^date0003} = parse("3/08/08", "{YYYY}/{0M}/{0D}")
    assert {:ok, ^date2003} = parse("03 8 8", "{0YY}{_M}{_D}")
    assert {:ok, ^date2003} = parse(" 8/08/ 3", "{_D}/{0M}/{_YY}")
  end

  test "parse hour24" do
    date_midnight = Timex.to_naive_datetime({0,1,1})
    assert {:error, "Expected `hour between 0 and 24` at line 1, column 1."} = parse("0", "{h24}")
    assert {:ok, ^date_midnight} = parse("00", "{h24}")
    assert {:ok, ^date_midnight} = parse("00", "{0h24}")
    assert {:ok, ^date_midnight} = parse(" 0", "{_h24}")
    assert {:error, "Input datetime string cannot be empty!"} = parse("", "{0am}")
    assert {:error, "Input datetime string cannot be empty!"} = parse("", "{_AM}")
  end

  test "parse hour12 and am/AM" do
    date_midnight = Timex.to_naive_datetime({0,1,1})
    date_noon     = Timex.set(date_midnight, hour: 12)
    date_5a       = Timex.set(date_midnight, hour: 5)
    date_4p       = Timex.set(date_midnight, hour: 16)

    assert {:ok, ^date_midnight} = parse("12 am", "{h12} {am}")
    assert {:ok, ^date_noon}     = parse("12 pm", "{h12} {am}")
    assert {:ok, ^date_5a}       = parse("5 am",  "{h12} {am}")
    assert {:ok, ^date_4p}       = parse("4 pm",  "{h12} {am}")
    assert {:ok, ^date_4p}       = parse("04 PM", "{0h12} {AM}")
    assert {:ok, ^date_4p}       = parse(" 4 pm", "{_h12} {am}")
  end

  test "parse hour24 and am/AM" do
    date_midnight = Timex.to_naive_datetime({0,1,1})
    date_13 = Timex.to_naive_datetime({{0,1,1}, {13,0,0}})
    assert {:ok, ^date_13}       = parse("13 am", "{h24} {am}")
    assert {:ok, ^date_13}       = parse("13 pm", "{h24} {am}")
    assert {:ok, ^date_midnight} = parse("PM 00", "{AM} {0h24}")
    assert {:ok, ^date_midnight} = parse("24 pm", "{0h24} {am}")
  end

  test "parse simple time formats" do
    date = Timex.to_naive_datetime({{0,1,1}, {12,3,4}})
    assert {:ok, ^date} = parse("12: 3: 4", "{h24}:{_m}:{_s}")
    assert {:ok, ^date} = parse("12:03:04", "{h12}:{0m}:{0s}")
    assert {:ok, ^date} = parse("12:03:04 PM", "{h12}:{0m}:{0s} {AM}")
    assert {:error, "Expected `minute` at line 1, column 7." } = parse("pm 12:3:4", "{am} {h24}:{m}:{s}")
  end

  test "parse fractional seconds" do
    str = "2015-11-07T13:45:02.060Z"
    assert {:ok, %DateTime{second: 2, microsecond: {60_000, 3}}} = parse(str, "{ISO:Extended:Z}")
    str = "2015-11-07T13:45:02.687"
    assert {:ok, %NaiveDateTime{second: 2, microsecond: {687_000,3}}} = parse(str, "{YYYY}-{M}-{0D}T{h24}:{m}:{s}{ss}")
  end

  test "parse s-epoch" do
    date = Timex.shift(Timex.to_datetime({1970,1,1}), years: 3, days: 12)
    secs = Timex.to_unix(date)
    assert {:ok, ^date} = parse("#{secs}", "{s-epoch}")
    assert {:ok, ^date} = parse("#{secs}", "{0s-epoch}")
    assert {:ok, ^date} = parse("#{secs}", "{_s-epoch}")

    date = Timex.to_datetime({{2001,9,9},{1,46,40}})
    assert {:ok, ^date} = parse("1000000000", "{s-epoch}")

    date = Timex.epoch()
    dt = Timex.to_datetime(date, "Etc/UTC")
    assert {:ok, ^dt} = parse("0", "{s-epoch}")
    assert {:ok, ^dt} = parse("0000000000", "{0s-epoch}")
    assert {:error, "Expected `seconds since epoch` at line 1, column 1."} = parse("  0", "{s-epoch}")
    assert {:ok, ^dt} = parse(" 0", "{_s-epoch}")
  end

  test "parse RFC1123" do
    date_gmt = Timex.to_datetime({{2013,3,5},{23,25,19}}, "GMT")
    date_utc = Timex.to_datetime({{2013,3,5},{23,25,19}}, "UTC")
    date_est = Timex.to_datetime({{2013,3,5},{23,25,19}}, "EST")

    # * `{RFC1123}`     - e.g. `Tue, 05 Mar 2013 23:25:19 GMT`
    assert {:ok, ^date_gmt} = parse("Tue, 05 Mar 2013 23:25:19 GMT", "{RFC1123}")
    assert {:ok, ^date_est} = parse("Tue, 05 Mar 2013 23:25:19 EST", "{RFC1123}")
    assert {:ok, ^date_gmt} = parse("Tue, 5 Mar 2013 23:25:19 GMT", "{RFC1123}")
    assert {:ok, ^date_est} = parse("Tue, 5 Mar 2013 23:25:19 EST", "{RFC1123}")

    # * `{RFC1123z}`    - e.g. `Tue, 05 Mar 2013 23:25:19 +0200`
    assert {:ok, ^date_utc} = parse("Tue, 05 Mar 2013 23:25:19 Z", "{RFC1123z}")
    assert {:ok, ^date_utc} = parse("Tue, 5 Mar 2013 23:25:19 Z", "{RFC1123z}")
    date_utc_at_one = Timex.to_datetime({{2013,3,6},{1,25,19}})
    assert {:ok, ^date_utc_at_one} = parse("Tue, 06 Mar 2013 01:25:19 Z", "{RFC1123z}")
    assert {:ok, ^date_utc_at_one} = parse("Tue, 6 Mar 2013 01:25:19 Z", "{RFC1123z}")
  end

  test "parse RFC822" do
    # * `{RFC822}`      - e.g. `Mon, 05 Jun 14 23:20:59 UT`
    date = Timex.to_datetime({{2014, 6, 5}, {23, 20, 59}}, "Etc/GMT+12")
    assert {:ok, ^date} = parse("Mon, 05 Jun 14 23:20:59 Y", "{RFC822}")
    assert {:ok, ^date} = parse("Mon, 5 Jun 14 23:20:59 Y", "{RFC822}")
    assert {:ok, ^date} = parse("5 Jun 14 23:20:59 Y", "{RFC822}")

    # * `{RFC822z}`     - e.g. `Mon, 05 Jun 14 23:20:59 Z`
    date = Timex.to_datetime({{2014, 6, 5}, {23, 20, 59}}, "UTC")
    assert {:ok, ^date} = parse("Mon, 05 Jun 14 23:20:59 Z", "{RFC822z}")
    assert {:ok, ^date} = parse("Mon, 5 Jun 14 23:20:59 Z", "{RFC822z}")
  end

  test "parse RFC3339" do
    # * `{RFC3339}`     - e.g. `2013-03-05T23:25:19+02:00`
    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "GMT-2")
    assert {:ok, ^date} = parse("2013-03-05T23:25:19+02:00", "{RFC3339}")

    # * `{RFC3339z}`    - e.g. `2013-03-05T23:25:19Z`
    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "UTC")
    assert {:ok, ^date} = parse("2013-03-05T23:25:19Z", "{RFC3339z}")
  end

  test "parse ANSIC" do
    # * `{ANSIC}`       - e.g. `Tue Mar  5 23:25:19 2013`
    date = Timex.to_naive_datetime({{2013, 3, 5}, {23, 25, 19}})
    assert {:ok, ^date} = parse("Tue Mar  5 23:25:19 2013", "{ANSIC}")

    date = Timex.to_naive_datetime({{2015, 11, 16}, {22, 23, 48}})
    assert {:ok, ^date} = parse("Mon Nov 16 22:23:48 2015", "{ANSIC}")
  end

  test "parse UNIX" do
    # * `{UNIX}`        - e.g. `Tue Mar  5 23:25:19 EST 2013`
    date = Timex.to_datetime({{2013, 3, 5}, {23, 25, 19}}, "EST")
    assert {:ok, ^date} = parse("Tue Mar  5 23:25:19 EST 2013", "{UNIX}")


    date = Timex.to_datetime({{2015, 10, 5}, {0, 7, 11}}, "PST")
    assert {:ok, ^date} = parse("Mon Oct 5 00:07:11 PST 2015", "{UNIX}")

    date = Timex.to_datetime({{2015, 11, 16}, {22, 23, 48}}, "UTC")
    assert {:ok, ^date} = parse("Mon Nov 16 22:23:48 UTC 2015", "{UNIX}")
  end


  test "parse ASN1:UTCtime" do
    # * `{ASN1:UTCtime}`       - e.g. `Tue Mar  5 23:25:19 2013`
    date = Timex.to_datetime({{2009, 3, 5}, {23, 25, 19}})
    assert {:ok, ^date} = parse("090305232519Z", "{ASN1:UTCtime}")

    date = Timex.to_datetime({{2015, 11, 16}, {22, 23, 00}})
    assert {:ok, ^date} = parse("1511162223Z", "{ASN1:UTCtime}")
  end

  test "parse ASN1:GeneralizedTime" do
    # YYYYMMDDHH[MM[SS[.fff]]]
    # * `{ASN1:GeneralizedTime}`       - e.g. `Tue Mar  5 23:25:19 2013`
    timestamp = Duration.from_erl({1236, 295519, 456000}) |> Duration.to_seconds(truncate: true)
    {:ok, result} = parse("20090305232519.456", "{ASN1:GeneralizedTime}")
    assert ^timestamp = Timex.to_unix(result)

    date = Timex.to_naive_datetime({{2009, 3, 5}, {23, 25, 19}})
    assert {:ok, ^date} = parse("20090305232519.000", "{ASN1:GeneralizedTime}")

    date = Timex.to_naive_datetime({{2009, 3, 5}, {23, 25, 19}})
    assert {:ok, ^date} = parse("20090305232519", "{ASN1:GeneralizedTime}")

    date = Timex.to_naive_datetime({{2015, 11, 16}, {22, 23, 00}})
    assert {:ok, ^date} = parse("201511162223", "{ASN1:GeneralizedTime}")

    date = Timex.to_naive_datetime({{2015, 11, 16}, {22, 00, 00}})
    assert {:ok, ^date} = parse("2015111622", "{ASN1:GeneralizedTime}")
  end

  test "parse ASN1:GeneralizedTime:Z" do
    # YYYYMMDDHH[MM[SS[.fff]]]Z
    # * `{ASN1:GeneralizedTime:Z}`       - e.g. `Tue Mar  5 23:25:19 2013`
    {:ok, result} = parse("20090305232519.456Z", "{ASN1:GeneralizedTime:Z}")
    assert 1236295519 = Timex.to_unix(result)

    date = Timex.to_datetime({{2009, 3, 5}, {23, 25, 19}})
    assert {:ok, ^date} = parse("20090305232519.000Z", "{ASN1:GeneralizedTime:Z}")

    date = Timex.to_datetime({{2009, 3, 5}, {23, 25, 19}})
    assert {:ok, ^date} = parse("20090305232519Z", "{ASN1:GeneralizedTime:Z}")

    date = Timex.to_datetime({{2015, 11, 16}, {22, 23, 00}}, "UTC")
    assert {:ok, ^date} = parse("201511162223Z", "{ASN1:GeneralizedTime:Z}")

    date = Timex.to_datetime({{2015, 11, 16}, {22, 00, 00}}, "UTC")
    assert {:ok, ^date} = parse("2015111622Z", "{ASN1:GeneralizedTime:Z}")
  end

  test "parse ASN1:GeneralizedTime:TZ" do
    # YYYYMMDDHH[MM[SS[.fff]]]Z
    # * `{ASN1:GeneralizedTime:TZ}`       - e.g. `Tue Mar  5 23:25:19 2013`
    {:ok, result} = parse("20090305232519.456-0700", "{ASN1:GeneralizedTime:TZ}")
    assert 1236320719 = Timex.to_unix(result)

    date = Timex.to_datetime({{2009, 3, 5}, {23, 25, 19}}, "Etc/GMT+7")
    assert {:ok, ^date} = parse("20090305232519.000-0700", "{ASN1:GeneralizedTime:TZ}")

    date = Timex.to_datetime({{2009, 3, 5}, {23, 25, 19}}, "Etc/GMT+7")
    assert {:ok, ^date} = parse("20090305232519-0700", "{ASN1:GeneralizedTime:TZ}")

    date = Timex.to_datetime({{2015, 11, 16}, {22, 23, 00}}, "Etc/GMT+7")
    assert {:ok, ^date} = parse("201511162223-0700", "{ASN1:GeneralizedTime:TZ}")

    date = Timex.to_datetime({{2015, 11, 16}, {22, 00, 00}}, "Etc/GMT+7")
    assert {:ok, ^date} = parse("2015111622-0700", "{ASN1:GeneralizedTime:TZ}")
  end

  test "parse kitchen" do
    # * `{kitchen}`     - e.g. `3:25PM`
    date = Timex.to_naive_datetime(Timex.set(Timex.now(), hour: 15, minute: 25, second: 0, microsecond: {0,0}))
    assert {:ok, ^date} = parse("3:25PM", "{kitchen}")
  end

  test "parse ISO8601 (Extended)" do
    date1 = Timex.to_datetime({{2014, 8, 14}, {12, 34, 33}})
    date2 = %{date1 | :microsecond => {199_000,3}}

    assert {:ok, ^date1} = parse("2014-08-14T12:34:33+00:00", "{ISO:Extended}")
    assert {:ok, ^date1} = parse("2014-08-14T12:34:33+0000", "{ISO:Extended}")
    assert {:ok, ^date1} = parse("2014-08-14T12:34:33+00", "{ISO:Extended}")
    assert {:ok, ^date1} = parse("2014-08-14T12:34:33Z", "{ISO:Extended}")
    assert {:ok, ^date1} = parse("2014-08-14T12:34:33Z", "{ISO:Extended:Z}")
    assert {:error, "Expected at least one digit" <> _} = parse("2014-08-14T12:34:33.Z", "{ISO:Extended}")

    assert {:ok, ^date2} = parse("2014-08-14T12:34:33.199+00:00", "{ISO:Extended}")
    assert {:ok, ^date2} = parse("2014-08-14T12:34:33.199+0000", "{ISO:Extended}")
    assert {:ok, ^date2} = parse("2014-08-14T12:34:33.199+00", "{ISO:Extended}")
    assert {:ok, ^date2} = parse("2014-08-14T12:34:33.199Z", "{ISO:Extended}")
    assert {:ok, ^date2} = parse("2014-08-14T12:34:33.199Z", "{ISO:Extended:Z}")

    date3 = Timex.to_datetime({{2014, 8, 14}, {12, 34, 33}}, "Etc/GMT+5")
    assert {:ok, ^date3} = parse("2014-08-14T12:34:33-05:00", "{ISO:Extended}")
    assert {:ok, ^date3} = parse("2014-08-14T12:34:33-0500", "{ISO:Extended}")
    assert {:ok, ^date3} = parse("2014-08-14T12:34:33-05", "{ISO:Extended}")

    date4 = Timex.to_datetime({{2007, 4, 5}, {14, 30, 0}})
    assert {:ok, ^date4} = parse("2007-04-05T14:30Z", "{ISO:Extended}")

    date5 = Timex.to_datetime({{2007, 4, 5}, {14, 0, 0}})
    assert {:ok, ^date5} = parse("2007-04-05T14Z", "{ISO:Extended}")

    date6 = Timex.to_datetime({{2016, 11, 30}, {9, 5, 32}})
    date6 = %{date6 | :time_zone => "Etc/GMT-5:30", :zone_abbr => "+05:30", :utc_offset => 330*60, :std_offset => 0}
    assert {:ok, ^date6} = parse("2016-11-30T09:05:32+05:30", "{ISO:Extended}")
  end

  test "parse ISO8601 (Basic)" do
    date1z = Timex.to_datetime({{2014, 8, 14}, {12, 34, 33}})
    date1  = %{date1z | :time_zone => "Etc/GMT+0", :zone_abbr => "GMT"}
    date2z = %{date1z | :microsecond => {199_000,3}}
    date2  = %{date2z | :time_zone => "Etc/GMT+0", :zone_abbr => "GMT"}

    assert {:ok, ^date1} = parse("20140814T123433-0000", "{ISO:Basic}")
    assert {:ok, ^date1} = parse("20140814T123433-00", "{ISO:Basic}")
    assert {:ok, ^date1z} = parse("20140814T123433Z", "{ISO:Basic}")
    assert {:ok, ^date1z} = parse("20140814T123433Z", "{ISO:Basic:Z}")

    assert {:ok, ^date2} = parse("20140814T123433.199-0000", "{ISO:Basic}")
    assert {:ok, ^date2} = parse("20140814T123433.199-00", "{ISO:Basic}")
    assert {:ok, ^date2z} = parse("20140814T123433.199Z", "{ISO:Basic}")
    assert {:ok, ^date2z} = parse("20140814T123433.199Z", "{ISO:Basic:Z}")

    date3 = Timex.to_datetime({{2014, 8, 14}, {12, 34, 33}}, "Etc/GMT+5")
    assert {:ok, ^date3} = parse("20140814T123433-0500", "{ISO:Basic}")
    assert {:ok, ^date3} = parse("20140814T123433-05", "{ISO:Basic}")

    date4 = Timex.to_datetime({{2007, 4, 5}, {14, 30, 0}})
    assert {:ok, ^date4} = parse("20070405T1430Z", "{ISO:Basic}")

    date5 = Timex.to_datetime({{2007, 4, 5}, {14, 0, 0}})
    assert {:ok, ^date5} = parse("20070405T14Z", "{ISO:Basic}")
  end

  test "parse time struct" do
    to_change = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3}})
    changed = Timex.set(to_change, [time: ~T[09:52:33.000]])

    assert 33 == changed.second
    assert 52 == changed.minute
    assert 9 == changed.hour
    assert changed.year == to_change.year
    assert changed.month == to_change.month
    assert changed.day == to_change.day
  end

  test "set from time struct with more than one change requested" do
    to_change = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3}})
    changed = Timex.set(to_change, [time: ~T[09:52:33.000], year: 1989])

    assert 1989 == changed.year
    assert 33 == changed.second
    assert 52 == changed.minute
    assert 9 == changed.hour
    assert changed.month == to_change.month
    assert changed.day == to_change.day
  end

  test "roundtrip bug #252" do
    format = "{YYYY}-{0M}-{0D}T{0h24}:{0m}:{0s}{0ss}{Zname}"
    now = Timex.now()
    formatted = Timex.format!(now, format)
    assert ^now = Timex.parse!(formatted, format)
  end

  test "roundtrip bug #318" do
    {:ok, d} = Timex.parse("2017-06-27T08:32:55.80011111123333Z", "{ISO:Extended}")
    assert "2017-06-27T08:32:55.800111+00:00" = Timex.format!(d, "{ISO:Extended}")
  end

  defp parse(date, fmt) do
    Timex.parse(date, fmt)
  end
end
