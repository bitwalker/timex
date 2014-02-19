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
    now_days = D.now(:day)
    assert is_integer(now_sec)
    assert is_integer(now_days)
    assert now_sec > now_days
  end

  test :local do
    local = D.local()
    localdate = D.from(local, :local)
    assert local === D.local(localdate)

    if D.timezone() !== {0.0, "UTC"} do
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
    assert D.to_days(epoch, :zero) === D.epoch(:day)
    assert D.to_timestamp(epoch) === D.epoch(:timestamp)
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
    assert D.local(D.from(30, :day)) === {{1970,1,31}, {0,0,0}}
    assert D.local(D.from(31, :day)) === {{1970,2,1}, {0,0,0}}
  end

  test :convert do
    date = D.now()
    assert D.convert(date, :sec) + D.epoch(:sec) === D.to_sec(date, :zero)
    assert D.convert(date, :day) + D.epoch(:day) === D.to_days(date, :zero)
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

  test :daynum do
    assert D.daynum(D.from({3,1,1})) === 1
    assert D.daynum(D.from({3,2,1})) === 32
    assert D.daynum(D.from({3,12,31})) === 365
    assert D.daynum(D.from({2012,12,31})) === 366
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
    assert D.days_in_month(D.from(localdate)) === 28

    localdate = {{2000,2,17},{11,59,10}}
    assert D.days_in_month(D.from(localdate)) === 29

    assert D.days_in_month(D.epoch()) === 31
    assert D.days_in_month(2012, 2) === 29
    assert D.days_in_month(2013, 2) === 28
  end

  test :month_to_num do
    assert D.month_to_num("April") == 4
    assert D.month_to_num("april") == 4
    assert D.month_to_num("Apr") == 4
    assert D.month_to_num("apr") == 4
    assert D.month_to_num(:april) == 4
  end

  test :day_to_num do
    assert D.day_to_num("Wednesday") == 3
    assert D.day_to_num("wednesday") == 3
    assert D.day_to_num("Wed") == 3
    assert D.day_to_num("wed") == 3
    assert D.day_to_num(:wednesday) == 3
  end

  test :is_leap do
    assert not D.is_leap(D.epoch())
    assert D.is_leap(2012)
    assert not D.is_leap(2100)
  end

  test :is_valid do
    assert D.is_valid(D.now())
    assert D.is_valid(D.from({1,1,1}))
    assert D.is_valid(D.from({{1,1,1}, {1,1,1}}))
    assert D.is_valid(D.from({{1,1,1}, {0,0,0}}))
    assert D.is_valid(D.from({{1,1,1}, {23,59,59}}))

    assert not D.is_valid(D.from({12,13,14}))
    assert not D.is_valid(D.from({12,12,34}))
    assert not D.is_valid(D.from({1,0,1}))
    assert not D.is_valid(D.from({1,1,0}))
    assert not D.is_valid(D.from({{12,12,12}, {24,0,0}}))
    assert not D.is_valid(D.from({{12,12,12}, {23,60,0}}))
    assert not D.is_valid(D.from({{12,12,12}, {23,59,60}}))
    assert not D.is_valid(D.from({{12,12,12}, {-1,59,59}}))
  end

  test :normalize do
    date = D.now()
    assert D.normalize(date) === date

    date = { {1,13,44}, {-8,60,61} }
    assert D.local(D.normalize(D.from(date))) === { {1,12,31}, {0,59,59} }

    assert D.local(D.normalize(D.from({2012,2,30}))) === { {2012,2,29}, {0,0,0} }
    assert D.local(D.normalize(D.from({2013,2,30}))) === { {2013,2,28}, {0,0,0} }
  end

  test :set do
    import D.Conversions, only: [to_gregorian: 1]

    date = D.from({{2013,3,17}, {17,26,5}}, {2.0,"EET"})
    assert to_gregorian(D.set(date, date: {1,1,1})) === { {1,1,1}, {15,26,5}, {2.0,"EET"} }
    assert to_gregorian(D.set(date, hour: 0)) === { {2013,3,17}, {0,26,5}, {2.0,"EET"} }
    assert to_gregorian(D.set(date, tz: D.timezone(:utc))) === { {2013,3,17}, {15,26,5}, {0.0,"UTC"} }

    assert to_gregorian(D.set(date, [date: {1,1,1}, hour: 13, sec: 61, tz: D.timezone(:utc)]))
           === { {1,1,1}, {13,26,59}, {0.0,"UTC"} }
    assert to_gregorian(D.set(date, [date: {-1,-2,-3}, hour: 33, sec: 61, tz: D.timezone(:utc)]))
           === { {0,1,1}, {23,26,59}, {0.0,"UTC"} }
  end

  test :rawset do
    import D.Conversions, only: [to_gregorian: 1]

    date = D.from({{2013,3,17}, {17,26,5}}, {2.0,"EET"})
    assert to_gregorian(D.rawset(date, date: {1,13,101})) === { {1,13,101}, {15,26,5}, {2.0,"EET"} }
    assert to_gregorian(D.rawset(date, hour: -1)) === { {2013,3,17}, {-1,26,5}, {2.0,"EET"} }
    assert to_gregorian(D.rawset(date, tz: D.timezone(-100000))) === { {2013,3,17}, {15,26,5}, {-100000,"TimeZoneName"} }

    assert to_gregorian(D.rawset(date, [date: {-1,-2,-3}, hour: 33, sec: 61, tz: D.timezone(:utc)]))
           === { {-1,-2,-3}, {33,26,61}, {0.0,"UTC"} }
  end

  test :compare do
    assert D.compare(D.epoch(), D.zero()) === -1
    assert D.compare(D.zero(), D.epoch()) === 1

    date = {2013,3,18}
    tz1 = D.timezone(2)
    tz2 = D.timezone(-3)
    assert D.compare(D.from({date, {13,44,0}}, tz1), D.from({date, {8,44,0}}, tz2)) === 0

    tz3 = D.timezone(3)
    assert D.compare(D.from({date, {13,44,0}}, tz1), D.from({date, {13,44,0}}, tz3)) === -1

    date = D.now()
    # Won't fail unless we go back in time
    assert D.compare(D.epoch(), date) === 1

    assert D.compare(date, :distant_past) === -1
    assert D.compare(date, :distant_future) === 1
  end

  test :diff do
    epoch = D.epoch()
    date1 = D.from({1971,1,1})
    date2 = D.from({1973,1,1})

    assert D.diff(date1, date2, :sec)   === -D.diff(date2, date1, :sec)
    #assert D.diff(date1, date2, :min)   === -D.diff(date2, date1, :min)
    #assert D.diff(date1, date2, :hour)  === -D.diff(date2, date1, :hour)
    assert D.diff(date1, date2, :day)   === -D.diff(date2, date1, :day)
    assert D.diff(date1, date2, :week)  === -D.diff(date2, date1, :week)
    assert D.diff(date1, date2, :month) === -D.diff(date2, date1, :month)
    assert D.diff(date1, date2, :year)  === -D.diff(date2, date1, :year)

    assert D.diff(epoch, date1, :day) === 365
    assert D.diff(epoch, date1, :sec) === 365 * 24 * 3600
    assert D.diff(epoch, date1, :year) === 1

    # additional day is added because 1972 was a leap year
    assert D.diff(epoch, date2, :day) === 365*3 + 1
    assert D.diff(epoch, date2, :sec) === (365*3 + 1) * 24 * 3600
    assert D.diff(epoch, date2, :year) === 3

    assert D.diff(epoch, date1, :month) === 12
    assert D.diff(epoch, date2, :month) === 36
    assert D.diff(date1, date2, :month) === 24

    date1 = D.from({1971,3,31})
    date2 = D.from({1969,2,11})
    assert D.diff(date1, date2, :month) === -25
    assert D.diff(date2, date1, :month) === 25
  end

  test :shift_seconds do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert shift(datetime, sec: 0) === datetime

    assert shift(datetime, sec: 1)           === {date, {23,23,24}}
    assert shift(datetime, sec: 36)          === {date, {23,23,59}}
    assert shift(datetime, sec: 37)          === {date, {23,24,0}}
    assert shift(datetime, sec: 38)          === {date, {23,24,1}}
    assert shift(datetime, sec: 38+60)       === {date, {23,25,1}}
    assert shift(datetime, sec: 38+60*35+58) === {date, {23,59,59}}
    assert shift(datetime, sec: 38+60*35+59) === {{2013,3,6}, {0,0,0}}
    assert shift(datetime, sec: 38+60*36)    === {{2013,3,6}, {0,0,1}}
    assert shift(datetime, sec: 24*3600)     === {{2013,3,6}, {23,23,23}}
    assert shift(datetime, sec: 24*3600*365) === {{2014,3,5}, {23,23,23}}

    assert shift(datetime, sec: -1)                 === {date, {23,23,22}}
    assert shift(datetime, sec: -23)                === {date, {23,23,0}}
    assert shift(datetime, sec: -24)                === {date, {23,22,59}}
    assert shift(datetime, sec: -23*60)             === {date, {23,0,23}}
    assert shift(datetime, sec: -24*60)             === {date, {22,59,23}}
    assert shift(datetime, sec: -23*3600-23*60-23)  === {date, {0,0,0}}
    assert shift(datetime, sec: -23*3600-23*60-24)  === {{2013,3,4}, {23,59,59}}
    assert shift(datetime, sec: -24*3600)           === {{2013,3,4}, {23,23,23}}
    assert shift(datetime, sec: -24*3600*365)       === {{2012,3,5}, {23,23,23}}
    assert shift(datetime, sec: -24*3600*(365*2+1)) === {{2011,3,5}, {23,23,23}}   # +1 day for leap year 2012
  end

  test :shift_minutes do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert shift(datetime, min: 0) === datetime

    assert shift(datetime, min: 1)         === {date, {23,24,23}}
    assert shift(datetime, min: 36)        === {date, {23,59,23}}
    assert shift(datetime, min: 37)        === {{2013,3,6}, {0,0,23}}
    assert shift(datetime, min: 38)        === {{2013,3,6}, {0,1,23}}
    assert shift(datetime, min: 60*24*365) === {{2014,3,5}, {23,23,23}}

    assert shift(datetime, min: -1)                 === {date, {23,22,23}}
    assert shift(datetime, min: -23)                === {date, {23,0,23}}
    assert shift(datetime, min: -24)                === {date, {22,59,23}}
    assert shift(datetime, min: -23*60-24)          === {{2013,3,4}, {23,59,23}}
    assert shift(datetime, min: -60*24*(365*2 + 1)) === {{2011,3,5}, {23,23,23}}
  end

  test :shift_hours do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    assert shift(datetime, hour: 0) === datetime

    assert shift(datetime, hour: 1)      === {{2013,3,6}, {0,23,23}}
    assert shift(datetime, hour: 24)     === {{2013,3,6}, {23,23,23}}
    assert shift(datetime, hour: 25)     === {{2013,3,7}, {0,23,23}}
    assert shift(datetime, hour: 24*30)  === {{2013,4,4}, {23,23,23}}
    assert shift(datetime, hour: 24*365) === {{2014,3,5}, {23,23,23}}

    assert shift(datetime, hour: -1)              === {date, {22,23,23}}
    assert shift(datetime, hour: -23)             === {date, {0,23,23}}
    assert shift(datetime, hour: -24)             === {{2013,3,4}, {23,23,23}}
    assert shift(datetime, hour: -24*(365*2 + 1)) === {{2011,3,5}, {23,23,23}}
  end

  test :shift_days do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    assert shift(datetime, day: 0) === datetime

    assert shift(datetime, day: 1)   === { {2013,3,6}, time }
    assert shift(datetime, day: 27)  === { {2013,4,1}, time }
    assert shift(datetime, day: 365) === { {2014,3,5}, time }

    assert shift(datetime, day: -1)       === { {2013,3,4}, time }
    assert shift(datetime, day: -5)       === { {2013,2,28}, time }
    assert shift(datetime, day: -365)     === { {2012,3,5}, time }
    assert shift(datetime, day: -365*2-1) === { {2011,3,5}, time }
  end

  test :shift_weeks do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    assert shift(datetime, week: 0) === datetime

    assert shift(datetime, week: 1)   === { {2013,3,12}, time }
    assert shift(datetime, week: 52)  === { {2014,3,4}, time }
    assert shift(datetime, week: -1)  === { {2013,2,26}, time }
    assert shift(datetime, week: -52) === { {2012,3,6}, time }

    date = D.from(datetime)
    weekday = D.weekday(date)
    Enum.each -53..53, fn n ->
      assert D.shift(date, [week: n]) |> D.weekday === weekday
    end
  end

  test :shift_months do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    assert shift(datetime, month: 0) === datetime

    assert shift(datetime, month: 1)   === { {2013,4,5}, time }
    assert shift(datetime, month: 10)  === { {2014,1,5}, time }
    assert shift(datetime, month: -2)  === { {2013,1,5}, time }
    assert shift(datetime, month: -12) === { {2012,3,5}, time }

    datetime = { {2013,3,31}, time }
    assert shift(datetime, month: 1)  === { {2013,4,30}, time }
    assert shift(datetime, month: -1) === { {2013,2,28}, time }
  end

  test :shift_years do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    assert shift(datetime, year: 0) === datetime

    assert shift(datetime, year: 1)  === { {2014,3,5}, time }
    assert shift(datetime, year: -2) === { {2011,3,5}, time }

    datetime = { {2012,2,29}, time }
    assert shift(datetime, year: 1)  === { {2013,2,28}, time }
    assert shift(datetime, year: 4)  === { {2016,2,29}, time }
    assert shift(datetime, year: -1) === { {2011,2,28}, time }
    assert shift(datetime, year: -4) === { {2008,2,29}, time }
  end

  test :arbitrary_shifts do
    datetime = { {2013,3,5}, {23,23,23} }
    assert shift(datetime, month: 3) === { {2013,6,5}, {23,23,23} }
    assert_raise ArgumentError, fn ->
      shift(datetime, month: 3, day: 1) === { {2013,6,6}, {23,23,23} }
    end
    assert shift(datetime, sec: 13, day: -1, week: 2) === { {2013,3,18}, {23,23,36} }

    datetime = { {2012,2,29}, {23,23,23} }
    assert shift(datetime, month: 12) === { {2013,2,28}, {23,23,23} }

    assert shift(datetime, year: -10, day: 1) === { {2002,3,1}, {23,23,23} }
    assert shift(datetime, min: 36, sec: 36) === { {2012,2,29}, {23,59,59} }
    assert shift(datetime, min: 36, sec: 37) === { {2012,3,1}, {0,0,0} }
  end

  defp shift(date, spec) when is_list(spec) do
    D.local(D.shift(D.from(date), spec))
  end
end
