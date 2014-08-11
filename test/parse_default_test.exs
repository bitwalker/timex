defmodule DateFormatTest.ParseDefault do
  use ExUnit.Case, async: true
  use Timex

  test :parse_literal do
    assert {:error, "There were no parsing directives in the provided string."} = parse("hello", "hello")
    assert {:error, "There were no parsing directives in the provided string."} = parse("hello1", "hello")
    assert {:error, "There were no parsing directives in the provided string."} = parse("áîü≤≥Ø", "áîü≤≥")

    assert {:error, "There were no parsing directives in the provided string."} = parse("h", "hello")
  end

  test :parse_year do
    date2013 = Date.from({2013,1,1})
    date2003 = Date.from({2003,1,1})
    date2000 = Date.from({2000,1,1})
    date1913 = Date.from({1913,1,1})
    date1900 = Date.from({1900,1,1})
    date0003 = Date.from({3,1,1})
    date0000 = Date.from({0,1,1})

    assert { :ok, ^date2013 } = parse("2013", "{YYYY}")
    assert { :ok, ^date2013 } = parse("13", "{YY}")
    assert { :ok, ^date2000 } = parse("20", "{C}")
    assert { :ok, ^date1900 } = parse("19", "{C}")
    assert { :ok, ^date0000 } = parse("0", "{C}")
    assert { :ok, ^date0000 } = parse("00", "{0C}")
    assert { :ok, ^date0000 } = parse(" 0", "{_C}")

    assert { :ok, ^date0003 } = parse("3", "{YYYY}")
    assert { :ok, ^date0003 } = parse("0003", "{YYYY}")
    assert { :ok, ^date0003 } = parse("   3", "{YYYY}")
    assert { :ok, ^date0003 } = parse("0003", "{0YYYY}")
    assert { :ok, ^date0003 } = parse("   3", "{_YYYY}")
    assert { :ok, ^date2003 } = parse("3", "{YY}")
    assert { :ok, ^date2003 } = parse("03", "{YY}")
    assert { :ok, ^date2003 } = parse(" 3", "{YY}")
    assert { :ok, ^date2003 } = parse("03", "{0YY}")
    assert { :ok, ^date2003 } = parse(" 3", "{_YY}")

    assert { :ok, ^date2013 } = parse("20 13", "{C} {YY}")
    assert { :ok, ^date2013 } = parse("20    13", "{C} {YY}")
    assert { :ok, ^date1913 } = parse("13 20", "{YY} {C}")
    assert { :ok, ^date1913 } = parse("13    20", "{YY} {C}")
    assert {:error, "Unexpected end of string! Starts at:  20"} = parse("0013 20", "{YY} {C}")
    assert {:error, "Unexpected end of string! Starts at:  00020"} = parse("0013 00020", "{YY} {C}")
    assert {:error, "Unexpected end of string! Starts at:     20"} = parse("0013    20", "{YY} {C}")
  end

  test :parse_month do
    date = Date.from({0,3,1})
    assert { :ok, ^date } = parse("3", "{M}")
    assert { :ok, ^date } = parse("03", "{M}")
    assert { :ok, ^date } = parse(" 3", "{M}")
    assert { :ok, ^date } = parse("03", "{0M}")
    assert { :ok, ^date } = parse(" 3", "{_M}")
  end

  test :parse_day do
    date18 = Date.from({0,1,18})
    date8 = Date.from({0,1,8})

    assert { :ok, ^date18 } = parse("18", "{D}")
    assert { :ok, ^date18 } = parse("18", "{0D}")
    assert { :ok, ^date18 } = parse("18", "{_D}")
    assert { :ok, ^date8 } = parse("8", "{D}")
    assert { :ok, ^date8 } = parse("08", "{0D}")
    assert { :ok, ^date8 } = parse(" 8", "{_D}")
  end

  test :parse_year_month_day do
    date2013_11 = Date.from({2013,11,8})
    date2013_01 = Date.from({2013,1,8})

    assert { :ok, ^date2013_11 } = parse("2013-11-08", "{YYYY}-{M}-{D}")
    assert { :ok, ^date2013_01 } = parse("2013- 1- 8", "{YYYY}-{0M}-{0D}")
    assert { :ok, ^date2013_11 } = parse("20131108", "{0YYYY}{0M}{0D}")
  end

  #test :format_iso_year do
    #date = Date.from({2007,11,19})
    #assert { :ok, ^date, "" } = parse("2007", "{WYYYY}")
    #assert { :ok, ^date, "" } = parse("7"   , "{WYY}")
    #assert { :ok, ^date, "" } = parse("07"  , "{0WYY}")
    #assert { :ok, ^date, "" } = parse(" 7"  , "{_WYY}")

    #date = Date.from({2006,1,1})
    #assert { :ok, ^date, "" } = parse("2005", "{WYYYY}")
    #assert { :ok, ^date, "" } = parse("5"   , "{WYY}")
    #assert { :ok, ^date, "" } = parse("05"  , "{0WYY}")
    #assert { :ok, ^date, "" } = parse(" 5"  , "{_WYY}")
  #end

  test :format_month_name do
    date_nov = Date.from({0,11,1})
    assert { :ok, ^date_nov } = parse("Nov", "{Mshort}")
    assert { :ok, ^date_nov } = parse("November", "{Mfull}")

    date_mar = Date.from({0,3,1})
    assert { :ok, ^date_mar } = parse("Mar", "{Mshort}")
    assert { :ok, ^date_mar } = parse("March", "{Mfull}")

    assert {:error, "Input string cannot be empty"} = parse("", "{0Mfull}")
    assert {:error, "Input string cannot be empty"} = parse("", " {_Mshort}")
    #assert { :error, "at 0: bad directive" } = parse("Apr", "{Mfull}")
    #assert { :error, "at 1: bad directive" } = parse("January", " {Mshort}")
  end

  #test :format_ordinal_day do
    #date = Date.from({3,2,1})

    #assert { :ok, "32" }  = format(date, "{Dord}")
    #assert { :ok, "032" } = format(date, "{0Dord}")
    #assert { :ok, " 32" } = format(date, "{_Dord}")

    #date = Date.from({3,12,31})
    #assert { :ok, "365" } = format(date, "{Dord}")

    #date = Date.from({3,1,1})
    #assert { :ok, "001" } = format(date, "{0Dord}")
  #end

  #test :format_weekday do
    #date = Date.from({2007,11,18})
    #assert { :ok, "0" } = format(date, "{WDsun}")
    #assert { :ok, "7" } = format(date, "{WDmon}")
    #assert { :error, "at 0: bad directive" } = format(date, "{0WDsun}")
    #assert { :error, "at 0: bad directive" } = format(date, "{0WDmon}")
    #assert { :error, "at 0: bad directive" } = format(date, "{_WDsun}")
    #assert { :error, "at 0: bad directive" } = format(date, "{_WDmon}")
  #end

  #test :format_weekday_name do
    #assert { :ok, "Mon" } = format(Date.from({2012,12,31}), "{WDshort}")
    #assert { :ok, "Tue" } = format(Date.from({2013,1,1}), "{WDshort}")
    #assert { :ok, "Wed" } = format(Date.from({2013,1,2}), "{WDshort}")
    #assert { :ok, "Thu" } = format(Date.from({2013,1,3}), "{WDshort}")
    #assert { :ok, "Fri" } = format(Date.from({2013,1,4}), "{WDshort}")
    #assert { :ok, "Sat" } = format(Date.from({2013,1,5}), "{WDshort}")
    #assert { :ok, "Sun" } = format(Date.from({2013,1,6}), "{WDshort}")
    #assert { :error, "at 0: bad directive" } = format(Date.from({2013,1,6}), "{0WDshort}")
    #assert { :error, "at 0: bad directive" } = format(Date.from({2013,1,6}), "{_WDshort}")

    #assert { :ok, "Monday" }    = format(Date.from({2012,12,31}), "{WDfull}")
    #assert { :ok, "Tuesday" }   = format(Date.from({2013,1,1}), "{WDfull}")
    #assert { :ok, "Wednesday" } = format(Date.from({2013,1,2}), "{WDfull}")
    #assert { :ok, "Thursday" }  = format(Date.from({2013,1,3}), "{WDfull}")
    #assert { :ok, "Friday" }    = format(Date.from({2013,1,4}), "{WDfull}")
    #assert { :ok, "Saturday" }  = format(Date.from({2013,1,5}), "{WDfull}")
    #assert { :ok, "Sunday" }    = format(Date.from({2013,1,6}), "{WDfull}")
    #assert { :error, "at 0: bad directive" } = format(Date.from({2013,1,6}), "{0WDfull}")
    #assert { :error, "at 0: bad directive" } = format(Date.from({2013,1,6}), "{_WDfull}")
  #end

  #test :format_iso_week do
    #date = Date.from({2007,11,19})
    #assert { :ok, "47" } = format(date, "{Wiso}")
    #assert { :ok, "47" } = format(date, "{0Wiso}")
    #assert { :ok, "47" } = format(date, "{_Wiso}")

    #date = Date.from({2007,1,1})
    #assert { :ok, "1" }  = format(date, "{Wiso}")
    #assert { :ok, "01" } = format(date, "{0Wiso}")
    #assert { :ok, " 1" } = format(date, "{_Wiso}")
  #end

  #test :format_ordinal_week do
    #date = Date.from({2013,1,1})
    #assert { :ok, "0" } = format(date, "{Wmon}")
    #assert { :ok, "0" } = format(date, "{Wsun}")

    #date = Date.from({2013,1,6})
    #assert { :ok, "00" } = format(date, "{0Wmon}")
    #assert { :ok, "01" } = format(date, "{0Wsun}")

    #date = Date.from({2013,1,7})
    #assert { :ok, " 1" } = format(date, "{_Wmon}")
    #assert { :ok, " 1" } = format(date, "{_Wsun}")

    #date = Date.from({2012,1,1})
    #assert { :ok, "0" } = format(date, "{Wmon}")
    #assert { :ok, "1" } = format(date, "{Wsun}")

    #date = Date.from({2012,1,2})
    #assert { :ok, "1" } = format(date, "{Wmon}")
    #assert { :ok, "1" } = format(date, "{Wsun}")

    #date = Date.from({2012,12,31})
    #assert { :ok, "53" } = format(date, "{Wmon}")
    #assert { :ok, "53" } = format(date, "{Wsun}")
  #end

  test :parse_dates do
    date = Date.from({2013,8,18})
    assert { :ok, ^date } = parse("2013-8-18", "{YYYY}-{M}-{D}")
    assert { :ok, ^date } = parse("8 2013 18", "{M} {YYYY} {D}")

    date0003 = Date.from({3,8,8})
    date2003 = Date.from({2003,8,8})
    assert { :ok, ^date0003 } = parse("3/08/08", "{YYYY}/{0M}/{0D}")
    assert { :ok, ^date2003 } = parse("03 8 8", "{0YY}{_M}{_D}")
    assert { :ok, ^date2003 } = parse(" 8/08/ 3", "{_D}/{0M}/{_YY}")
  end

  test :format_time do
    date_midnight = Date.from({0,1,1})
    date_noon     = Date.set(date_midnight, hour: 12)
    assert { :ok, ^date_midnight } = parse("0", "{h24}")
    assert { :ok, ^date_midnight } = parse("00", "{0h24}")
    assert { :ok, ^date_midnight } = parse(" 0", "{_h24}")
    assert { :ok, ^date_noon } = parse("am 12", "{am} {h12}")
    assert { :ok, ^date_midnight } = parse("PM 00", "{AM} {0h24}")
    assert {:error, "Input string cannot be empty"} = parse("", "{0am}")
    assert {:error, "Input string cannot be empty"} = parse("", "{_AM}")

    #date = Date.from({{0,1,1}, {16,0,0}})
    #assert { :ok, ^date, "" } = parse("4 pm", "{h12} {am}")
    #assert { :ok, ^date, "" } = parse("04 PM", "{0h12} {AM}")
    #assert { :ok, ^date, "" } = parse(" 4 pm", "{_h12} {am}")

    #date = Date.from({{0,1,1}, {12,3,4}})
    #assert { :ok, ^date, "" } = parse("12: 3: 4", "{h24}:{_m}:{_s}")
    #assert { :ok, ^date, "" } = parse("12:03:04", "{h12}:{0m}:{0s}")
    #assert { :ok, ^date, "" } = parse("12:03:04 PM", "{h12}:{0m}:{0s} {AM}")
    #assert { :ok, ^date, "" } = parse("pm 12:3:4", "{am} {h24}:{m}:{s}")

    #assert { :ok, ^date, "" } = parse("1376827384", "{s-epoch}")
    #assert { :ok, ^date, "" } = parse("1376827384", "{0s-epoch}")
    #assert { :ok, ^date, "" } = parse("1376827384", "{_s-epoch}")

    #date = Date.from({{2001,9,9},{1,46,40}})
    #assert { :ok, ^date, "" } = parse("1000000000", "{s-epoch}")

    #date = Date.epoch()
    #assert { :ok, ^date, "" } = parse("0", "{s-epoch}")
    #assert { :ok, ^date, "" } = parse("0000000000", "{0s-epoch}")
    #assert { :ok, ^date, "" } = parse("         0", "{_s-epoch}")
  end

  #test :format_zones do
    #eet = Date.timezone(2.0, "EET")
    #date = Date.from({2007,11,19}, eet)
    #assert { :ok, "EET" } = format(date, "{Zname}")
    #assert { :ok, "+0200" } = format(date, "{Z}")
    #assert { :ok, "+02:00" } = format(date, "{Z:}")
    #assert { :ok, "+02:00:00" } = format(date, "{Z::}")

    #pst = Date.timezone(-8.0, "PST")
    #date = Date.from({2007,11,19}, pst)
    #assert { :ok, "PST" } = format(date, "{Zname}")
    #assert { :ok, "-0800" } = format(date, "{Z}")
    #assert { :ok, "-08:00" } = format(date, "{Z:}")
    #assert { :ok, "-08:00:00" } = format(date, "{Z::}")

    #assert { :error, "at 0: bad directive" } = format(date, "{0Zname}")
    #assert { :error, "at 0: bad directive" } = format(date, "{_Z}")
    #assert { :error, "at 0: bad directive" } = format(date, "{0Z:}")
    #assert { :error, "at 0: bad directive" } = format(date, "{_Z::}")
  #end

  #test :format_compound_iso do
    #eet = Date.timezone(2, "EET")
    #date = Date.from({{2013,3,5},{23,25,19}}, eet)
    #assert { :ok, "2013-03-05T23:25:19+0200" } = format(date, "{ISO}")
    #assert { :ok, "2013-03-05T21:25:19Z" }     = format(date, "{ISOz}")

    #pst = Date.timezone(-8, "PST")
    #local = {{2013,3,5},{23,25,19}}
    #assert { :ok, "2013-03-05T23:25:19-0800" } = format(Date.from(local, pst), "{ISO}")
    #assert { :ok, "2013-03-05T23:25:19+0000" } = format(Date.from(local, :utc), "{ISO}")


    #date = Date.from({{2007,11,19}, {1,37,48}}, eet)

    #assert { :ok, "2007-11-18" } = format(date, "{ISOdate}")
    #assert { :ok, "20071119" }   = format(date, "{0YYYY}{0M}{0D}")
    #assert { :ok, "0007-01-02" } = format(Date.from({7,1,2}), "{ISOdate}")

    #assert { :ok, "23:37:48" } = format(date, "{ISOtime}")
    #assert { :ok, "01:37:48" } = format(date, "{0h24}:{0m}:{0s}")
    #assert { :ok, "23:03:09" } = format(Date.from({{1,2,3},{23,3,9}}), "{ISOtime}")
    #assert { :ok, "23:03:09" } = format(Date.from({{1,2,3},{23,3,9}}), "{0h24}:{0m}:{0s}")

    #assert { :ok, "2007-W47" }   = format(date, "{ISOweek}")
    #assert { :ok, "2007-W47-1" } = format(date, "{ISOweek}-{WDmon}")
    #assert { :ok, "2007-W47-1" } = format(date, "{ISOweek-day}")
    #assert { :ok, "2007W471" }   = format(date, "{0WYYYY}W{0Wiso}{WDmon}")

    #assert { :ok, "2007-322" }   = format(date, "{ISOord}")
    #assert { :ok, "2007-323" }   = format(date, "{0YYYY}-{0Dord}")
  #end

  #test :format_compound_rfc1123 do
    #date = Date.from({{2013,3,5},{23,25,19}})
    #assert { :ok, "Tue, 05 Mar 2013 23:25:19 GMT" } = format(date, "{RFC1123}")
    #assert { :ok, "Tue, 05 Mar 2013 23:25:19 +0000" } = format(date, "{RFC1123z}")

    #eet = Date.timezone(2, "EET")
    #date = Date.from({{2013,3,5},{23,25,19}}, eet)
    #assert { :ok, "Tue, 05 Mar 2013 23:25:19 EET" } = format(date, "{RFC1123}")
    #assert { :ok, "Tue, 05 Mar 2013 23:25:19 +0200" } = format(date, "{RFC1123z}")

    #pst = Date.timezone(-8, "PST")
    #date = Date.from({{2013,3,5},{23,25,19}}, pst)
    #assert { :ok, "Tue, 05 Mar 2013 23:25:19 PST" } = format(date, "{RFC1123}")
    #assert { :ok, "Tue, 05 Mar 2013 23:25:19 -0800" } = format(date, "{RFC1123z}")
  #end

  #test :format_compound_rfc3339 do
    #local = {{2013,3,5},{23,25,19}}
    #date = Date.from(local)

    #assert { :ok, "2013-03-05T23:25:19Z" } = format(date, "{RFC3339}")

    #eet = Date.timezone(2.0, "EET")
    #assert { :ok, "2013-03-05T23:25:19+02:00" } = format(Date.from(local, eet), "{RFC3339}")
    #pst = Date.timezone(-8.0, "PST")
    #assert { :ok, "2013-03-05T23:25:19-08:00" } = format(Date.from(local, pst), "{RFC3339}")
  #end

  #test :format_compound_common do
    #local = {{2013,3,5},{23,25,19}}
    #date = Date.from(local)

    #pst = Date.timezone(-8.0, "PST")
    #assert { :ok, "Tue Mar  5 23:25:19 2013" } = format(date, "{ANSIC}")
    #assert { :ok, "Tue Mar  5 23:25:19 UTC 2013" } = format(date, "{UNIX}")
    #assert { :ok, "Tue Mar  5 23:25:19 PST 2013" } = format(Date.from(local, pst), "{UNIX}")

    #date = Date.from({{2013,3,5},{15,25,19}})
    #assert { :ok, "3:25PM" } = DateFormat.format(date, "{kitchen}")
  #end

  ## References:
  ## http://www.ruby-doc.org/core-2.0/Time.html#method-i-strftime
  ## http://golang.org/pkg/time/#pkg-constants
  #test :format_full do
    #minus6 = Date.timezone(-6, "")
    #date = Date.from({{2007,11,19}, {8,37,48}}, minus6)

    #assert { :ok, "083748-0600" } = format(date, "{0h24}{0m}{0s}{Z}")
    #assert { :ok, "08:37:48-06:00" } = format(date, "{0h24}:{0m}:{0s}{Z:}")
    #assert { :ok, "20071119T083748-0600" } = format(date, "{YYYY}{M}{D}T{0h24}{m}{s}{Z}")
    #assert { :ok, "2007-11-19T08:37:48-06:00" } = format(date, "{YYYY}-{M}-{D}T{0h24}:{m}:{s}{Z:}")
    #assert { :ok, "2007323T083748-0600" } = format(date, "{YYYY}{Dord}T{0h24}{m}{s}{Z}")
    #assert { :ok, "2007-323T08:37:48-06:00" } = format(date, "{YYYY}-{Dord}T{0h24}:{m}:{s}{Z:}")
    #assert { :ok, "2007W471T083748-0600" } = format(date, "{WYYYY}W{Wiso}{WDmon}T{0h24}{m}{s}{Z}")
    #assert { :ok, "2007-W47-1T08:37:48-06:00" } = format(date, "{WYYYY}-W{Wiso}-{WDmon}T{0h24}:{m}:{s}{Z:}")

    #mst = Date.timezone(-7, "MST")
    #date = Date.from({{2007,11,9}, {8,37,48}}, mst)

    #assert { :ok, "20071109T0837" } = format(date, "{YYYY}{M}{0D}T{0h24}{m}")
    #assert { :ok, "2007-11-09T08:37" } = format(date, "{YYYY}-{M}-{0D}T{0h24}:{m}")

    #assert { :ok, "Fri Nov  9 08:37:48 2007" } = format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {YYYY}")
    #assert { :ok, "Fri Nov  9 08:37:48 MST 2007" } = format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {Zname} {YYYY}")
    #assert { :ok, "Fri Nov  9 08:37:48 -0700 2007" } = format(date, "{WDshort} {Mshort} {_D} {0h24}:{0m}:{0s} {Z} {YYYY}")
    #assert { :ok, "09 Nov 07 08:37" } = format(date, "{0D} {Mshort} {0YY} {0h24}:{0m}")

    #assert { :ok, "8:37AM" } = format(date, "{h12}:{0m}{AM}")
  #end

  #test :unicode do
    #date = Date.from({{2007,11,9}, {8,37,48}})
    #assert { :ok, "Fri å∫ç∂ {08…37…48} ¿UTC?" } = format(date, "{WDshort} å∫ç∂ {{{0h24}…{m}…{s}} ¿{Zname}?")
  #end

  #test :tokens do
    #date = Date.now()
    #assert {:ok, "" } = format(date, "")
    #assert {:ok, "abc" } = format(date, "abc")
    #assert {:ok, "Use { as oft{en as you like{" } = format(date, "Use {{ as oft{{en as you like{{")
    #assert {:ok, "Same go}}es for }}" } = format(date, "Same go}}es for }}")
    #assert {:ok, "{{abc}}" } = format(date, "{{{{abc}}")
    #assert {:ok, "abc } def" } = format(date, "abc } def")
  #end

  defp parse(date, fmt) do
    DateFormat.parse(date, fmt)
  end
end

