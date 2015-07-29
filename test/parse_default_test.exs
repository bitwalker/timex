defmodule DateFormatTest.ParseDefault do
  use ExUnit.Case, async: true
  use Timex

  test "produce an error if input string contains no directives" do
    err = {:error, {:format, "Invalid format string, must contain at least one directive."}}
    assert ^err = parse("hello", "hello")
    assert ^err = parse("hello1", "hello")
    assert ^err = parse("áîü≤≥Ø", "áîü≤≥")

    assert ^err = parse("h", "hello")
  end

  test "parse year4 and year2" do
    date2013 = Date.from({2013,1,1})
    date2003 = Date.from({2003,1,1})
    date0003 = Date.from({3,1,1})

    assert { :ok, ^date2013 } = parse("2013", "{YYYY}")
    assert { :ok, ^date2013 } = parse("13", "{YY}")

    assert { :ok, ^date0003 } = parse("3", "{YYYY}")
    assert { :ok, ^date0003 } = parse("0003", "{YYYY}")
    assert {:error, "Expected `4 digit year` at line 1, column 1."} = parse("   3", "{YYYY}")
    assert { :ok, ^date0003 } = parse("0003", "{0YYYY}")
    assert { :ok, ^date0003 } = parse("   3", "{_YYYY}")
    assert { :ok, ^date2003 } = parse("3", "{YY}")
    assert { :ok, ^date2003 } = parse("03", "{YY}")
    assert {:error, "Expected `2 digit year` at line 1, column 1."} = parse(" 3", "{YY}")
    assert { :ok, ^date2003 } = parse("03", "{0YY}")
    assert { :ok, ^date2003 } = parse(" 3", "{_YY}")
  end

  test "parse century" do
    date2000 = Date.from({2000,1,1})
    date1900 = Date.from({1900,1,1})
    date0000 = Date.from({0,1,1})
    assert { :ok, ^date2000 } = parse("20", "{C}")
    assert { :ok, ^date1900 } = parse("19", "{C}")
    assert { :ok, ^date0000 } = parse("0", "{C}")
    assert { :ok, ^date0000 } = parse("00", "{0C}")
    assert { :ok, ^date0000 } = parse(" 0", "{_C}")
  end

  test "parse month" do
    date = Date.from({0,3,1})
    assert { :ok, ^date } = parse("3", "{M}")
    assert { :ok, ^date } = parse("03", "{M}")
    assert {:error, "Expected `2 digit month` at line 1, column 1."} = parse(" 3", "{M}")
    assert { :ok, ^date } = parse("03", "{0M}")
    assert { :ok, ^date } = parse(" 3", "{_M}")
  end

  test "parse day" do
    date18 = Date.from({0,1,18})
    date8 = Date.from({0,1,8})

    assert { :ok, ^date18 } = parse("18", "{D}")
    assert { :ok, ^date18 } = parse("18", "{0D}")
    assert { :ok, ^date18 } = parse("18", "{_D}")
    assert { :ok, ^date8 } = parse("8", "{D}")
    assert { :ok, ^date8 } = parse("08", "{0D}")
    assert { :ok, ^date8 } = parse(" 8", "{_D}")
  end

  test "parse simple format YYYY-M-D, with padding variations" do
    date2013_11 = Date.from({2013,11,8})

    assert { :ok, ^date2013_11 } = parse("2013-11-08", "{YYYY}-{M}-{D}")
    assert {:error, "Expected `2 digit month` at line 1, column 6."} = parse("2013- 1- 8", "{YYYY}-{0M}-{0D}")
    assert { :ok, ^date2013_11 } = parse("20131108", "{0YYYY}{0M}{0D}")
  end

  test "parse ISO year4/year2" do
    date = Date.from({2007,1,1})
    year = date.year
    assert { :ok, %DateTime{year: ^year} } = parse("2007", "{WYYYY}")
    assert { :ok, %DateTime{year: ^year} } = parse("7"   , "{WYY}")
    assert { :ok, %DateTime{year: ^year} } = parse("07"  , "{0WYY}")
    assert { :ok, %DateTime{year: ^year} } = parse(" 7"  , "{_WYY}")
  end

  test "parse full and abbreviated month names" do
    date_nov = Date.from({0,11,1})
    assert { :ok, ^date_nov } = parse("Nov", "{Mshort}")
    assert { :ok, ^date_nov } = parse("November", "{Mfull}")

    date_mar = Date.from({0,3,1})
    assert { :ok, ^date_mar } = parse("Mar", "{Mshort}")
    assert { :ok, ^date_mar } = parse("March", "{Mfull}")

    assert {:error, "Input datetime string cannot be empty."} = parse("", "{0Mfull}")
    assert {:error, "Input datetime string cannot be empty."} = parse("", " {_Mshort}")
    assert {:error, "Expected `full month name` at line 1, column 1."} = parse("Apr", "{Mfull}")
    assert {:error, "Expected ` `, but found `J` at line 1, column 1."} = parse("January", " {Mshort}")
  end

  test "parse simple variations of year, month, and day directives" do
    date = Date.from({2013,8,18})
    assert { :ok, ^date } = parse("2013-8-18", "{YYYY}-{M}-{D}")
    assert { :ok, ^date } = parse("8 2013 18", "{M} {YYYY} {D}")

    date0003 = Date.from({3,8,8})
    date2003 = Date.from({2003,8,8})
    assert { :ok, ^date0003 } = parse("3/08/08", "{YYYY}/{0M}/{0D}")
    assert { :ok, ^date2003 } = parse("03 8 8", "{0YY}{_M}{_D}")
    assert { :ok, ^date2003 } = parse(" 8/08/ 3", "{_D}/{0M}/{_YY}")
  end

  test "parse hour24" do
    date_midnight = Date.from({0,1,1})
    assert { :ok, ^date_midnight } = parse("0", "{h24}")
    assert { :ok, ^date_midnight } = parse("00", "{0h24}")
    assert { :ok, ^date_midnight } = parse(" 0", "{_h24}")
    assert {:error, "Input datetime string cannot be empty."} = parse("", "{0am}")
    assert {:error, "Input datetime string cannot be empty."} = parse("", "{_AM}")
  end

  test "parse hour12 and am/AM" do
    date_midnight = Date.from({0,1,1})
    date_noon     = Date.set(date_midnight, hour: 12)

    assert { :ok, ^date_noon } = parse("am 12", "{am} {h12}")
    assert { :ok, ^date_midnight } = parse("PM 00", "{AM} {0h24}")
    date = Date.from({{0,1,1}, {16,0,0}})
    assert { :ok, ^date } = parse("4 pm", "{h12} {am}")
    assert { :ok, ^date } = parse("04 PM", "{0h12} {AM}")
    assert { :ok, ^date } = parse(" 4 pm", "{_h12} {am}")
  end

  test "parse simple time formats" do
    date = Date.from({{0,1,1}, {12,3,4}})
    assert { :ok, ^date } = parse("12: 3: 4", "{h24}:{_m}:{_s}")
    assert { :ok, ^date } = parse("12:03:04", "{h12}:{0m}:{0s}")
    assert { :ok, ^date } = parse("12:03:04 PM", "{h12}:{0m}:{0s} {AM}")
    assert { :error, "Expected `minute` at line 1, column 7." } = parse("pm 12:3:4", "{am} {h24}:{m}:{s}")
  end

  test "parse s-epoch" do
    date = Date.epoch |> Date.shift(years: 3, days: 12)
    secs = Date.to_secs(date, :epoch)
    assert { :ok, ^date } = parse("#{secs}", "{s-epoch}")
    assert { :ok, ^date } = parse("#{secs}", "{0s-epoch}")
    assert { :ok, ^date } = parse("#{secs}", "{_s-epoch}")

    date = Date.from({{2001,9,9},{1,46,40}})
    assert { :ok, ^date } = parse("1000000000", "{s-epoch}")

    date = Date.epoch()
    assert { :ok, ^date } = parse("0", "{s-epoch}")
    assert { :ok, ^date } = parse("0000000000", "{0s-epoch}")
    assert {:error, "Expected `seconds since epoch` at line 1, column 1."} = parse("  0", "{s-epoch}")
    assert { :ok, ^date } = parse(" 0", "{_s-epoch}")
  end

  test "parse RFC1123" do
    date_gmt = Date.from({{2013,3,5},{23,25,19}}, "GMT")
    date_utc = Date.from({{2013,3,5},{23,25,19}}, "UTC")
    date_eet = Date.from({{2013,3,5},{23,25,19}}, "EEST")

    # * `{RFC1123}`     - e.g. `Tue, 05 Mar 2013 23:25:19 GMT`
    assert { :ok, ^date_gmt } = parse("Tue, 05 Mar 2013 23:25:19 GMT", "{RFC1123}")
    assert { :ok, ^date_eet } = parse("Tue, 05 Mar 2013 23:25:19 EEST", "{RFC1123}")

    # * `{RFC1123z}`    - e.g. `Tue, 05 Mar 2013 23:25:19 +0200`
    assert { :ok, ^date_utc } = parse("Tue, 05 Mar 2013 23:25:19 Z", "{RFC1123z}")
    date_utc_at_one = Date.from({{2013,3,6},{1,25,19}})
    assert { :ok, ^date_utc_at_one } = parse("Tue, 06 Mar 2013 01:25:19 Z", "{RFC1123z}")
  end

  test "parse RFC822" do
    # * `{RFC822}`      - e.g. `Mon, 05 Jun 14 23:20:59 UT`
    date = Date.from({{2014, 6, 5}, {23, 20, 59}}, "Etc/GMT+12")
    assert { :ok, ^date } = parse("Mon, 05 Jun 14 23:20:59 Y", "{RFC822}")

    # * `{RFC822z}`     - e.g. `Mon, 05 Jun 14 23:20:59 Z`
    date = Date.from({{2014, 6, 5}, {23, 20, 59}}, "UTC")
    assert { :ok, ^date } = parse("Mon, 05 Jun 14 23:20:59 Z", "{RFC822z}")
  end

  test "parse RFC3339" do
    # * `{RFC3339}`     - e.g. `2013-03-05T23:25:19+02:00`
    date = Date.from({{2013, 3, 5}, {23, 25, 19}}, "GMT-2")
    assert { :ok, ^date } = parse("2013-03-05T23:25:19+02:00", "{RFC3339}")

    # * `{RFC3339z}`    - e.g. `2013-03-05T23:25:19Z`
    date = Date.from({{2013, 3, 5}, {23, 25, 19}}, "UTC")
    assert { :ok, ^date } = parse("2013-03-05T23:25:19Z", "{RFC3339z}")
  end

  test "parse ANSIC" do
    # * `{ANSIC}`       - e.g. `Tue Mar  5 23:25:19 2013`
    date = Date.from({{2013, 3, 5}, {23, 25, 19}})
    assert { :ok, ^date } = parse("Tue Mar  5 23:25:19 2013", "{ANSIC}")
  end

  test "parse UNIX" do
    # * `{UNIX}`        - e.g. `Tue Mar  5 23:25:19 EET 2013`
    date = Date.from({{2013, 3, 5}, {23, 25, 19}}, "EET")
    assert { :ok, ^date } = parse("Tue Mar  5 23:25:19 EET 2013", "{UNIX}")
  end

  test "parse kitchen" do
    # * `{kitchen}`     - e.g. `3:25PM`
    date = Date.now |> Date.set(hour: 15, minute: 25, second: 0, ms: 0)
    assert { :ok, ^date } = parse("3:25PM", "{kitchen}")
  end

  test "parse ISO8601" do
    date1 = Date.from({{2014, 8, 14}, {12, 34, 33}})
    date2 = %{date1 | :ms => 199}

    assert { :ok, ^date1 } = parse("2014-08-14T12:34:33+00:00", "{ISO}")
    assert { :ok, ^date1 } = parse("2014-08-14T12:34:33+0000", "{ISO}")
    assert { :ok, ^date1 } = parse("2014-08-14T12:34:33+00", "{ISO}")
    assert { :ok, ^date1 } = parse("2014-08-14T12:34:33Z", "{ISO}")
    assert { :ok, ^date1 } = parse("2014-08-14T12:34:33Z", "{ISOz}")

    assert { :ok, ^date2 } = parse("2014-08-14T12:34:33.199+00:00", "{ISO}")
    assert { :ok, ^date2 } = parse("2014-08-14T12:34:33.199+0000", "{ISO}")
    assert { :ok, ^date2 } = parse("2014-08-14T12:34:33.199+00", "{ISO}")
    assert { :ok, ^date2 } = parse("2014-08-14T12:34:33.199Z", "{ISO}")
    assert { :ok, ^date2 } = parse("2014-08-14T12:34:33.199Z", "{ISOz}")

    date3 = Date.from({{2014, 8, 14}, {12, 34, 33}}, "Etc/GMT+5")
    assert { :ok, ^date3 } = parse("2014-08-14T12:34:33-05:00", "{ISO}")
    assert { :ok, ^date3 } = parse("2014-08-14T12:34:33-0500", "{ISO}")
    assert { :ok, ^date3 } = parse("2014-08-14T12:34:33-05", "{ISO}")
  end


  defp parse(date, fmt) do
    DateFormat.parse(date, fmt)
  end
end
