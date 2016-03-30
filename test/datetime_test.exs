defmodule DateTimeTests do
  use ExUnit.Case, async: true
  doctest Timex.DateTime

  use Timex

  import ExUnit.CaptureIO

  test "today" do
    today = DateTime.today
    today_with_tz = DateTime.today("America/Chicago")
    refute today.timezone == today_with_tz.timezone

    tz = Timezone.get("America/Chicago", today)
    today_with_tz = DateTime.today(tz)
    refute today.timezone == today_with_tz.timezone

    local_today = DateTime.today(:local)
    refute today.timezone == local_today.timezone
    assert Timex.equal?(today, DateTime.today(:utc))
  end

  test "now" do
    # We cannot assert matching to a specific value. However, we can still do
    # some sanity checks
    now = DateTime.now
    assert {{_, _, _}, {_, _, _}, {0, "UTC"}} = Timex.to_gregorian(now)

    now_secs = DateTime.now(:seconds)
    now_days = DateTime.now(:days)
    assert is_integer(now_secs)
    assert is_integer(now_days)
    assert now_secs > now_days

    assert capture_io(:stderr, fn ->
      DateTime.now(:secs)
    end) =~ ~r/deprecated/
  end

  test "local" do
    local     = DateTime.local
    %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, millisecond: ms} = local
    localdate = Timex.datetime({{y,m,d}, {h,min,s,ms}}, :local)
    assert local === DateTime.local(localdate)

    today = DateTime.today
    local_today = DateTime.local(today)
    refute today.timezone == local_today.timezone
  end

  test "universal" do
    uni     = DateTime.universal()
    %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, millisecond: ms} = uni
    unidate = Timex.datetime({{y,m,d}, {h,min,s,ms}})
    assert uni === DateTime.universal(unidate)
  end

  test "zero" do
    zero = DateTime.zero
    { date, time, {0, "UTC"} } = zero |> Timex.to_gregorian
    assert :calendar.datetime_to_gregorian_seconds({date,time}) === 0
  end

  test "epoch" do
    epoch = DateTime.epoch
    assert { {1970,1,1}, {0,0,0}, {0, "UTC"} } = Timex.to_gregorian(epoch)
    assert DateTime.to_seconds(epoch) === 0
    assert DateTime.to_days(epoch) === 0
    assert DateTime.to_seconds(epoch, :zero) === DateTime.epoch(:seconds)
    assert DateTime.to_timestamp(epoch) === DateTime.epoch(:timestamp)
  end

  test "from date" do
    date = {2000, 11, 11}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 0, minute: 0, second: 0} = date |> Timex.datetime

    localdate    = Timex.datetime(date, :local)
    { _d, _t, tz } = Timex.to_gregorian(localdate)
    localtz      = localdate.timezone

    diff = Timezone.diff(localdate, %TimezoneInfo{})
    diff = cond do
      rem(diff, 60) > 0 -> diff
      :else             -> div(diff, 60)
    end
    assert tz === {diff, localtz.abbreviation}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 0, minute: 0, second: 0, timezone: _} = date |> Timex.datetime(:local)

    date = Timex.datetime(date)
    { d, t, tz } = Timex.to_gregorian(date)
    datetz = date.timezone

    diff = Timezone.diff(date, %TimezoneInfo{})
    diff = cond do
      rem(diff, 60) > 0 -> diff
      :else             -> div(diff, 60)
    end
    assert tz === {diff,datetz.abbreviation}
    assert {^d,^t} = {{2000,11,11}, {0,0,0}}

    # Converting to a datetime and back to gregorian should yield the original date
    fulldate = Timex.datetime(d, Timex.timezone("Europe/Athens", {d, {0,0,0}}))
    { d, t, _ } = fulldate |> Timex.to_gregorian
    assert {^d,^t} = {{2000,11,11}, {0,0,0}}
  end

  test "from datetime" do
    assert Timex.datetime({{1970,1,1}, {0,0,0}}) === Timex.datetime({1970,1,1})
    assert 0 === Timex.datetime({{1970,1,1}, {0,0,0}}) |> DateTime.to_seconds

    date = {{2000, 11, 11}, {1, 0, 0}}
    assert %DateTime{year: 2000, month: 11, day: 11, hour: 1, minute: 0, second: 0} = date |> Timex.datetime |> DateTime.universal

    { d, time, {0, "UTC"} } = date |> Timex.datetime |> Timex.to_gregorian
    assert {d,time} === date

    { d, time } = date |> Timex.datetime |> Timex.to_erlang_datetime
    assert {d,time} === date

    { d, time, _ } = date |> Timex.datetime(Timex.timezone("Europe/Athens", date)) |> Timex.to_gregorian
    assert {d,time} === {{2000,11,11}, {1,0,0}}
  end

  test "from timestamp" do
    now = Time.now
    assert trunc(Time.to_seconds(now)) === now |> DateTime.from_timestamp |> DateTime.to_seconds
    assert 0 === {0,0,0} |> DateTime.from_timestamp |> DateTime.to_seconds
    assert -DateTime.epoch(:seconds) === {0,0,0} |> DateTime.from_timestamp(:zero) |> DateTime.to_seconds
  end

  test "from milliseconds" do
    msecs = 1451425764069
    date = Timex.datetime({{2015, 12, 29}, {21, 49, 24, 69}})
    assert date == DateTime.from_milliseconds(msecs)
  end

  test "from seconds" do
    now_sec = trunc(Time.now(:seconds))
    assert now_sec === now_sec |> DateTime.from_seconds |> DateTime.to_seconds
    assert now_sec - DateTime.epoch(:seconds) === now_sec |> DateTime.from_seconds(:zero) |> DateTime.to_seconds
  end

  test "from days" do
    assert %DateTime{year: 1970, month: 1, day: 31, hour: 0, minute: 0, second: 0} = DateTime.from_days(30)
    assert %DateTime{year: 1970, month: 2, day: 1, hour: 0, minute: 0, second: 0} = DateTime.from_days(31)
  end

  test "from phoenix_datetime_select" do
    date = %{"day" => "05", "hour" => "12", "min" => "35", "month" => "2", "year" => "2016"}
    assert %DateTime{year: 2016, month: 2, day: 05, hour: 12, minute: 35, second: 0} = Timex.datetime(date)
  end

  test "to timestamp" do
    assert {0,0,0} === DateTime.epoch |> DateTime.to_timestamp
    assert {62167,219200,0} === DateTime.epoch |> DateTime.to_timestamp(:zero)
    assert DateTime.epoch(:seconds) == DateTime.epoch |> DateTime.to_timestamp(:zero) |> Time.to_seconds

    # Force some micro seconds to appear in case we are unlucky and hit when micro := 0
    {mega, secs, _micro} = Time.now
    now = {mega, secs, 864123}

    # deliberately match against 864000 AND NOT 864123 since DateTime only
    # takes milliseconds into account
    assert {mega, secs, 864000} === DateTime.from_timestamp(now, :epoch) |> DateTime.to_timestamp(:epoch)
  end

  test "to seconds" do
    date = DateTime.now()
    assert DateTime.to_seconds(date, :zero) === date |> Timex.to_erlang_datetime |> :calendar.datetime_to_gregorian_seconds

    ts = Time.now()
    assert trunc(Time.to_seconds(ts)) === ts |> DateTime.from_timestamp |> DateTime.to_seconds

    date = Timex.datetime({{1999,1,2}, {12,13,14}})
    assert DateTime.to_seconds(date) === 915279194
    assert DateTime.to_seconds(date, :zero) === 63082498394

    assert DateTime.to_seconds(DateTime.epoch()) === 0
    assert DateTime.to_seconds(DateTime.epoch(), :zero) === 62167219200

    date = Timex.datetime({{2014,11,17},{0,0,0}}, "America/Los_Angeles")
    assert DateTime.to_seconds(date) == 1416211200

    ndate = Timex.datetime({2014,11,17})
    assert DateTime.to_seconds(ndate) == 1416182400

  end

  test "to days" do
    date = Timex.datetime({2013,3,16})
    assert DateTime.to_days(date) === 15780
    assert DateTime.to_days(date, :zero) === 735308

    assert DateTime.to_days(DateTime.epoch()) === 0
    assert DateTime.to_days(DateTime.epoch(), :zero) === 719528
  end

  test "shift by seconds" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Timex.datetime
    assert unchanged === shift(datetime, seconds: 0)

    assert %DateTime{minute: 23, second: 24} = shift(datetime, seconds: 1)
    assert %DateTime{minute: 23, second: 59} = shift(datetime, seconds: 36)
    assert %DateTime{minute: 24, second: 0} = shift(datetime, seconds: 37)
    assert %DateTime{minute: 24, second: 1} = shift(datetime, seconds: 38)
    assert %DateTime{minute: 25, second: 1} = shift(datetime, seconds: 38+60)
    assert %DateTime{minute: 59, second: 59} = shift(datetime, seconds: 38+60*35+58)
    assert %DateTime{month: 3, day: 6, hour: 0, minute: 0, second: 0} = shift(datetime, seconds: 38+60*35+59)
    assert %DateTime{month: 3, day: 6, hour: 0, minute: 0, second: 1} = shift(datetime, seconds: 38+60*36)
    assert %DateTime{month: 3, day: 6, hour: 23, minute: 23, second: 23} = shift(datetime, seconds: 24*3600)
    assert %DateTime{month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, seconds: 24*3600*365)

    assert %DateTime{minute: 23, second: 22} = shift(datetime, seconds: -1)
    assert %DateTime{minute: 23, second: 0} = shift(datetime, seconds: -23)
    assert %DateTime{minute: 22, second: 59} = shift(datetime, seconds: -24)
    assert %DateTime{hour: 23, minute: 0, second: 23} = shift(datetime, seconds: -23*60)
    assert %DateTime{hour: 22, minute: 59, second: 23} = shift(datetime, seconds: -24*60)
    assert %DateTime{year: 2013, month: 3, day: 5, hour: 0, minute: 0, second: 0} = shift(datetime, seconds: -23*3600-23*60-23)
    assert %DateTime{year: 2013, month: 3, day: 4, hour: 23, minute: 59, second: 59} = shift(datetime, seconds: -23*3600-23*60-24)
    assert %DateTime{year: 2013, month: 3, day: 4, hour: 23, minute: 23, second: 23} = shift(datetime, seconds: -24*3600)
    assert %DateTime{year: 2012, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, seconds: -24*3600*365)
    assert %DateTime{year: 2011, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, seconds: -24*3600*(365*2+1))   # +1 day for leap year 2012
  end

  test "shift by seconds with timezone" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago")

    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 1, minute: 44, timezone: utc }
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: cst }
    assert %DateTime{minute: 49 , second: 0} = Timex.shift(date1, seconds: 5*60 )
    assert %DateTime{minute: 49 , second: 0} = Timex.shift(date2, seconds: 5*60 )
  end

  test "shift by minutes" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Timex.datetime
    assert unchanged === shift(datetime, minutes: 0)

    assert %DateTime{hour: 23, minute: 24, second: 23} = shift(datetime, minutes: 1)
    assert %DateTime{hour: 23, minute: 59, second: 23} = shift(datetime, minutes: 36)
    assert %DateTime{year: 2013, month: 3, day: 6, hour: 0, minute: 0, second: 23} = shift(datetime, minutes: 37)
    assert %DateTime{year: 2013, month: 3, day: 6, hour: 0, minute: 1, second: 23} = shift(datetime, minutes: 38)
    assert %DateTime{year: 2014, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, minutes: 60*24*365)

    assert %DateTime{hour: 23, minute: 22, second: 23} = shift(datetime, minutes: -1)
    assert %DateTime{hour: 23, minute: 0, second: 23} = shift(datetime, minutes: -23)
    assert %DateTime{hour: 22, minute: 59, second: 23} = shift(datetime, minutes: -24)
    assert %DateTime{month: 3, day: 4, hour: 23, minute: 59, second: 23} = shift(datetime, minutes: -23*60-24)
    assert %DateTime{year: 2011, month: 3, day: 5, hour: 23, minute: 23, second: 23} = shift(datetime, minutes: -60*24*(365*2 + 1))
  end

  test "shift by minutes with timezone" do
    utc = Timezone.get(:utc, {{2014,2,24},{12,0,0}})
    cst = Timezone.get("America/Chicago", {{2014,2,24},{18,0,0}})

    chicago_noon = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 12, minute: 0, month: 2, millisecond: 0, second: 0, timezone: cst , year: 2014}
    utc_dinner = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 18, minute: 0, month: 2, millisecond: 0, second: 0, timezone: utc , year: 2014}

    assert %DateTime{ :hour => 18, :minute => 0, :timezone => ^cst } = Timex.shift(chicago_noon, minutes: 360 )
    assert %DateTime{ :hour => 12, :minute => 0, :timezone => ^utc } = Timex.shift(utc_dinner, minutes: -360 )

    date = Timex.datetime({{2015, 09, 24}, {10, 0, 0}}, "America/Los_Angeles")
    shifted = Timex.shift(date, minutes: 45)
    assert "2015-09-24T10:45:00-07:00" = Timex.format!(shifted, "{ISO}")
  end

  test "shift by hours" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = {date,time}

    unchanged = datetime |> Timex.datetime
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

    unchanged = datetime |> Timex.datetime
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

    unchanged = datetime |> Timex.datetime
    assert unchanged === shift(datetime, weeks: 0)

    assert %DateTime{year: 2013, month: 3, day: 12} = shift(datetime, weeks: 1)
    assert %DateTime{year: 2014, month: 3, day: 4}  = shift(datetime, weeks: 52)
    assert %DateTime{year: 2013, month: 2, day: 26} = shift(datetime, weeks: -1)
    assert %DateTime{year: 2012, month: 3, day: 6}  = shift(datetime, weeks: -52)

    date = Timex.datetime(datetime)
    weekday = Timex.weekday(date)
    Enum.each -53..53, fn n ->
      assert Timex.shift(date, [weeks: n]) |> Timex.weekday === weekday
    end
  end

  test "shift by months" do
    date = {2013,3,5}
    time = {23,23,23}
    datetime = { date, time }

    unchanged = datetime |> Timex.datetime
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

    unchanged = datetime |> Timex.datetime
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
    assert %DateTime{year: 2013, month: 6, day: 6} = shift(datetime, months: 3, days: 1)
    assert %DateTime{year: 2013, month: 3, day: 18, second: 36} = shift(datetime, seconds: 13, days: -1, weeks: 2)

    datetime = { {2012,2,29}, {23,23,23} }
    assert %DateTime{year: 2013, month: 2, day: 28} = shift(datetime, months: 12)

    assert %DateTime{year: 2002, month: 3, day: 1} = shift(datetime, years: -10, days: 1)
    assert %DateTime{year: 2012, month: 2, day: 29, hour: 23, minute: 59, second: 59} = shift(datetime, minutes: 36, seconds: 36)
    assert %DateTime{year: 2012, month: 3, day: 1, hour: 0, minute: 0, second: 0} = shift(datetime, minutes: 36, seconds: 37)
  end
  defp shift(date, spec) when is_list(spec) do
    date |> Timex.datetime |> Timex.shift(spec)
  end

end
