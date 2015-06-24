defmodule DateTests do
  use ExUnit.Case, async: true
  use Timex

  alias Timex.Date, as: D

  test :add do
    date     = Date.from({{2015, 6, 24}, {14, 27, 52}})
    expected = Date.from({{2015, 7, 2}, {14, 27, 52}})
    result   = date |> Date.add(Time.to_timestamp(8, :days))
    assert expected === result
  end

  test :subtract do
    date     = Date.from({{2015, 6, 24}, {14, 27, 52}})
    expected = Date.from({{2015, 6, 16}, {14, 27, 52}})
    result   = date |> Date.subtract(Time.to_timestamp(8, :days))
    assert expected === result
  end

  test :"century/0" do
    assert 21 === Date.century
  end

  test :"century/1" do
    date = Date.from({{2015, 6, 24}, {14, 27, 52}})
    c = date |> Date.century
    assert 21 === c
  end

  test :now do
    # We cannot assert matching to a specific value. However, we can still do
    # some sanity checks
    now = D.now
    assert {{_, _, _}, {_, _, _}, {_, _}} = DateConvert.to_gregorian(now)

    {_, _, tz} = DateConvert.to_gregorian(now)
    %TimezoneInfo{:full_name => name, :offset_std => offset_mins} = %TimezoneInfo{}
    assert tz === {offset_mins/60, name}

    now_secs = D.now(:secs)
    now_days = D.now(:days)
    assert is_integer(now_secs)
    assert is_integer(now_days)
    assert now_secs > now_days
  end

  test :local do
    local     = D.local
    %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, ms: ms} = local
    localdate = D.from({{y,m,d}, {h,min,s,ms}}, :local)
    assert local === D.local(localdate)
  end

  test :universal do
    uni     = D.universal()
    %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, ms: ms} = uni
    unidate = D.from({{y,m,d}, {h,min,s,ms}})
    assert uni === D.universal(unidate)
  end
  
  test :zero do
    zero = D.zero
    { date, time, tz } = zero |> DateConvert.to_gregorian
    assert :calendar.datetime_to_gregorian_seconds({date,time}) === 0
    assert tz === {zero.timezone.offset_std/60, zero.timezone.full_name}
  end

  test :epoch do
    epoch = D.epoch
    assert { {1970,1,1}, {0,0,0}, {0.0, "UTC"} } = DateConvert.to_gregorian(epoch)
    assert D.to_secs(epoch) === 0
    assert D.to_days(epoch) === 0
    assert D.to_secs(epoch, :zero) === D.epoch(:secs)
    assert D.to_days(epoch, :zero) === D.epoch(:days)
    assert D.to_timestamp(epoch) === D.epoch(:timestamp)
  end

  test :from_date do
    date = {2000, 11, 11}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 0, minute: 0, second: 0} = date |> D.from

    { d, t, tz } = date |> D.from(:local) |> DateConvert.to_gregorian
    localtz = Timezone.local({d, t})
    assert tz === {localtz.offset_std/60, localtz.abbreviation}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 0, minute: 0, second: 0, timezone: _} = date |> D.from(:local)

    { date, time, tz } = date |> Date.from |> DateConvert.to_gregorian
    unitz = D.timezone(:utc, date)
    assert tz === {unitz.offset_std/60,unitz.abbreviation}
    assert {date,time} === {{2000,11,11}, {0,0,0}}

    # Converting to a datetime and back to gregorian should yield the original date
    fulldate = date |> D.from(D.timezone("Europe/Athens", {date, {0,0,0}}))
    { date, time, _ } = fulldate |> DateConvert.to_gregorian
    assert {date,time} === {{2000,11,11}, {0,0,0}}
  end

  test :from_datetime do
    assert D.from({{1970,1,1}, {0,0,0}}) === D.from({1970,1,1})
    assert 0 === D.from({{1970,1,1}, {0,0,0}}) |> D.to_secs

    date = {{2000, 11, 11}, {1, 0, 0}}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 1, minute: 0, second: 0} = date |> D.from |> D.universal

    { d, time, tz } = date |> D.from |> DateConvert.to_gregorian
    unitz = D.timezone(:utc, date)
    assert tz === {unitz.offset_std/60,unitz.abbreviation}
    assert {d,time} === date

    { d, time } = date |> D.from |> DateConvert.to_erlang_datetime
    assert {d,time} === date

    { d, time, _ } = date |> D.from(D.timezone("Europe/Athens", date)) |> DateConvert.to_gregorian
    assert {d,time} === {{2000,11,11}, {1,0,0}}
  end

  test :from_timestamp do
    now = Time.now
    assert trunc(Time.to_secs(now)) === now |> D.from(:timestamp) |> D.to_secs
    assert 0 === {0,0,0} |> D.from(:timestamp) |> D.to_secs
    assert -D.epoch(:secs) === {0,0,0} |> D.from(:timestamp, :zero) |> D.to_secs
  end

  test :from_sec do
    now_sec = trunc(Time.now(:secs))
    assert now_sec === now_sec |> D.from(:secs) |> D.to_secs
    assert now_sec - D.epoch(:secs) === now_sec |> D.from(:secs, :zero) |> D.to_secs
  end

  test :from_days do
    assert %DateTime{year: 1970, month: 1, day: 31, hour: 0, minute: 0, second: 0} = D.from(30, :days)
    assert %DateTime{year: 1970, month: 2, day: 1, hour: 0, minute: 0, second: 0} = D.from(31, :days)
  end

  test :convert do
    date = D.now
    assert D.convert(date, :secs) + D.epoch(:secs) === D.to_secs(date, :zero)
    assert D.convert(date, :days) + D.epoch(:days) === D.to_days(date, :zero)
  end

  test :to_timestamp do
    assert {0,0,0} === D.epoch |> D.to_timestamp
    assert {62167,219200,0} === D.epoch |> D.to_timestamp(:zero)
    assert D.epoch(:secs) == D.epoch |> D.to_timestamp(:zero) |> Time.to_secs
  end

  test :to_secs do
    date = D.now()
    assert D.to_secs(date, :zero) === date |> DateConvert.to_erlang_datetime |> :calendar.datetime_to_gregorian_seconds

    ts = Time.now()
    assert trunc(Time.to_secs(ts)) === ts |> D.from(:timestamp) |> D.to_secs

    date = D.from({{1999,1,2}, {12,13,14}})
    assert D.to_secs(date) === 915279194
    assert D.to_secs(date, :zero) === 63082498394

    assert D.to_secs(D.epoch()) === 0
    assert D.to_secs(D.epoch(), :zero) === 62167219200

    date = D.from({{2014,11,17},{0,0,0}}, "America/Los_Angeles")
    assert D.to_secs(date) == 1416211200

    ndate = D.from({2014,11,17})
    assert D.to_secs(ndate) == 1416182400

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
    assert D.weekday(D.from(localdate)) === 7
    assert D.weekday(D.epoch()) === 4
  end

  test :day do
    assert D.day(D.from({3,1,1})) === 1
    assert D.day(D.from({3,2,1})) === 32
    assert D.day(D.from({3,12,31})) === 365
    assert D.day(D.from({2012,12,31})) === 366
  end

  test :week do
    localdate = {{2013,3,17},{11,59,10}}
    assert D.iso_week(localdate) === {2013,11}
    assert D.iso_week(D.from(localdate)) === {2013,11}
    assert D.iso_week(D.epoch()) === {1970,1}
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
    assert D.month_to_num(:apr) == 4
  end

  test :day_to_num do
    assert D.day_to_num("Wednesday") == 3
    assert D.day_to_num("wednesday") == 3
    assert D.day_to_num("Wed") == 3
    assert D.day_to_num("wed") == 3
    assert D.day_to_num(:wed) == 3
  end

  test :is_leap do
    assert not D.is_leap?(D.epoch())
    assert D.is_leap?(2012)
    assert not D.is_leap?(2100)
  end

  test :is_valid? do
    assert D.is_valid?(D.now())
    assert D.is_valid?(D.from({1,1,1}))
    assert D.is_valid?(D.from({{1,1,1}, {1,1,1}}))
    assert D.is_valid?(D.from({{1,1,1}, {0,0,0}}))
    assert D.is_valid?(D.from({{1,1,1}, {23,59,59}}))
    assert D.is_valid?({{1,1,1}, {1, 1, 1}, Timezone.get(:utc)})

    assert not D.is_valid?(D.from({12,13,14}))
    assert not D.is_valid?(D.from({12,12,34}))
    assert not D.is_valid?(D.from({1,0,1}))
    assert not D.is_valid?(D.from({1,1,0}))
    assert not D.is_valid?(D.from({{12,12,12}, {24,0,0}}))
    assert not D.is_valid?(D.from({{12,12,12}, {23,60,0}}))
    assert not D.is_valid?(D.from({{12,12,12}, {23,59,60}}))
    assert not D.is_valid?(D.from({{12,12,12}, {-1,59,59}}))
    assert D.is_valid?({{12,12,12}, {1,59,59}, %TimezoneInfo{}})
    assert not D.is_valid?({{12,12,12}, {-1,59,59}, Timezone.get(:utc)})
  end

  test :normalize do
    tz = Timezone.get(:utc)
    date = { {1,13,44}, {-8,60,61}, tz }
    assert %DateTime{year: 1, month: 12, day: 31, hour: 0, minute: 59, second: 59, timezone: _} = D.normalize(date)
  end

  test :set do
    import D.Convert, only: [to_gregorian: 1]

    eet = Timezone.get("Europe/Athens", Date.from({{2013,3,17}, {17,26,5}}))
    utc = Timezone.get(:utc)
    %TimezoneInfo{:abbreviation => eet_name, :offset_std => eet_offset_min} = eet
    %TimezoneInfo{:abbreviation => utc_name, :offset_std => utc_offset_min} = utc

    tuple = {{2013,3,17}, {17,26,5}}
    date = D.from(tuple, "Europe/Athens")
    assert to_gregorian(D.set(date, date: {1,1,1}))        === { {1,1,1}, {17,26,5}, {eet_offset_min/60, eet_name} }
    assert to_gregorian(D.set(date, hour: 0))              === { {2013,3,17}, {0,26,5}, {eet_offset_min/60, eet_name} }
    assert to_gregorian(D.set(date, timezone: D.timezone(:utc, tuple))) === { {2013,3,17}, {17,26,5}, {utc_offset_min/60, utc_name} }

    assert to_gregorian(D.set(date, [date: {1,1,1}, hour: 13, second: 61, timezone: utc]))    === { {1,1,1}, {13,26,59}, {utc_offset_min/60, utc_name} }
    assert to_gregorian(D.set(date, [date: {-1,-2,-3}, hour: 33, second: 61, timezone: utc])) === { {0,1,1}, {23,26,59}, {utc_offset_min/60, utc_name} }
  end

  test :compare do
    assert D.compare(D.epoch(), D.zero()) === 1
    assert D.compare(D.zero(), D.epoch()) === -1

    tz1   = Timezone.get(2)
    tz2   = Timezone.get(-3)
    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz1}
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: tz2}
    assert D.compare(date1, date2) === 0

    tz3   = Timezone.get(3)
    date3 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz3}
    assert D.compare(date1, date3) === 1

    date = D.now()
    assert D.compare(D.epoch(), date) === -1

    assert D.compare(date, :distant_past) === +1
    assert D.compare(date, :distant_future) === -1
  end

  test :compare_with_granularity do
    tz1   = Timezone.get(2)
    tz2   = Timezone.get(-3)
    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz1}
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: tz2}
    date3 = %DateTime{year: 2013, month: 4, day: 18, hour: 8, minute: 44, second: 10, timezone: tz2}
    date4 = %DateTime{year: 2013, month: 4, day: 18, hour: 8, minute: 44, second: 23, timezone: tz2}

    assert D.compare(date1, date2, :years) === 0
    assert D.compare(date1, date2, :months) === 0
    assert D.compare(date1, date3, :months) === -1
    assert D.compare(date3, date1, :months) === +1
    assert D.compare(date1, date3, :weeks) === -1 
    assert D.compare(date1, date2, :days) === 0
    assert D.compare(date1, date3, :days) === -1
    assert D.compare(date1, date2, :hours) === 0
    assert D.compare(date3, date4, :mins) === 0
    assert D.compare(date3, date4, :secs) === -1
  end

  test :diff do
    epoch = D.epoch()
    date1 = D.from({1971,1,1})
    date2 = D.from({1973,1,1})

    assert D.diff(date1, date2, :secs)   === -D.diff(date2, date1, :secs)
    assert D.diff(date1, date2, :mins)   === -D.diff(date2, date1, :mins)
    assert D.diff(date1, date2, :hours)  === -D.diff(date2, date1, :hours)
    assert D.diff(date1, date2, :days)   === -D.diff(date2, date1, :days)
    assert D.diff(date1, date2, :weeks)  === -D.diff(date2, date1, :weeks)
    assert D.diff(date1, date2, :months) === -D.diff(date2, date1, :months)
    assert D.diff(date1, date2, :years)  === -D.diff(date2, date1, :years)

    assert D.diff(date1, date2, :timestamp) === {63, 158400, 0}

    assert D.diff(epoch, date1, :days) === 365
    assert D.diff(epoch, date1, :secs) === 365 * 24 * 3600
    assert D.diff(epoch, date1, :years) === 1

    # additional day is added because 1972 was a leap year
    assert D.diff(epoch, date2, :days) === 365*3 + 1
    assert D.diff(epoch, date2, :secs) === (365*3 + 1) * 24 * 3600
    assert D.diff(epoch, date2, :years) === 3

    assert D.diff(epoch, date1, :months) === 12
    assert D.diff(epoch, date2, :months) === 36
    assert D.diff(date1, date2, :months) === 24

    date1 = D.from({1971,3,31})
    date2 = D.from({1969,2,11})
    assert D.diff(date1, date2, :months) === -25
    assert D.diff(date2, date1, :months) === 25
  end

  test :shift_seconds do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, secs: 0)

    assert %DateTime{minute: 23, second: 24} = shift(datetime, secs: 1)
    assert %DateTime{minute: 23, second: 59} = shift(datetime, secs: 36)
    assert %DateTime{minute: 24, second: 0} = shift(datetime, secs: 37)
    assert %DateTime{minute: 24, second: 1} = shift(datetime, secs: 38)
    assert %DateTime{minute: 25, second: 1} = shift(datetime, secs: 38+60)
    assert %DateTime{minute: 59, second: 59} = shift(datetime, secs: 38+60*35+58)
    assert %DateTime{month: 3, day: 6, hour: 0, minute: 0, second: 0} = shift(datetime, secs: 38+60*35+59)
    assert %DateTime{month: 3, day: 6, hour: 0, minute: 0, second: 1} = shift(datetime, secs: 38+60*36)
    assert %DateTime{month: 3, day: 6, hour: 23, minute: 23, second: 23} = shift(datetime, secs: 24*3600)
    assert %DateTime{month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, secs: 24*3600*365)

    assert %DateTime{minute: 23, second: 22} = shift(datetime, secs: -1)
    assert %DateTime{minute: 23, second: 0} = shift(datetime, secs: -23)
    assert %DateTime{minute: 22, second: 59} = shift(datetime, secs: -24)
    assert %DateTime{hour: 23, minute: 0, second: 23} = shift(datetime, secs: -23*60)
    assert %DateTime{hour: 22, minute: 59, second: 23} = shift(datetime, secs: -24*60)
    assert %DateTime{year: 2013, month: 3, day: 5, hour: 0, minute: 0, second: 0} = shift(datetime, secs: -23*3600-23*60-23)
    assert %DateTime{year: 2013, month: 3, day: 4, hour: 23, minute: 59, second: 59} = shift(datetime, secs: -23*3600-23*60-24)
    assert %DateTime{year: 2013, month: 3, day: 4, hour: 23, minute: 23, second: 23} = shift(datetime, secs: -24*3600)
    assert %DateTime{year: 2012, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, secs: -24*3600*365)
    assert %DateTime{year: 2011, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, secs: -24*3600*(365*2+1))   # +1 day for leap year 2012
  end

  test :shift_seconds_with_timezone do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")

    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 1, minute: 44, timezone: utc }
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: cst }
    assert %DateTime{minute: 49 , second: 0} = D.shift(date1, secs: 5*60 )
    assert %DateTime{minute: 49 , second: 0} = D.shift(date2, secs: 5*60 )


  end 

  test :shift_minutes do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, mins: 0)

    assert %DateTime{hour: 23, minute: 24, second: 23} = shift(datetime, mins: 1)
    assert %DateTime{hour: 23, minute: 59, second: 23} = shift(datetime, mins: 36)
    assert %DateTime{year: 2013, month: 3, day: 6, hour: 0, minute: 0, second: 23} = shift(datetime, mins: 37)
    assert %DateTime{year: 2013, month: 3, day: 6, hour: 0, minute: 1, second: 23} = shift(datetime, mins: 38)
    assert %DateTime{year: 2014, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, mins: 60*24*365)

    assert %DateTime{hour: 23, minute: 22, second: 23} = shift(datetime, mins: -1)
    assert %DateTime{hour: 23, minute: 0, second: 23} = shift(datetime, mins: -23)
    assert %DateTime{hour: 22, minute: 59, second: 23} = shift(datetime, mins: -24)
    assert %DateTime{month: 3, day: 4, hour: 23, minute: 59, second: 23} = shift(datetime, mins: -23*60-24)
    assert %DateTime{year: 2011, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, mins: -60*24*(365*2 + 1))
  end

  test :shift_minutes_with_timezone do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")
    
    chicago_noon = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 12, minute: 0, month: 2, ms: 0, second: 0,timezone: cst , year: 2014}
    utc_dinner = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 18, minute: 0, month: 2, ms: 0, second: 0,timezone: utc , year: 2014}
    
    assert %DateTime{ hour: 18, minute: 0 } = D.shift(chicago_noon, mins: 360 )
    assert %DateTime{ hour: 12, minute: 0} = D.shift(utc_dinner, mins: -360 )
  end 

  test :shift_hours do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, hours: 0)

    assert %DateTime{month: 3, day: 6, hour: 0, minute: 23, second: 23} = shift(datetime, hours: 1)
    assert %DateTime{month: 3, day: 6, hour: 23, minute: 23, second: 23} = shift(datetime, hours: 24)
    assert %DateTime{month: 3, day: 7, hour: 0, minute: 23, second: 23} = shift(datetime, hours: 25)
    assert %DateTime{month: 4, day: 4, hour: 23, minute: 23, second: 23} = shift(datetime, hours: 24*30)
    assert %DateTime{month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, hours: 24*365)

    assert %DateTime{month: 3, day: 5, hour: 22, minute: 23, second: 23} = shift(datetime, hours: -1)
    assert %DateTime{month: 3, day: 5, hour: 0, minute: 23, second: 23} = shift(datetime, hours: -23)
    assert %DateTime{month: 3, day: 4, hour: 23, minute: 23, second: 23} = shift(datetime, hours: -24)
    assert %DateTime{month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, hours: -24*(365*2 + 1))
  end

  test :shift_days do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, days: 0)

    assert %DateTime{year: 2013, month: 3, day: 6} = shift(datetime, days: 1)
    assert %DateTime{year: 2013, month: 4, day: 1} = shift(datetime, days: 27)
    assert %DateTime{year: 2014, month: 3, day: 5} = shift(datetime, days: 365)

    assert %DateTime{year: 2013, month: 3, day: 4} = shift(datetime, days: -1)
    assert %DateTime{year: 2013, month: 2, day: 28} = shift(datetime, days: -5)
    assert %DateTime{year: 2012, month: 3, day: 5} = shift(datetime, days: -365)
    assert %DateTime{year: 2011, month: 3, day: 5} = shift(datetime, days: -365*2-1)
  end

  test :shift_weeks do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, weeks: 0)

    assert %DateTime{year: 2013, month: 3, day: 12} = shift(datetime, weeks: 1)
    assert %DateTime{year: 2014, month: 3, day: 4}  = shift(datetime, weeks: 52)
    assert %DateTime{year: 2013, month: 2, day: 26} = shift(datetime, weeks: -1)
    assert %DateTime{year: 2012, month: 3, day: 6}  = shift(datetime, weeks: -52)

    date = D.from(datetime)
    weekday = D.weekday(date)
    Enum.each -53..53, fn n ->
      assert D.shift(date, [weeks: n]) |> D.weekday === weekday
    end
  end

  test :shift_months do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, months: 0)

    assert %DateTime{year: 2013, month: 4, day: 5} = shift(datetime, months: 1)
    assert %DateTime{year: 2014, month: 1, day: 5} = shift(datetime, months: 10)
    assert %DateTime{year: 2013, month: 1, day: 5} = shift(datetime, months: -2)
    assert %DateTime{year: 2012, month: 3, day: 5} = shift(datetime, months: -12)

    datetime = { {2013,3,31}, time }
    assert %DateTime{year: 2013, month: 4, day: 30} = shift(datetime, months: 1)
    assert %DateTime{year: 2013, month: 2, day: 28} = shift(datetime, months: -1)
  end

  test :shift_years do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, years: 0)

    assert %DateTime{year: 2014, month: 3, day: 5} = shift(datetime, years: 1)
    assert %DateTime{year: 2011, month: 3, day: 5} = shift(datetime, years: -2)

    datetime = { {2012,2,29}, time }
    assert %DateTime{year: 2013, month: 2, day: 28} = shift(datetime, years: 1)
    assert %DateTime{year: 2016, month: 2, day: 29} = shift(datetime, years: 4)
    assert %DateTime{year: 2011, month: 2, day: 28} = shift(datetime, years: -1)
    assert %DateTime{year: 2008, month: 2, day: 29} = shift(datetime, years: -4)
  end

  test :arbitrary_shifts do
    datetime = { {2013,3,5}, {23,23,23} }
    assert %DateTime{year: 2013, month: 6, day: 5} = shift(datetime, months: 3)
    assert_raise ArgumentError, fn ->
      %DateTime{year: 2013, month: 6, day: 6} = shift(datetime, months: 3, days: 1)
    end
    assert %DateTime{year: 2013, month: 3, day: 18, second: 36} = shift(datetime, secs: 13, days: -1, weeks: 2)

    datetime = { {2012,2,29}, {23,23,23} }
    assert %DateTime{year: 2013, month: 2, day: 28} = shift(datetime, months: 12)

    assert %DateTime{year: 2002, month: 3, day: 1} = shift(datetime, years: -10, days: 1)
    assert %DateTime{year: 2012, month: 2, day: 29, hour: 23, minute: 59, second: 59} = shift(datetime, mins: 36, secs: 36)
    assert %DateTime{year: 2012, month: 3, day: 1, hour: 0, minute: 0, second: 0} = shift(datetime, mins: 36, secs: 37)
  end

  defp shift(date, spec) when is_list(spec) do
    date |> D.from |> D.shift(spec)
  end
end
