defmodule DateTests do
  use ExUnit.Case, async: true
  doctest Timex.Date
  doctest Timex.Date.Convert
  doctest Timex.DateTime

  use Timex

  test "add" do
    date     = Date.from({{2015, 6, 24}, {14, 27, 52}})
    expected = Date.from({{2015, 7, 2}, {14, 27, 52}})
    result   = date |> Date.add(Time.to_timestamp(8, :days))
    assert expected === result
  end

  test "subtract" do
    date     = Date.from({{2015, 6, 24}, {14, 27, 52}})
    expected = Date.from({{2015, 6, 16}, {14, 27, 52}})
    result   = date |> Date.subtract(Time.to_timestamp(8, :days))
    assert expected === result
  end

  test "century" do
    assert 21 === Date.century

    date = Date.from({{2015, 6, 24}, {14, 27, 52}})
    c = date |> Date.century
    assert 21 === c
  end

  test "now" do
    # We cannot assert matching to a specific value. However, we can still do
    # some sanity checks
    now = Date.now
    assert {{_, _, _}, {_, _, _}, {_, _}} = DateConvert.to_gregorian(now)

    {_, _, tz} = DateConvert.to_gregorian(now)
    %TimezoneInfo{:full_name => name, :offset_std => offset_mins} = %TimezoneInfo{}
    assert tz === {offset_mins/60, name}

    now_secs = Date.now(:secs)
    now_days = Date.now(:days)
    assert is_integer(now_secs)
    assert is_integer(now_days)
    assert now_secs > now_days
  end

  test "local" do
    local     = Date.local
    %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, ms: ms} = local
    localdate = Date.from({{y,m,d}, {h,min,s,ms}}, :local)
    assert local === Date.local(localdate)
  end

  test "universal" do
    uni     = Date.universal()
    %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, ms: ms} = uni
    unidate = Date.from({{y,m,d}, {h,min,s,ms}})
    assert uni === Date.universal(unidate)
  end

  test "zero" do
    zero = Date.zero
    { date, time, tz } = zero |> DateConvert.to_gregorian
    assert :calendar.datetime_to_gregorian_seconds({date,time}) === 0
    assert tz === {zero.timezone.offset_std/60, zero.timezone.full_name}
  end

  test "epoch" do
    epoch = Date.epoch
    assert { {1970,1,1}, {0,0,0}, {0.0, "UTC"} } = DateConvert.to_gregorian(epoch)
    assert Date.to_secs(epoch) === 0
    assert Date.to_days(epoch) === 0
    assert Date.to_secs(epoch, :zero) === Date.epoch(:secs)
    assert Date.to_timestamp(epoch) === Date.epoch(:timestamp)
  end

  test "from date" do
    date = {2000, 11, 11}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 0, minute: 0, second: 0} = date |> Date.from

    { d, t, tz } = date |> Date.from(:local) |> DateConvert.to_gregorian
    localtz = Timezone.local({d, t})
    assert tz === {localtz.offset_std/60, localtz.abbreviation}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 0, minute: 0, second: 0, timezone: _} = date |> Date.from(:local)

    { date, time, tz } = date |> Date.from |> DateConvert.to_gregorian
    unitz = Date.timezone(:utc, date)
    assert tz === {unitz.offset_std/60,unitz.abbreviation}
    assert {date,time} === {{2000,11,11}, {0,0,0}}

    # Converting to a datetime and back to gregorian should yield the original date
    fulldate = date |> Date.from(Date.timezone("Europe/Athens", {date, {0,0,0}}))
    { date, time, _ } = fulldate |> DateConvert.to_gregorian
    assert {date,time} === {{2000,11,11}, {0,0,0}}
  end

  test "from datetime" do
    assert Date.from({{1970,1,1}, {0,0,0}}) === Date.from({1970,1,1})
    assert 0 === Date.from({{1970,1,1}, {0,0,0}}) |> Date.to_secs

    date = {{2000, 11, 11}, {1, 0, 0}}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 1, minute: 0, second: 0} = date |> Date.from |> Date.universal

    { d, time, tz } = date |> Date.from |> DateConvert.to_gregorian
    unitz = Date.timezone(:utc, date)
    assert tz === {unitz.offset_std/60,unitz.abbreviation}
    assert {d,time} === date

    { d, time } = date |> Date.from |> DateConvert.to_erlang_datetime
    assert {d,time} === date

    { d, time, _ } = date |> Date.from(Date.timezone("Europe/Athens", date)) |> DateConvert.to_gregorian
    assert {d,time} === {{2000,11,11}, {1,0,0}}
  end

  test "from timestamp" do
    now = Time.now
    assert trunc(Time.to_secs(now)) === now |> Date.from(:timestamp) |> Date.to_secs
    assert 0 === {0,0,0} |> Date.from(:timestamp) |> Date.to_secs
    assert -Date.epoch(:secs) === {0,0,0} |> Date.from(:timestamp, :zero) |> Date.to_secs
  end

  test "from milliseconds" do
    msecs = 1451425764069
    date = Date.from({{2015, 12, 29}, {21, 49, 24, 69}})
    assert date == Date.from(msecs, :msecs)
  end

  test "from seconds" do
    now_sec = trunc(Time.now(:secs))
    assert now_sec === now_sec |> Date.from(:secs) |> Date.to_secs
    assert now_sec - Date.epoch(:secs) === now_sec |> Date.from(:secs, :zero) |> Date.to_secs
  end

  test "from days" do
    assert %DateTime{year: 1970, month: 1, day: 31, hour: 0, minute: 0, second: 0} = Date.from(30, :days)
    assert %DateTime{year: 1970, month: 2, day: 1, hour: 0, minute: 0, second: 0} = Date.from(31, :days)
  end

  test "from phoenix_datetime_select" do
    date = %{"day" => "05", "hour" => "12", "min" => "35", "month" => "2", "year" => "2016"}
    assert %DateTime{year: 2016, month: 2, day: 05, hour: 12, minute: 35, second: 0} = Date.from(date)
  end

  test "to timestamp" do
    assert {0,0,0} === Date.epoch |> Date.to_timestamp
    assert {62167,219200,0} === Date.epoch |> Date.to_timestamp(:zero)
    assert Date.epoch(:secs) == Date.epoch |> Date.to_timestamp(:zero) |> Time.to_secs

    # Force some micro seconds to appear in case we are unlucky and hit when micro := 0
    {mega, secs, _micro} = Time.now
    now = {mega, secs, 864123}

    # deliberately match against 864000 AND NOT 864123 since DateTime only
    # takes milliseconds into account
    assert {mega, secs, 864000} === Date.from(now, :timestamp, :epoch) |> Date.to_timestamp(:epoch)
  end

  test "to seconds" do
    date = Date.now()
    assert Date.to_secs(date, :zero) === date |> DateConvert.to_erlang_datetime |> :calendar.datetime_to_gregorian_seconds

    ts = Time.now()
    assert trunc(Time.to_secs(ts)) === ts |> Date.from(:timestamp) |> Date.to_secs

    date = Date.from({{1999,1,2}, {12,13,14}})
    assert Date.to_secs(date) === 915279194
    assert Date.to_secs(date, :zero) === 63082498394

    assert Date.to_secs(Date.epoch()) === 0
    assert Date.to_secs(Date.epoch(), :zero) === 62167219200

    date = Date.from({{2014,11,17},{0,0,0}}, "America/Los_Angeles")
    assert Date.to_secs(date) == 1416211200

    ndate = Date.from({2014,11,17})
    assert Date.to_secs(ndate) == 1416182400

  end

  test "to days" do
    date = Date.from({2013,3,16})
    assert Date.to_days(date) === 15780
    assert Date.to_days(date, :zero) === 735308

    assert Date.to_days(Date.epoch()) === 0
    assert Date.to_days(Date.epoch(), :zero) === 719528
  end

  test "weekday" do
    localdate = {{2013,3,17},{11,59,10}}
    assert Date.weekday(Date.from(localdate)) === 7
    assert Date.weekday(Date.epoch()) === 4
  end

  test "day" do
    assert Date.day(Date.from({3,1,1})) === 1
    assert Date.day(Date.from({3,2,1})) === 32
    assert Date.day(Date.from({3,12,31})) === 365
    assert Date.day(Date.from({2012,12,31})) === 366
  end

  test "week" do
    localdate = {{2013,3,17},{11,59,10}}
    assert Date.iso_week(localdate) === {2013,11}
    assert Date.iso_week(Date.from(localdate)) === {2013,11}
    assert Date.iso_week(Date.epoch()) === {1970,1}
  end

  test "iso_triplet" do
    localdate = {{2013,3,17},{11,59,10}}
    assert Date.iso_triplet(Date.from(localdate)) === {2013,11,7}
    assert Date.iso_triplet(Date.epoch()) === {1970,1,4}
  end

  test "days_in_month" do
    localdate = {{2013,2,17},{11,59,10}}
    assert Date.days_in_month(Date.from(localdate)) === 28

    localdate = {{2000,2,17},{11,59,10}}
    assert Date.days_in_month(Date.from(localdate)) === 29

    assert Date.days_in_month(Date.epoch()) === 31
    assert Date.days_in_month(2012, 2) === 29
    assert Date.days_in_month(2013, 2) === 28
  end

  test "month_to_num" do
    assert Date.month_to_num("April") == 4
    assert Date.month_to_num("april") == 4
    assert Date.month_to_num("Apr") == 4
    assert Date.month_to_num("apr") == 4
    assert Date.month_to_num(:apr) == 4
  end

  test "day_to_num" do
    assert Date.day_to_num("Wednesday") == 3
    assert Date.day_to_num("wednesday") == 3
    assert Date.day_to_num("Wed") == 3
    assert Date.day_to_num("wed") == 3
    assert Date.day_to_num(:wed) == 3
  end

  test "is_leap" do
    assert not Date.is_leap?(Date.epoch())
    assert Date.is_leap?(2012)
    assert not Date.is_leap?(2100)
  end

  test "is_valid?" do
    assert Date.is_valid?(Date.now())
    assert Date.is_valid?(Date.from({1,1,1}))
    assert Date.is_valid?(Date.from({{1,1,1}, {1,1,1}}))
    assert Date.is_valid?(Date.from({{1,1,1}, {0,0,0}}))
    assert Date.is_valid?(Date.from({{1,1,1}, {23,59,59}}))
    assert Date.is_valid?({{1,1,1}, {1, 1, 1}, Timezone.get(:utc)})

    new_date = %DateTime{timezone: %TimezoneInfo{}}
    assert not Date.is_valid?(new_date |> Date.set([date: {12,13,14}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([date: {12,12,34}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([date: {1,0,1}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([date: {1,1,0}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([datetime: {{12,12,12}, {24,0,0}}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([datetime: {{12,12,12}, {23,60,0}}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([datetime: {{12,12,12}, {23,59,60}}, validate: false]))
    assert not Date.is_valid?(new_date |> Date.set([datetime: {{12,12,12}, {-1,59,59}}, validate: false]))
    assert Date.is_valid?({{12,12,12}, {1,59,59}, %TimezoneInfo{}})
    assert not Date.is_valid?({{12,12,12}, {-1,59,59}, Timezone.get(:utc)})
  end

  test "normalize" do
    tz = Timezone.get(:utc)
    date = { {1,13,44}, {-8,60,61}, tz }
    assert %DateTime{year: 1, month: 12, day: 31, hour: 0, minute: 59, second: 59, timezone: _} = Date.normalize(date)
  end

  test "set" do
    import Date.Convert, only: [to_gregorian: 1]

    eet = Timezone.get("Europe/Athens", Date.from({{2013,3,17}, {17,26,5}}))
    utc = Timezone.get(:utc)
    %TimezoneInfo{:abbreviation => eet_name, :offset_std => eet_offset_min} = eet
    %TimezoneInfo{:abbreviation => utc_name, :offset_std => utc_offset_min} = utc

    tuple = {{2013,3,17}, {17,26,5}}
    date = Date.from(tuple, "Europe/Athens")
    assert to_gregorian(Date.set(date, date: {1,1,1}))        === { {1,1,1}, {17,26,5}, {eet_offset_min/60, eet_name} }
    assert to_gregorian(Date.set(date, hour: 0))              === { {2013,3,17}, {0,26,5}, {eet_offset_min/60, eet_name} }
    assert to_gregorian(Date.set(date, timezone: Date.timezone(:utc, tuple))) === { {2013,3,17}, {17,26,5}, {utc_offset_min/60, utc_name} }

    assert to_gregorian(Date.set(date, [date: {1,1,1}, hour: 13, second: 61, timezone: utc]))    === { {1,1,1}, {13,26,59}, {utc_offset_min/60, utc_name} }
    assert to_gregorian(Date.set(date, [date: {-1,-2,-3}, hour: 33, second: 61, timezone: utc])) === { {0,1,1}, {23,26,59}, {utc_offset_min/60, utc_name} }
  end

  test "compare" do
    assert Date.compare(Date.epoch(), Date.zero()) === 1
    assert Date.compare(Date.zero(), Date.epoch()) === -1

    tz1   = Timezone.get(2)
    tz2   = Timezone.get(-3)
    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz1}
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: tz2}
    assert Date.compare(date1, date2) === 0

    tz3   = Timezone.get(3)
    date3 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz3}
    assert Date.compare(date1, date3) === 1

    date = Date.now()
    assert Date.compare(Date.epoch(), date) === -1

    assert Date.compare(date, :distant_past) === +1
    assert Date.compare(date, :distant_future) === -1
  end

  test "compare with granularity" do
    tz1   = Timezone.get(2)
    tz2   = Timezone.get(-3)
    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz1}
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: tz2}
    date3 = %DateTime{year: 2013, month: 4, day: 18, hour: 8, minute: 44, second: 10, timezone: tz2}
    date4 = %DateTime{year: 2013, month: 4, day: 18, hour: 8, minute: 44, second: 23, timezone: tz2}

    assert Date.compare(date1, date2, :years) === 0
    assert Date.compare(date1, date2, :months) === 0
    assert Date.compare(date1, date3, :months) === -1
    assert Date.compare(date3, date1, :months) === +1
    assert Date.compare(date1, date3, :weeks) === -1
    assert Date.compare(date1, date2, :days) === 0
    assert Date.compare(date1, date3, :days) === -1
    assert Date.compare(date1, date2, :hours) === 0
    assert Date.compare(date3, date4, :mins) === 0
    assert Date.compare(date3, date4, :secs) === -1
  end

  test "diff" do
    epoch = Date.epoch()
    date1 = Date.from({1971,1,1})
    date2 = Date.from({1973,1,1})

    assert Date.diff(date1, date2, :secs)   === -Date.diff(date2, date1, :secs)
    assert Date.diff(date1, date2, :mins)   === -Date.diff(date2, date1, :mins)
    assert Date.diff(date1, date2, :hours)  === -Date.diff(date2, date1, :hours)
    assert Date.diff(date1, date2, :days)   === -Date.diff(date2, date1, :days)
    assert Date.diff(date1, date2, :weeks)  === -Date.diff(date2, date1, :weeks)
    assert Date.diff(date1, date2, :months) === -Date.diff(date2, date1, :months)
    assert Date.diff(date1, date2, :years)  === -Date.diff(date2, date1, :years)

    assert Date.diff(date1, date2, :timestamp) === {63, 158400, 0}

    assert Date.diff(epoch, date1, :days) === 365
    assert Date.diff(epoch, date1, :secs) === 365 * 24 * 3600
    assert Date.diff(epoch, date1, :years) === 1

    # additional day is added because 1972 was a leap year
    assert Date.diff(epoch, date2, :days) === 365*3 + 1
    assert Date.diff(epoch, date2, :secs) === (365*3 + 1) * 24 * 3600
    assert Date.diff(epoch, date2, :years) === 3

    assert Date.diff(epoch, date1, :months) === 12
    assert Date.diff(epoch, date2, :months) === 36
    assert Date.diff(date1, date2, :months) === 24

    date1 = Date.from({1971,3,31})
    date2 = Date.from({1969,2,11})
    assert Date.diff(date1, date2, :months) === -25
    assert Date.diff(date2, date1, :months) === 25
  end

  test "shift by seconds" do
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

  test "shift by seconds with timezone" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")

    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 1, minute: 44, timezone: utc }
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: cst }
    assert %DateTime{minute: 49 , second: 0} = Date.shift(date1, secs: 5*60 )
    assert %DateTime{minute: 49 , second: 0} = Date.shift(date2, secs: 5*60 )


  end

  test "shift by minutes" do
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

  test "shift by minutes with timezone" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")

    chicago_noon = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 12, minute: 0, month: 2, ms: 0, second: 0, timezone: cst , year: 2014}
    utc_dinner = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 18, minute: 0, month: 2, ms: 0, second: 0, timezone: utc , year: 2014}

    assert %DateTime{ hour: 18, minute: 0, timezone: ^cst } = Date.shift(chicago_noon, mins: 360 )
    assert %DateTime{ hour: 12, minute: 0, timezone: ^utc } = Date.shift(utc_dinner, mins: -360 )

    date = Date.from({{2015, 09, 24}, {10, 0, 0}}, "America/Los_Angeles")
    shifted = Date.shift(date, mins: 45)
    assert "2015-09-24T10:45:00-07:00" = Timex.DateFormat.format!(shifted, "{ISO}")
  end

  test "shift by hours" do
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

  test "shift by days" do
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

  test "shift by weeks" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Date.from
    assert unchanged === shift(datetime, weeks: 0)

    assert %DateTime{year: 2013, month: 3, day: 12} = shift(datetime, weeks: 1)
    assert %DateTime{year: 2014, month: 3, day: 4}  = shift(datetime, weeks: 52)
    assert %DateTime{year: 2013, month: 2, day: 26} = shift(datetime, weeks: -1)
    assert %DateTime{year: 2012, month: 3, day: 6}  = shift(datetime, weeks: -52)

    date = Date.from(datetime)
    weekday = Date.weekday(date)
    Enum.each -53..53, fn n ->
      assert Date.shift(date, [weeks: n]) |> Date.weekday === weekday
    end
  end

  test "shift by months" do
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

  test "shift by years" do
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

  test "arbitrary shifts" do
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

  test "beginning_of_year" do
    year_start = Date.from {{2015, 1, 1},  {0, 0, 0}}
    assert Date.beginning_of_year(2015) == year_start
    assert Date.beginning_of_year(%DateTime{year: 2015, month: 6, day: 15}) == year_start
    assert Date.beginning_of_year(Date.from({2015, 6, 15})) == year_start
  end

  test "end_of_year" do
    year_end = Date.from {{2015, 12, 32},  {23, 59, 59}}
    assert Date.end_of_year(2015) == year_end
    assert Date.end_of_year(%DateTime{year: 2015, month: 6, day: 15}) == year_end
    assert Date.end_of_year(Date.from({2015, 6, 15})) == year_end
  end

  test "beginning_of_month" do
    assert Date.beginning_of_month(%DateTime{year: 2016, month: 2, day: 15}) == Date.from {{2016, 2, 1},  {0, 0, 0}}
    assert Date.beginning_of_month(Date.from({{2014,2,15},{14,14,14}})) == Date.from {{2014, 2, 1},  {0, 0, 0}}
  end

  test "end_of_month" do
    assert Date.end_of_month(%DateTime{year: 2016, month: 2, day: 15}) == Date.from {{2016, 2, 29},  {23, 59, 59}}
    refute Date.end_of_month(%DateTime{year: 2016, month: 2, day: 15}) == Date.from {{2016, 2, 28},  {23, 59, 59}}
    assert Date.end_of_month(Date.from({{2014,2,15},{14,14,14}})) == Date.from {{2014, 2, 28},  {23, 59, 59}}
    assert Date.end_of_month(2015, 11) == Date.from {{2015, 11, 30},  {23, 59, 59}}

    assert_raise FunctionClauseError, fn ->
      Date.end_of_month 2015, 13
    end
    assert_raise FunctionClauseError, fn ->
      Date.end_of_month -2015, 12
    end
  end

  test "beginning_of_quarter" do
    assert Date.beginning_of_quarter(%DateTime{year: 2016, month: 3, day: 15}) == Date.from {{2016, 1, 1},  {0, 0, 0}}
    assert Date.beginning_of_quarter(Date.from({{2014,2,15},{14,14,14}})) == Date.from {{2014, 1, 1},  {0, 0, 0}}
    assert Date.beginning_of_quarter(%DateTime{year: 2016, month: 5, day: 15}) == Date.from {{2016, 4, 1},  {0, 0, 0}}
    assert Date.beginning_of_quarter(%DateTime{year: 2016, month: 8, day: 15}) == Date.from {{2016, 7, 1},  {0, 0, 0}}
    assert Date.beginning_of_quarter(%DateTime{year: 2016, month: 11, day: 15}) == Date.from {{2016, 10, 1},  {0, 0, 0}}
  end

  test "end_of_quarter" do
    assert Date.end_of_quarter(%DateTime{year: 2016, month: 2, day: 15}) == Date.from {{2016, 3, 31},  {23, 59, 59}}
    assert Date.end_of_quarter(Date.from({{2014,2,15},{14,14,14}})) == Date.from {{2014, 3, 31},  {23, 59, 59}}
    assert Date.end_of_quarter(2015, 1) == Date.from {{2015, 3, 31}, {23, 59, 59}}

    assert_raise FunctionClauseError, fn ->
      Date.end_of_quarter 2015, 13
    end
  end

  test "beginning_of_week" do
    # Monday 30th November 2015
    date = Date.from({{2015, 11, 30}, {13, 30, 30}})

    # Monday..Monday
    monday = Date.from({2015, 11, 30})
    assert Date.days_to_beginning_of_week(date) == 0
    assert Date.days_to_beginning_of_week(date, 1) == 0
    assert Date.days_to_beginning_of_week(date, :mon) == 0
    assert Date.days_to_beginning_of_week(date, "Monday") == 0
    assert Date.beginning_of_week(date) == monday
    assert Date.beginning_of_week(date, 1) == monday
    assert Date.beginning_of_week(date, :mon) == monday
    assert Date.beginning_of_week(date, "Monday") == monday

    # Monday..Tuesday
    tuesday = Date.from({2015, 11, 24})
    assert Date.days_to_beginning_of_week(date, 2) == 6
    assert Date.days_to_beginning_of_week(date, :tue) == 6
    assert Date.days_to_beginning_of_week(date, "Tuesday") == 6
    assert Date.beginning_of_week(date, 2) == tuesday
    assert Date.beginning_of_week(date, :tue) == tuesday
    assert Date.beginning_of_week(date, "Tuesday") == tuesday

    # Monday..Wednesday
    wednesday = Date.from({2015, 11, 25})
    assert Date.days_to_beginning_of_week(date, 3) == 5
    assert Date.days_to_beginning_of_week(date, :wed) == 5
    assert Date.days_to_beginning_of_week(date, "Wednesday") == 5
    assert Date.beginning_of_week(date, 3) == wednesday
    assert Date.beginning_of_week(date, :wed) == wednesday
    assert Date.beginning_of_week(date, "Wednesday") == wednesday

    # Monday..Thursday
    thursday = Date.from({2015, 11, 26})
    assert Date.days_to_beginning_of_week(date, 4) == 4
    assert Date.days_to_beginning_of_week(date, :thu) == 4
    assert Date.days_to_beginning_of_week(date, "Thursday") == 4
    assert Date.beginning_of_week(date, 4) == thursday
    assert Date.beginning_of_week(date, :thu) == thursday
    assert Date.beginning_of_week(date, "Thursday") == thursday

    # Monday..Friday
    friday = Date.from({2015, 11, 27})
    assert Date.days_to_beginning_of_week(date, 5) == 3
    assert Date.days_to_beginning_of_week(date, :fri) == 3
    assert Date.days_to_beginning_of_week(date, "Friday") == 3
    assert Date.beginning_of_week(date, 5) == friday
    assert Date.beginning_of_week(date, :fri) == friday
    assert Date.beginning_of_week(date, "Friday") == friday

    # Monday..Saturday
    saturday = Date.from({2015, 11, 28})
    assert Date.days_to_beginning_of_week(date, 6) == 2
    assert Date.days_to_beginning_of_week(date, :sat) == 2
    assert Date.days_to_beginning_of_week(date, "Saturday") == 2
    assert Date.beginning_of_week(date, 6) == saturday
    assert Date.beginning_of_week(date, :sat) == saturday
    assert Date.beginning_of_week(date, "Saturday") == saturday

    # Monday..Sunday
    sunday = Date.from({2015, 11, 29})
    assert Date.days_to_beginning_of_week(date, 7) == 1
    assert Date.days_to_beginning_of_week(date, :sun) == 1
    assert Date.days_to_beginning_of_week(date, "Sunday") == 1
    assert Date.beginning_of_week(date, 7) == sunday
    assert Date.beginning_of_week(date, :sun) == sunday
    assert Date.beginning_of_week(date, "Sunday") == sunday

    # Invalid start of week - out of range
    assert_raise FunctionClauseError, fn ->
      assert Date.days_to_beginning_of_week(date, 0)
      assert Date.beginning_of_week(date, 0)
    end

    # Invalid start of week - out of range
    assert_raise FunctionClauseError, fn ->
      assert Date.days_to_beginning_of_week(date, 8)
      assert Date.beginning_of_week(date, 8)
    end

    # Invalid start of week string
    assert_raise FunctionClauseError, fn ->
      assert Date.days_to_beginning_of_week(date, "Made up day")
      assert Date.beginning_of_week(date, "Made up day")
    end
  end

  test "end_of_week" do
    # Monday 30th November 2015
    date = Date.from({2015, 11, 30})

    # Monday..Sunday
    sunday = Date.from({{2015, 12, 6}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date) == 6
    assert Date.days_to_end_of_week(date, 1) == 6
    assert Date.days_to_end_of_week(date, :mon) == 6
    assert Date.days_to_end_of_week(date, "Monday") == 6
    assert Date.end_of_week(date) == sunday
    assert Date.end_of_week(date, 1) == sunday
    assert Date.end_of_week(date, :mon) == sunday
    assert Date.end_of_week(date, "Monday") == sunday

    # Monday..Monday
    monday = Date.from({{2015, 11, 30}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date, 2) == 0
    assert Date.days_to_end_of_week(date, :tue) == 0
    assert Date.days_to_end_of_week(date, "Tuesday") == 0
    assert Date.end_of_week(date, 2) == monday
    assert Date.end_of_week(date, :tue) == monday
    assert Date.end_of_week(date, "Tuesday") == monday

    # Monday..Tuesday
    tuesday = Date.from({{2015, 12, 1}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date, 3) == 1
    assert Date.days_to_end_of_week(date, :wed) == 1
    assert Date.days_to_end_of_week(date, "Wednesday") == 1
    assert Date.end_of_week(date, 3) == tuesday
    assert Date.end_of_week(date, :wed) == tuesday
    assert Date.end_of_week(date, "Wednesday") == tuesday

    # Monday..Wednesday
    wednesday = Date.from({{2015, 12, 2}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date, 4) == 2
    assert Date.days_to_end_of_week(date, :thu) == 2
    assert Date.days_to_end_of_week(date, "Thursday") == 2
    assert Date.end_of_week(date, 4) == wednesday
    assert Date.end_of_week(date, :thu) == wednesday
    assert Date.end_of_week(date, "Thursday") == wednesday

    # Monday..Thursday
    thursday = Date.from({{2015, 12, 3}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date, 5) == 3
    assert Date.days_to_end_of_week(date, :fri) == 3
    assert Date.days_to_end_of_week(date, "Friday") == 3
    assert Date.end_of_week(date, 5) == thursday
    assert Date.end_of_week(date, :fri) == thursday
    assert Date.end_of_week(date, "Friday") == thursday

    # Monday..Friday
    friday = Date.from({{2015, 12, 4}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date, 6) == 4
    assert Date.days_to_end_of_week(date, :sat) == 4
    assert Date.days_to_end_of_week(date, "Saturday") == 4
    assert Date.end_of_week(date, 6) == friday
    assert Date.end_of_week(date, :sat) == friday
    assert Date.end_of_week(date, "Saturday") == friday

    # Monday..Saturday
    saturday = Date.from({{2015, 12, 5}, {23, 59, 59}})
    assert Date.days_to_end_of_week(date, 7) == 5
    assert Date.days_to_end_of_week(date, :sun) == 5
    assert Date.days_to_end_of_week(date, "Sunday") == 5
    assert Date.end_of_week(date, 7) == saturday
    assert Date.end_of_week(date, :sun) == saturday
    assert Date.end_of_week(date, "Sunday") == saturday

    # Invalid start of week - out of range
    assert_raise FunctionClauseError, fn ->
      assert Date.days_to_end_of_week(date, 0)
      assert Date.end_of_week(date, 0)
    end

    # Invalid start of week - out of range
    assert_raise FunctionClauseError, fn ->
      assert Date.days_to_end_of_week(date, 8)
      assert Date.end_of_week(date, 8)
    end

    # Invalid start of week string
    assert_raise FunctionClauseError, fn ->
      assert Date.days_to_end_of_week(date, "Made up day")
      assert Date.end_of_week(date, "Made up day")
    end
  end

  test "beginning_of_day" do
    date = Date.from({{2015, 1, 1}, {13, 14, 15}})
    assert Date.beginning_of_day(date) == Date.from({{2015, 1, 1}, {0, 0, 0}})
  end

  test "end_of_day" do
    date = Date.from({{2015, 1, 1}, {13, 14, 15}})
    assert Date.end_of_day(date) == Date.from({{2015, 1, 1}, {23, 59, 59}})
  end

  defp shift(date, spec) when is_list(spec) do
    date |> Date.from |> Date.shift(spec)
  end

end
