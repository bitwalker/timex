defmodule DateTests do
  use ExUnit.Case, async: true
  doctest Timex.Date

  use Timex

  import ExUnit.CaptureIO

  test "deprecations produce stderr warnings" do
    assert capture_io(:stderr, fn ->
      Date.epoch(:secs)
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.from(Time.now, :timestamp)
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.from(Time.to_microseconds(Time.now), :us)
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.from(Time.to_milliseconds(Time.now), :msecs)
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.from(Time.to_seconds(Time.now), :secs)
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.from(Time.to_days(Time.now), :days)
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [mins: 5*60*24])
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [secs: 5*60*60*24])
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [secs: 5])
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [msecs: 5_000*60*60*24])
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [msecs: 5_000])
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [mins: 24*60*2])
    end) =~ ~r/deprecated/

    assert capture_io(:stderr, fn ->
      Date.shift(Date.today, [mins: 24])
    end) =~ ~r/deprecated/

  end

  test "today" do
    assert %Date{} = Date.today
  end

  test "today with timezone" do
    today = Date.today
    assert ^today = Date.today("UTC")
    assert ^today = Date.today(:utc)

    local_timezone = Timezone.local(DateTime.today)
    local_today = Date.today(local_timezone)
    assert ^local_today = Date.today(:local)
  end

  test "now" do
    now_days = Date.now(:days)
    assert is_integer(now_days)
    assert now_days > (1416182400 / (40*365*24*60*60))
  end

  test "zero" do
    zero = Date.zero
    { date, time, _tz } = Timex.to_gregorian(zero)
    assert :calendar.datetime_to_gregorian_seconds({date,time}) === 0
  end

  test "epoch" do
    epoch = Date.epoch
    assert { {1970,1,1}, {0,0,0}, {0, "GMT"} } = Timex.to_gregorian(epoch)
    assert Date.to_seconds(epoch) === 0
    assert Date.to_days(epoch) === 0
    assert Date.to_seconds(epoch, :zero) === Date.epoch(:seconds)
  end

  test "from date" do
    date = {2000, 11, 11}
    assert %Date{year: 2000, month: 11, day: 11} = date |> Timex.date

    { _d, _t, _tz } = date |> Timex.date |> Timex.to_gregorian
    assert %Date{year: 2000, month: 11, day: 11} = date |> Timex.date

    assert %Date{year: 2000, month: 11, day: 11} = Date.from({{2000,11,11},{0,0,0}})

    { date, time, _tz } = date |> Timex.date |> Timex.to_gregorian
    assert {date,time} === {{2000,11,11}, {0,0,0}}

    # Converting to a datetime and back to gregorian should yield the original date
    fulldate = Timex.date(date)
    { date, time, _ } = fulldate |> Timex.to_gregorian
    assert {date,time} === {{2000,11,11}, {0,0,0}}
  end

  test "from datetime" do
    assert Timex.date({{1970,1,1}, {0,0,0}}) === Timex.date({1970,1,1})
    assert 0 === Timex.date({{1970,1,1}, {0,0,0}}) |> Date.to_seconds

    date = {{2000, 11, 11}, {1, 0, 0}}
    assert %Date{year: 2000, month: 11, day: 11} = Timex.date(date)

    date_with_ms = {{2000,11,11}, {1,0,0,0}}
    assert %Date{year: 2000, month: 11, day: 11} = Date.from_erl(date_with_ms)

    { d, _time, _tz } = date |> Timex.date |> Timex.to_gregorian
    assert {^d,{_,_,_}} = date

    { d, _time } = date |> Timex.date |> Timex.to_erlang_datetime
    assert {^d,{_,_,_}} = date

    { d, _time, _ } = date |> Timex.date |> Timex.to_gregorian
    assert {^d,{_,_,_}} = {{2000,11,11}, {0,0,0}}
  end

  test "from timestamp" do
    seconds = DateTime.to_seconds(DateTime.from({2014, 1, 2}))
    assert seconds === Date.from_timestamp(Time.to_timestamp(seconds, :seconds)) |> Date.to_seconds
    assert 0 === {0,0,0} |> Date.from_timestamp |> Date.to_seconds
    assert -Date.epoch(:seconds) === {0,0,0} |> Date.from_timestamp(:zero) |> Date.to_seconds
  end

  test "from microseconds" do
    today = Date.today
    micro = Time.to_microseconds(Date.to_timestamp(today))
    assert ^today = Date.from_microseconds(micro)
  end

  test "from milliseconds" do
    msecs = 1451425764069
    date = Timex.date({{2015, 12, 29}, {21, 49, 24, 69}})
    assert date == Date.from_milliseconds(msecs)
  end

  test "from seconds" do
    seconds = DateTime.to_seconds(DateTime.from({2014, 2, 4}))
    assert seconds === seconds |> Date.from_seconds |> Date.to_seconds
    assert seconds - Date.epoch(:seconds) === seconds |> Date.from_seconds(:zero) |> Date.to_seconds

    seconds = Date.to_seconds(Date.from({2014,2,4}))
    assert ^seconds = Date.to_secs(Date.from({2014,2,4}))

    seconds = Date.to_seconds(Date.from({2014,2,4}), :zero)
    assert ^seconds = Date.to_secs(Date.from({2014,2,4}), :zero)
  end

  test "from days" do
    assert %Date{year: 1970, month: 1, day: 31} = Date.from_days(30)
    assert %Date{year: 1970, month: 2, day: 1} = Date.from_days(31)
  end

  test "from phoenix_datetime_select" do
    date = %{"day" => "05", "hour" => "12", "min" => "35", "month" => "2", "year" => "2016"}
    assert %Date{year: 2016, month: 2, day: 05} = Timex.date(date)
  end

  test "to seconds" do
    date = Date.now()
    assert Date.to_seconds(date, :zero) === date |> Timex.to_erlang_datetime |> :calendar.datetime_to_gregorian_seconds

    date = Timex.date({{1999,1,2}, {0,0,0}})
    assert Date.to_seconds(date) === 915235200
    assert Date.to_seconds(date, :zero) === 63082454400

    assert Date.to_seconds(Date.epoch()) === 0
    assert Date.to_seconds(Date.epoch(), :zero) === 62167219200

    date = Timex.date({{2014,11,17},{0,0,0}})
    assert Date.to_seconds(date) == 1416182400

    ndate = Timex.date({2014,11,17})
    assert Date.to_seconds(ndate) == 1416182400

  end

  test "to days" do
    date = Timex.date({2013,3,16})
    assert Date.to_days(date) === 15780
    assert Date.to_days(date, :zero) === 735308

    assert Date.to_days(Date.epoch()) === 0
    assert Date.to_days(Date.epoch(), :zero) === 719528
  end

  test "normalize" do
    date = {-1,13,44}
    assert %Date{year: 0, month: 12, day: 31} = Timex.normalize(date)
  end

  test "set" do
    import Timex.Convertable, only: [to_gregorian: 1]

    tuple = {2013,3,17}
    date = Timex.date(tuple)
    assert to_gregorian(Timex.set(date, date: {1,1,1}))        === { {1,1,1}, {0,0,0}, {0, "GMT"} }
    assert to_gregorian(Timex.set(date, hour: 0))              === { {2013,3,17}, {0,0,0}, {0, "GMT"} }
    assert to_gregorian(Timex.set(date, timezone: Timezone.get(:utc, tuple))) === { {2013,3,17}, {0,0,0}, {0, "GMT"} }

    utc = Timezone.get(:utc)

    assert to_gregorian(Timex.set(date, [date: {1,1,1}, hour: 13, second: 61, timezone: utc]))    === { {1,1,1}, {0,0,0}, {0, "GMT"} }
    assert to_gregorian(Timex.set(date, [date: {-1,-2,-3}, hour: 33, second: 61, timezone: utc])) === { {0,1,1}, {0,0,0}, {0, "GMT"} }

    date = Date.from({2016,2,29})

    assert {:error, _} = Timex.set(date, [foo: 1, validate: true])
    assert %Date{:year => 2016, :month => 3, :day => 1} = Timex.set(date, [date: {2016, 3, 5}, day: 1, validate: false])
    assert %Date{:year => 2017, :month => 3, :day => 5} = Timex.set(date, [date: {2016, 3, 5}, year: 2017, validate: false])
    assert %Date{:year => 2016, :month => 3, :day => 1} = Timex.set(date, [datetime: {{2016, 3, 5},{0,0,0}}, day: 1, validate: false])
    assert %Date{:year => 2016, :month => 3, :day => 1} = Timex.set(date, [datetime: {{2016, 3, 5},{0,0,0}}, day: 1])
    assert capture_io(:stderr, fn ->
      Timex.set(date, [ms: 10000000])
    end) =~ ~r/deprecated/
  end

  test "shift by seconds" do
    date_tuple = {2013,3,5}
    date = Timex.date(date_tuple)

    assert ^date = shift(date, seconds: 0)

    assert ^date = shift(date, timestamp: {0,0,0})
    assert ^date = shift(date, seconds: 1)
    assert ^date = shift(date, seconds: 36)
    assert ^date = shift(date, seconds: 37)
    assert ^date = shift(date, seconds: 38)
    assert ^date = shift(date, seconds: 38+60)
    assert ^date = shift(date, seconds: 38+60*35+58)
    assert %Date{month: 3, day: 5} = shift(date, seconds: 38+60*35+59)
    assert %Date{month: 3, day: 5} = shift(date, seconds: 24*3600*365)

    assert ^date = shift(date, seconds: -1)
    assert ^date = shift(date, seconds: -23)
    assert ^date = shift(date, seconds: -24)
    assert ^date = shift(date, seconds: -23*60)
    assert ^date = shift(date, seconds: -24*60)
    assert %Date{year: 2013, month: 3, day: 5} = shift(date, seconds: -23*3600-23*60-23)
    assert %Date{year: 2013, month: 3, day: 5} = shift(date, seconds: -23*3600-23*60-24)
    assert %Date{year: 2013, month: 3, day: 4} = shift(date, seconds: -24*3600)
    assert %Date{year: 2012, month: 3, day: 5} = shift(date, seconds: -24*3600*365)
    assert %Date{year: 2011, month: 3, day: 5} = shift(date, seconds: -24*3600*(365*2+1))   # +1 day for leap year 2012
  end

  test "shift by minutes" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Timex.date
    assert unchanged === shift(datetime, minutes: 0)

    assert %Date{year: 2013, month: 3, day: 5} = shift(datetime, minutes: 37)
    assert %Date{year: 2013, month: 3, day: 5} = shift(datetime, minutes: 38)
    assert %Date{year: 2014, month: 3, day: 5} = shift(datetime, minutes: 60*24*365)

    assert %Date{month: 3, day: 5} = shift(datetime, minutes: -23*60-24)
    assert %Date{year: 2011, month: 3, day: 5} = shift(datetime, minutes: -60*24*(365*2 + 1))
  end

  test "shift by hours" do
    date = Timex.date({2013,3,5})
    assert ^date = shift(date, hours: 0)

    assert %Date{month: 3, day: 5} = shift(date, hours: 1)
    assert %Date{month: 3, day: 6} = shift(date, hours: 24)
    assert %Date{month: 3, day: 6} = shift(date, hours: 25)
    assert %Date{month: 4, day: 4} = shift(date, hours: 24*30)
    assert %Date{month: 3, day: 5} = shift(date, hours: 24*365)

    assert %Date{month: 3, day: 5} = shift(date, hours: -1)
    assert %Date{month: 3, day: 5} = shift(date, hours: -23)
    assert %Date{month: 3, day: 4} = shift(date, hours: -24)
    assert %Date{month: 3, day: 5} = shift(date, hours: -24*(365*2 + 1))
  end

  test "shift by days" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Timex.date
    assert unchanged === shift(datetime, days: 0)

    assert %Date{year: 2013, month: 3, day: 6} = shift(datetime, days: 1)
    assert %Date{year: 2013, month: 4, day: 1} = shift(datetime, days: 27)
    assert %Date{year: 2014, month: 3, day: 5} = shift(datetime, days: 365)

    assert %Date{year: 2013, month: 3, day: 4} = shift(datetime, days: -1)
    assert %Date{year: 2013, month: 2, day: 28} = shift(datetime, days: -5)
    assert %Date{year: 2012, month: 3, day: 5} = shift(datetime, days: -365)
    assert %Date{year: 2011, month: 3, day: 5} = shift(datetime, days: -365*2-1)
  end

  test "shift by weeks" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Timex.date
    assert unchanged === shift(datetime, weeks: 0)

    assert %Date{year: 2013, month: 3, day: 12} = shift(datetime, weeks: 1)
    assert %Date{year: 2014, month: 3, day: 4}  = shift(datetime, weeks: 52)
    assert %Date{year: 2013, month: 2, day: 26} = shift(datetime, weeks: -1)
    assert %Date{year: 2012, month: 3, day: 6}  = shift(datetime, weeks: -52)

    date = Timex.date(datetime)
    weekday = Timex.weekday(date)
    Enum.each -53..53, fn n ->
      assert Timex.shift(date, [weeks: n]) |> Timex.weekday === weekday
    end
  end

  test "shift by months" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Timex.date
    assert unchanged === shift(datetime, months: 0)

    assert %Date{year: 2013, month: 4, day: 5} = shift(datetime, months: 1)
    assert %Date{year: 2014, month: 1, day: 5} = shift(datetime, months: 10)
    assert %Date{year: 2013, month: 1, day: 5} = shift(datetime, months: -2)
    assert %Date{year: 2012, month: 3, day: 5} = shift(datetime, months: -12)
    assert %Date{year: 2012, month: 9, day: 5} = shift(datetime, months: -6)

    datetime = { {2013,3,31}, time }
    assert %Date{year: 2013, month: 4, day: 30} = shift(datetime, months: 1)
    assert %Date{year: 2013, month: 2, day: 28} = shift(datetime, months: -1)
  end

  test "shift by years" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Timex.date
    assert unchanged === shift(datetime, years: 0)

    assert %Date{year: 2014, month: 3, day: 5} = shift(datetime, years: 1)
    assert %Date{year: 2011, month: 3, day: 5} = shift(datetime, years: -2)

    datetime = { {2012,2,29}, time }
    assert %Date{year: 2013, month: 2, day: 28} = shift(datetime, years: 1)
    assert %Date{year: 2016, month: 2, day: 29} = shift(datetime, years: 4)
    assert %Date{year: 2011, month: 2, day: 28} = shift(datetime, years: -1)
    assert %Date{year: 2008, month: 2, day: 29} = shift(datetime, years: -4)
  end

  test "arbitrary shifts" do
    datetime = { {2013,3,5}, {23,23,23} }
    assert %Date{year: 2013, month: 6, day: 5} = shift(datetime, months: 3)
    assert %Date{year: 2013, month: 6, day: 6} = shift(datetime, months: 3, days: 1)
    assert %Date{year: 2013, month: 3, day: 18} = shift(datetime, seconds: 13, days: -1, weeks: 2)

    datetime = { {2012,2,29}, {23,23,23} }
    assert %Date{year: 2013, month: 2, day: 28} = shift(datetime, months: 12)

    assert %Date{year: 2002, month: 3, day: 1} = shift(datetime, years: -10, days: 1)
    assert %Date{year: 2012, month: 2, day: 29} = shift(datetime, minutes: 36, seconds: 36)
    assert %Date{year: 2012, month: 2, day: 29} = shift(datetime, minutes: 36, seconds: 37)
  end

  defp shift(date, spec) when is_list(spec) do
    date |> Timex.date |> Timex.shift(spec)
  end

end
