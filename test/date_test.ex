defmodule DateTest do
  use ExUnit.Case, async: true

  test :from_date do
    date = {2000, 11, 11}
    assert Date.local(Date.from(date)) == {date, {0,0,0}}

    { datetime, tz } = Date.from(date, :local)
    assert tz == Date.timezone()
    assert Date.local(Date.from(date, :local)) == {date, {0,0,0}}

    { datetime, tz } = Date.from(date)
    assert tz == Date.timezone(:utc)
    assert datetime == {{2000,11,11}, {0,0,0}}

    { datetime, _ } = date = Date.from(date, Date.timezone(2, "EET"))
    assert datetime == {{2000,11,10}, {22,0,0}}
    assert Date.local(date) == {{2000,11,11}, {0,0,0}}

    { datetime, _ } = date = Date.from({2013,3,16}, Date.timezone(-8, "PST"))
    assert datetime == {{2013,3,16}, {8,0,0}}
    assert Date.local(date) == {{2013,3,16}, {0,0,0}}
  end

  test :from_datetime do
    assert Date.from({{1970,1,1}, {0,0,0}}) == Date.from({1970,1,1})
    assert Date.to_sec(Date.from({{1970,1,1}, {0,0,0}})) == 0

    date = {{2000, 11, 11}, {0, 0, 0}}
    assert Date.local(Date.from(date)) == date

    { datetime, tz } = Date.from(date, :local)
    assert tz == Date.timezone()

    { datetime, tz } = Date.from(date)
    assert tz == Date.timezone(:utc)
    assert datetime == date

    { datetime, _ } = Date.from(date, Date.timezone(2, "EET"))
    assert datetime == {{2000,11,10}, {22,0,0}}

  end

  test :from_timestamp do
    now = Time.now
    assert Date.to_sec(Date.from(now, :timestamp)) == trunc(Time.to_sec(now))
    assert Date.to_sec(Date.from({0,0,0}, :timestamp)) == 0
    assert Date.to_sec(Date.from({0,0,0}, :timestamp, 0)) == -Date.epoch(:sec)
  end

  test :from_sec do
    now = Time.now(:sec)
    assert Date.to_sec(Date.from(now, :sec)) == trunc(now)
    assert Date.to_sec(Date.from(now, :sec, 0)) == trunc(now) - Date.epoch(:sec)
  end

  test :from_days do
    assert Date.local(Date.from(30, :days)) == {{1970,1,31}, {0,0,0}}
    assert Date.local(Date.from(31, :days)) == {{1970,2,1}, {0,0,0}}
  end

  test :zero do
    {datetime, _} = Date.zero()
    assert :calendar.datetime_to_gregorian_seconds(datetime) == 0
  end

  test :epoch do
    assert Date.epoch() == { {{1970,1,1}, {0,0,0}}, {0.0, "UTC"} }
    assert Date.to_sec(Date.epoch) == 0
    assert Date.to_days(Date.epoch) == 0
    assert Date.to_sec(Date.epoch, 0) == Date.epoch(:sec)
    assert Date.to_days(Date.epoch, 0) == Date.epoch(:days)
    assert Date.to_timestamp(Date.epoch) == Date.epoch(:timestamp)
  end

  test :iso_format do
    eet = Date.timezone(2, "EET")
    pst = Date.timezone(-8, "PST")
    date = {{2013,3,5},{23,25,19}}

    assert Date.iso_format(Date.from(date, eet), :utc) == "2013-03-05 21:25:19Z"
    assert Date.iso_format(Date.from(date, eet), :local) == "2013-03-05 23:25:19"
    assert Date.iso_format(Date.from(date, pst), :full) == "2013-03-05 23:25:19-0800"
  end

  test :rfc_format do
    eet = Date.timezone(2, "EET")
    date = Date.from({{2013,3,5},{23,25,19}}, eet)
    assert Date.rfc_format(date) == "Tue, 05 Mar 2013 21:25:19 GMT"

    eet = Date.timezone(-8, "PST")
    date = Date.from({{2013,3,5},{23,25,19}}, eet)
    assert Date.rfc_format(date) == "Wed, 06 Mar 2013 07:25:19 GMT"
  end

  test :convert do
    date = Date.now()
    assert Date.convert(date, :sec) + Date.epoch(:sec) == Date.to_sec(date, 0)
    assert Date.convert(date, :days) + Date.epoch(:days) == Date.to_days(date, 0)
  end

  test :to_timestamp do
    assert Date.to_timestamp(Date.epoch()) == {0,0,0}
    assert Date.to_timestamp(Date.epoch(), 0) == {62167,219200,0}
    assert Time.to_sec(Date.to_timestamp(Date.epoch(), 0)) == Date.epoch(:sec)
  end

  test :to_sec do
    date = Date.now()
    assert Date.to_sec(date, 0) == :calendar.datetime_to_gregorian_seconds(Date.universal(date))
    assert Date.to_sec(date, 0) - Date.epoch(:sec) == Date.to_sec(date)
    assert Date.to_sec(Date.now()) == trunc(Time.now(:sec))

    date = Date.from({{1999,1,2}, {12,13,14}})
    assert Date.to_sec(date) == 915279194
    assert Date.to_sec(date, 0) == 63082498394

    assert Date.to_sec(Date.epoch()) == 0
    assert Date.to_sec(Date.epoch(), 0) == 62167219200
  end

  test :to_days do
    date = Date.from({2013,3,16})
    assert Date.to_days(date) == 15780
    assert Date.to_days(date, 0) == 735308

    assert Date.to_days(Date.epoch()) == 0
    assert Date.to_days(Date.epoch(), 0) == 719528
  end

  test :weekday do
    localdate = {{2013,3,17},{11,59,10}}
    assert Date.weekday(localdate) == 7
    assert Date.weekday(Date.from(localdate)) == 7
    assert Date.weekday(Date.epoch()) == 4
  end

  test :weeknum do
    localdate = {{2013,3,17},{11,59,10}}
    assert Date.weeknum(localdate) == {2013,11}
    assert Date.weeknum(Date.from(localdate)) == {2013,11}
    assert Date.weeknum(Date.epoch()) == {1970,1}
  end

  test :iso_triplet do
    localdate = {{2013,3,17},{11,59,10}}
    assert Date.iso_triplet(Date.from(localdate)) == {2013,11,7}
    assert Date.iso_triplet(Date.epoch()) == {1970,1,4}
  end

  test :days_in_month do
    localdate = {{2013,2,17},{11,59,10}}
    assert Date.days_in_month(Date.from(localdate)) == 28
    assert Date.days_in_month(Date.epoch()) == 31
    assert Date.days_in_month(2012, 2) == 29
    assert Date.days_in_month(2013, 2) == 28
  end

  test :is_leap do
    assert Date.is_leap(Date.epoch()) == false
    assert Date.is_leap(2012) == true
  end

  test :is_valid do
    raise NotImplemented
  end

  test :normalize do
    raise NotImplemented
  end

  test :replace do
    raise NotImplemented
  end

  test :shift_seconds do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert Date.shift(datetime, 0, :sec) == datetime

    assert Date.shift(datetime, 1, :sec) == {date,{23,23,24}}
    assert Date.shift(datetime, 36, :sec) == {date,{23,23,59}}
    assert Date.shift(datetime, 37, :sec) == {date,{23,24,0}}
    assert Date.shift(datetime, 38, :sec) == {date,{23,24,1}}
    assert Date.shift(datetime, 38+60, :sec) == {date,{23,25,1}}
    assert Date.shift(datetime, 38+60*35+58, :sec) == {date,{23,59,59}}
    assert Date.shift(datetime, 38+60*35+59, :sec) == {{2013,3,6},{0,0,0}}
    assert Date.shift(datetime, 38+60*36, :sec) == {{2013,3,6},{0,0,1}}
    assert Date.shift(datetime, 24*3600, :sec) == {{2013,3,6},{23,23,23}}
    assert Date.shift(datetime, 24*3600*365, :sec) == {{2014,3,5},{23,23,23}}

    assert Date.shift(datetime, -1, :sec) == {date,{23,23,22}}
    assert Date.shift(datetime, -23, :sec) == {date,{23,23,0}}
    assert Date.shift(datetime, -24, :sec) == {date,{23,22,59}}
    assert Date.shift(datetime, -23*60, :sec) == {date,{23,0,23}}
    assert Date.shift(datetime, -24*60, :sec) == {date,{22,59,23}}
    assert Date.shift(datetime, -23*3600-23*60-23, :sec) == {date,{0,0,0}}
    assert Date.shift(datetime, -23*3600-23*60-24, :sec) == {{2013,3,4},{23,59,59}}
    assert Date.shift(datetime, -24*3600, :sec) == {{2013,3,4},{23,23,23}}
    assert Date.shift(datetime, -24*3600*365, :sec) == {{2012,3,5},{23,23,23}}
    assert Date.shift(datetime, -24*3600*(365*2 + 1), :sec) == {{2011,3,5},{23,23,23}}   # +1 day for leap year 2012
  end

  test :shift_minutes do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert Date.shift(datetime, 0, :min) == datetime

    assert Date.shift(datetime, 1, :min) == {date,{23,24,23}}
    assert Date.shift(datetime, 36, :min) == {date,{23,59,23}}
    assert Date.shift(datetime, 37, :min) == {{2013,3,6},{0,0,23}}
    assert Date.shift(datetime, 38, :min) == {{2013,3,6},{0,1,23}}
    assert Date.shift(datetime, 60*24*365, :min) == {{2014,3,5},{23,23,23}}

    assert Date.shift(datetime, -1, :min) == {date,{23,22,23}}
    assert Date.shift(datetime, -23, :min) == {date,{23,0,23}}
    assert Date.shift(datetime, -24, :min) == {date,{22,59,23}}
    assert Date.shift(datetime, -23*60-24, :min) == {{2013,3,4},{23,59,23}}
    assert Date.shift(datetime, -60*24*(365*2 + 1), :min) == {{2011,3,5},{23,23,23}}
  end

  test :shift_days do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }
    assert Date.shift(datetime, 1, :days) == { {2013,3,6}, time }
  end

  test :shift_months do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }
    assert Date.shift(datetime, 3, :months) == { {2013,6,5}, time }
  end

  test :arbitrary_shifts do
    datetime = { {2013,3,5}, {23,23,23} }
    assert Date.shift(datetime, [{3, :months}, {1, :days}]) == { {2013,6,6}, {23,23,23} }

    datetime = { {2012,2,29}, {23,23,23} }
    assert Date.shift(datetime, [{12, :months}]) == { {2013,2,28}, {23,23,23} }
    assert Date.shift(datetime, [{12, :months}, {1, :days}]) == { {2013,3,1}, {23,23,23} }
    assert Date.shift(datetime, [{12, :months}, {36, :min}, {36, :sec}]) == { {2013,2,28}, {23,59,59} }
    assert Date.shift(datetime, [{12, :months}, {36, :min}, {37, :sec}]) == { {2013,3,1}, {0,0,0} }
  end
end
