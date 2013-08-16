#Code.require_file "test_helper.exs", __DIR__

defmodule DTest do
  use ExUnit.Case, async: true

  alias Date, as: D

  test :timezone do
    assert D.timezone(:utc) === { 0.0, "UTC" }
    #assert D.timezone(2) === { 2.0, "EET" }
    #assert D.timezone("EET") === { 2.0, "EET" }
    assert D.timezone(2.0, "EET") === { 2.0, "EET" }
    #assert_raise ArgumentError, fn ->
      #D.timezone(3.0, "EET")
    #end
    assert {_, _} = D.timezone(:local)
  end

  test :now do
    # We cannot assert matching to a specific value. However, we can still do
    # some sanity checks
    now = D.now()
    assert {_, _, _} = D.Conversions.to_gregorian(now)

    {_, _, tz} = D.Conversions.to_gregorian(now)
    assert tz === D.timezone(:local)

    now_sec = D.now(:sec)
    now_days = D.now(:days)
    assert is_integer(now_sec)
    assert is_integer(now_days)
    assert now_sec > now_days
  end

  test :local do
    local = D.local()
    localdate = D.from(local, :local)
    assert local === D.local(localdate)

    if D.timezone() !== {2.0, "UTC"} do
      assert local !== D.universal(localdate)
    end

    tz = D.timezone(:local)
    assert local === D.local(localdate, tz)
  end

  test :universal do
    uni = D.universal()
    unidate = D.from(uni)
    assert uni === D.universal(unidate)
  end

  test :zero do
    { date, time, tz } = D.Conversions.to_gregorian(D.zero())
    assert :calendar.datetime_to_gregorian_seconds({date,time}) === 0
    assert tz === D.timezone(:utc)
  end

  test :epoch do
    epoch = D.epoch()
    assert D.Conversions.to_gregorian(epoch) === { {1970,1,1}, {0,0,0}, {0.0,"UTC"} }
    assert D.to_sec(epoch) === 0
    assert D.to_days(epoch) === 0
    assert D.to_sec(epoch, :zero) === D.epoch(:sec)
    assert D.to_days(epoch, :zero) === D.epoch(:days)
    assert D.to_timestamp(epoch) === D.epoch(:timestamp)
  end

  test :distant_past do
    assert D.compare(D.distant_past(), D.zero()) === 1
  end

  test :distant_future do
    # I wonder what the Earth will look like when this test fails
    assert D.compare(D.now(), D.distant_future()) === 1
  end

  test :from_date do
    date = {2000, 11, 11}
    assert D.universal(D.from(date)) === {date, {0,0,0}}

    { _, _, tz } = D.Conversions.to_gregorian(D.from(date, :local))
    assert tz === D.timezone()
    assert D.local(D.from(date, :local)) === {date, {0,0,0}}

    { date, time, tz } = D.Conversions.to_gregorian(D.from(date))
    assert tz === D.timezone(:utc)
    assert {date,time} === {{2000,11,11}, {0,0,0}}

    fulldate = D.from(date, D.timezone(2, "EET"))
    { date, time, _ } = D.Conversions.to_gregorian(fulldate)
    assert {date,time} === {{2000,11,10}, {22,0,0}}
    assert D.local(fulldate) === {{2000,11,11}, {0,0,0}}

    fulldate = D.from({2013,3,16}, D.timezone(-8, "PST"))
    { date, time, _ } = D.Conversions.to_gregorian(fulldate)
    assert {date,time} === {{2013,3,16}, {8,0,0}}
    assert D.local(fulldate) === {{2013,3,16}, {0,0,0}}
  end

  test :from_datetime do
    assert D.from({{1970,1,1}, {0,0,0}}) === D.from({1970,1,1})
    assert D.to_sec(D.from({{1970,1,1}, {0,0,0}})) === 0

    date = {{2000, 11, 11}, {1, 0, 0}}
    assert D.universal(D.from(date)) === date

    { _, _, tz } = D.Conversions.to_gregorian(D.from(date, :local))
    assert tz === D.timezone()

    { d, time, tz } = D.Conversions.to_gregorian(D.from(date))
    assert tz === D.timezone(:utc)
    assert {d,time} === date

    { d, time, _ } = D.Conversions.to_gregorian(D.from(date, D.timezone(2, "EET")))
    assert {d,time} === {{2000,11,10}, {23,0,0}}
  end

  test :from_timestamp do
    now = Time.now
    assert D.to_sec(D.from(now, :timestamp)) === trunc(Time.to_sec(now))
    assert D.to_sec(D.from({0,0,0}, :timestamp)) === 0
    assert D.to_sec(D.from({0,0,0}, :timestamp, :zero)) === -D.epoch(:sec)
  end

  test :from_sec do
    now_sec = trunc(Time.now(:sec))
    assert D.to_sec(D.from(now_sec, :sec)) === now_sec
    assert D.to_sec(D.from(now_sec, :sec, :zero)) === now_sec - D.epoch(:sec)
  end

  test :from_days do
    assert D.local(D.from(30, :days)) === {{1970,1,31}, {0,0,0}}
    assert D.local(D.from(31, :days)) === {{1970,2,1}, {0,0,0}}
  end

  test :iso_format do
    date = {{2013,3,5},{23,25,19}}

    eet = D.timezone(2, "EET")
    assert D.format(D.from(date, eet), :iso)       == "2013-03-05T21:25:19Z"
    assert D.format(D.from(date, eet), :iso_local) == "2013-03-05T23:25:19"
    assert D.format(D.from(date, eet), :iso_full)  == "2013-03-05T23:25:19+0200"

    pst = D.timezone(-8, "PST")
    assert D.format(D.from(date, pst), :iso_full)  == "2013-03-05T23:25:19-0800"

    assert D.format(D.from(date, :utc), :iso_full) == "2013-03-05T23:25:19+0000"

    assert D.format(D.from(date), :iso_week)    == "2013-W10"
    assert D.format(D.from(date), :iso_weekday) == "2013-W10-2"
    assert D.format(D.from(date), :iso_ordinal) == "2013-063"
  end

  test :rfc_format do
    date = {{2013,3,5},{23,25,19}}
    assert D.format(D.from(date), :rfc1123)  == "Tue, 05 Mar 2013 23:25:19 GMT"
    assert D.format(D.from(date), :rfc1123z) == "Tue, 05 Mar 2013 23:25:19 +0000"

    eet = D.timezone(2, "EET")
    date = D.from({{2013,3,5},{23,25,19}}, eet)
    assert D.format(date, :rfc1123)  == "Tue, 05 Mar 2013 23:25:19 EET"
    assert D.format(date, :rfc1123z) == "Tue, 05 Mar 2013 23:25:19 +0200"

    pst = D.timezone(-8, "PST")
    date = D.from({{2013,3,5},{23,25,19}}, pst)
    assert D.format(date, :rfc1123)  == "Tue, 05 Mar 2013 23:25:19 PST"
    assert D.format(date, :rfc1123z) == "Tue, 05 Mar 2013 23:25:19 -0800"
  end

  test :format do
    #assert nil
  end

  test :weekday_name do
    assert D.weekday_name(1, :short) == "Mon"
    assert D.weekday_name(7, :full) == "Sunday"
    assert_raise FunctionClauseError, fn ->
      D.weekday_name(0, :short)
      D.weekday_name(8, :full)
    end
  end

  test :month_name do
    assert D.month_name(1, :short) == "Jan"
    assert D.month_name(12, :full) == "December"
    assert_raise FunctionClauseError, fn ->
      D.month_name(0, :short)
      D.month_name(13, :full)
    end
  end

  test :convert do
    date = D.now()
    assert D.convert(date, :sec) + D.epoch(:sec) === D.to_sec(date, :zero)
    assert D.convert(date, :days) + D.epoch(:days) === D.to_days(date, :zero)
  end

  test :to_timestamp do
    assert D.to_timestamp(D.epoch()) === {0,0,0}
    assert D.to_timestamp(D.epoch(), :zero) === {62167,219200,0}
    assert Time.to_sec(D.to_timestamp(D.epoch(), :zero)) == D.epoch(:sec)
  end

  test :to_sec do
    date = D.now()
    assert D.to_sec(date, :zero) === :calendar.datetime_to_gregorian_seconds(D.universal(date))
    assert D.to_sec(date, :zero) - D.epoch(:sec) === D.to_sec(date)

    ts = Time.now()
    assert D.to_sec(D.from(ts, :timestamp)) === trunc(Time.to_sec(ts))

    date = D.from({{1999,1,2}, {12,13,14}})
    assert D.to_sec(date) === 915279194
    assert D.to_sec(date, :zero) === 63082498394

    assert D.to_sec(D.epoch()) === 0
    assert D.to_sec(D.epoch(), :zero) === 62167219200
  end

  test :to_days do
    date = D.from({2013,3,16})
    assert D.to_days(date) === 15780
    assert D.to_days(date, :zero) === 735308

    assert D.to_days(D.epoch()) === 0
    assert D.to_days(D.epoch(), :zero) === 719528
  end

  test :weekday do
    localdate = {{2013,3,17},{11,59,10}}
    assert D.weekday(localdate) === 7
    assert D.weekday(D.from(localdate)) === 7
    assert D.weekday(D.epoch()) === 4
  end

  test :weeknum do
    localdate = {{2013,3,17},{11,59,10}}
    assert D.weeknum(localdate) === {2013,11}
    assert D.weeknum(D.from(localdate)) === {2013,11}
    assert D.weeknum(D.epoch()) === {1970,1}
  end

  test :iso_triplet do
    localdate = {{2013,3,17},{11,59,10}}
    assert D.iso_triplet(D.from(localdate)) === {2013,11,7}
    assert D.iso_triplet(D.epoch()) === {1970,1,4}
  end

  test :days_in_month do
    localdate = {{2013,2,17},{11,59,10}}
    assert D.days_in_month(D.from(localdate)) == 28
    assert D.days_in_month(D.epoch()) == 31
    assert D.days_in_month(2012, 2) == 29
    assert D.days_in_month(2013, 2) == 28
  end

  test :is_leap do
    assert D.is_leap(D.epoch()) == false
    assert D.is_leap(2012) == true
  end

  test :is_valid do
    assert D.is_valid(D.now())
    assert D.is_valid(D.from({1,1,1}))
    assert D.is_valid(D.from({{1,1,1}, {1,1,1}}))
    assert not D.is_valid(D.from({12,13,14}))
    assert not D.is_valid(D.from({12,12,34}))
    assert not D.is_valid(D.from({{12,12,12}, {24,0,0}}))
    assert not D.is_valid(D.from({{12,12,12}, {23,60,0}}))
    assert not D.is_valid(D.from({{12,12,12}, {23,59,60}}))
    assert not D.is_valid(D.from({{12,12,12}, {-1,59,59}}))
  end

  test :normalize do
    date = D.now()
    assert D.normalize(date) == date

    date = { {1,13,44}, {-8,60,61} }
    assert D.local(D.normalize(D.from(date))) == { {1,12,31}, {0,59,59} }
  end

  test :replace do
    date = D.from({{2013,3,17}, {17,26,5}}, {2.0,"EET"})
    assert D.Conversions.to_gregorian(D.replace(date, :date, {1,1,1})) == { {1,1,1}, {15,26,5}, {2.0,"EET"} }
    assert D.Conversions.to_gregorian(D.replace(date, :hour, 0)) == { {2013,3,17}, {0,26,5}, {2.0,"EET"} }
    assert D.Conversions.to_gregorian(D.replace(date, :tz, D.timezone(:utc))) == { {2013,3,17}, {15,26,5}, {0.0,"UTC"} }

    assert D.Conversions.to_gregorian(D.replace(date, [date: {1,1,1}, hour: 13, sec: 61, tz: D.timezone(:utc)])) \
           == { {1,1,1}, {13,26,61}, {0.0,"UTC"} }
  end

  test :compare do
    assert D.compare(D.epoch(), D.zero()) == -1
    assert D.compare(D.zero(), D.epoch()) == 1

    date = {2013,3,18}
    tz1 = D.timezone(2)
    tz2 = D.timezone(-3)
    assert D.compare(D.from({date, {13,44,0}}, tz1), D.from({date, {8,44,0}}, tz2)) == 0

    tz3 = D.timezone(3)
    assert D.compare(D.from({date, {13,44,0}}, tz1), D.from({date, {13,44,0}}, tz3)) == -1

    date = D.now()
    assert D.compare(D.epoch(), date) == 1
  end

  test :diff do
    epoch = D.epoch()
    date1 = D.from({1971,1,1})
    date2 = D.from({1973,1,1})

    assert D.diff(epoch, date1, :days) == 365
    assert D.diff(epoch, date1, :sec) == 365 * 24 * 3600
    assert D.diff(epoch, date1, :years) == 1
    #assert D.diff(epoch, date1, :months) == 12

    # additional day is added because 1972 was a leap year
    assert D.diff(epoch, date2, :days) == 365*3 + 1
    assert D.diff(epoch, date2, :sec) == (365*3 + 1) * 24 * 3600
    assert D.diff(epoch, date2, :years) == 3
    #assert D.diff(epoch, date1, :months) == 36
  end

  test :shift_seconds do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert shift(datetime, 0, :sec) == datetime

    assert shift(datetime, 1, :sec) == {date,{23,23,24}}
    assert shift(datetime, 36, :sec) == {date,{23,23,59}}
    assert shift(datetime, 37, :sec) == {date,{23,24,0}}
    assert shift(datetime, 38, :sec) == {date,{23,24,1}}
    assert shift(datetime, 38+60, :sec) == {date,{23,25,1}}
    assert shift(datetime, 38+60*35+58, :sec) == {date,{23,59,59}}
    assert shift(datetime, 38+60*35+59, :sec) == {{2013,3,6},{0,0,0}}
    assert shift(datetime, 38+60*36, :sec) == {{2013,3,6},{0,0,1}}
    assert shift(datetime, 24*3600, :sec) == {{2013,3,6},{23,23,23}}
    assert shift(datetime, 24*3600*365, :sec) == {{2014,3,5},{23,23,23}}

    assert shift(datetime, -1, :sec) == {date,{23,23,22}}
    assert shift(datetime, -23, :sec) == {date,{23,23,0}}
    assert shift(datetime, -24, :sec) == {date,{23,22,59}}
    assert shift(datetime, -23*60, :sec) == {date,{23,0,23}}
    assert shift(datetime, -24*60, :sec) == {date,{22,59,23}}
    assert shift(datetime, -23*3600-23*60-23, :sec) == {date,{0,0,0}}
    assert shift(datetime, -23*3600-23*60-24, :sec) == {{2013,3,4},{23,59,59}}
    assert shift(datetime, -24*3600, :sec) == {{2013,3,4},{23,23,23}}
    assert shift(datetime, -24*3600*365, :sec) == {{2012,3,5},{23,23,23}}
    assert shift(datetime, -24*3600*(365*2 + 1), :sec) == {{2011,3,5},{23,23,23}}   # +1 day for leap year 2012
  end

  test :shift_minutes do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert shift(datetime, 0, :min) == datetime

    assert shift(datetime, 1, :min) == {date,{23,24,23}}
    assert shift(datetime, 36, :min) == {date,{23,59,23}}
    assert shift(datetime, 37, :min) == {{2013,3,6},{0,0,23}}
    assert shift(datetime, 38, :min) == {{2013,3,6},{0,1,23}}
    assert shift(datetime, 60*24*365, :min) == {{2014,3,5},{23,23,23}}

    assert shift(datetime, -1, :min) == {date,{23,22,23}}
    assert shift(datetime, -23, :min) == {date,{23,0,23}}
    assert shift(datetime, -24, :min) == {date,{22,59,23}}
    assert shift(datetime, -23*60-24, :min) == {{2013,3,4},{23,59,23}}
    assert shift(datetime, -60*24*(365*2 + 1), :min) == {{2011,3,5},{23,23,23}}
  end

  test :shift_days do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }
    assert shift(datetime, 1, :days) == { {2013,3,6}, time }
  end

  test :shift_months do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }
    assert shift(datetime, 3, :months) == { {2013,6,5}, time }
  end

  test :arbitrary_shifts do
    datetime = { {2013,3,5}, {23,23,23} }
    assert shift(datetime, [months: 3, days: 1]) == { {2013,6,6}, {23,23,23} }
    assert shift(datetime, [sec: 13, days: -1, weeks: 2]) == { {2013,3,18}, {23,23,36} }

    datetime = { {2012,2,29}, {23,23,23} }
    assert shift(datetime, [months: 12]) == { {2013,2,28}, {23,23,23} }
    assert shift(datetime, [months: 12, days: 1]) == { {2013,3,1}, {23,23,23} }
    assert shift(datetime, [months: 12, min: 36, sec: 36]) == { {2013,2,28}, {23,59,59} }
    assert shift(datetime, [months: 12, min: 36, sec: 37]) == { {2013,3,1}, {0,0,0} }
  end

  defp shift(date, spec) when is_list(spec) do
    D.local(D.shift(D.from(date), spec))
  end

  defp shift(date, value, type) do
    D.local(D.shift(D.from(date), value, type))
  end
end
