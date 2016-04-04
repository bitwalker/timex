defmodule TimexTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex

  test "century" do
    assert 21 === Timex.century

    date = Timex.datetime({{2015, 6, 24}, {14, 27, 52}})
    c = date |> Timex.century
    assert 21 === c
  end

  test "add" do
    date     = Timex.datetime({{2015, 6, 24}, {14, 27, 52}})
    expected = Timex.datetime({{2015, 7, 2}, {14, 27, 52}})
    result   = date |> Timex.add(Time.to_timestamp(8, :days))
    assert expected === result
  end

  test "subtract" do
    date     = Timex.datetime({{2015, 6, 24}, {14, 27, 52}})
    expected = Timex.datetime({{2015, 6, 16}, {14, 27, 52}})
    result   = date |> Timex.subtract(Time.to_timestamp(8, :days))
    assert expected === result
  end

  test "weekday" do
    localdate = {{2013,3,17},{11,59,10}}
    assert Timex.weekday(Timex.datetime(localdate)) === 7
    assert Timex.weekday(DateTime.epoch()) === 4
  end

  test "day" do
    assert Timex.day(Timex.datetime({3,1,1})) === 1
    assert Timex.day(Timex.datetime({3,2,1})) === 32
    assert Timex.day(Timex.datetime({3,12,31})) === 365
    assert Timex.day(Timex.datetime({2012,12,31})) === 366
  end

  test "week" do
    localdate = {{2013,3,17},{11,59,10}}
    assert Timex.iso_week(localdate) === {2013,11}
    assert Timex.iso_week(Timex.datetime(localdate)) === {2013,11}
    assert Timex.iso_week(DateTime.epoch()) === {1970,1}
  end

  test "iso_triplet" do
    localdate = {{2013,3,17},{11,59,10}}
    assert Timex.iso_triplet(Timex.datetime(localdate)) === {2013,11,7}
    assert Timex.iso_triplet(DateTime.epoch()) === {1970,1,4}
  end

  test "days_in_month" do
    localdate = {{2013,2,17},{11,59,10}}
    assert Timex.days_in_month(Timex.datetime(localdate)) === 28

    localdate = {{2000,2,17},{11,59,10}}
    assert Timex.days_in_month(Timex.datetime(localdate)) === 29

    assert Timex.days_in_month(DateTime.epoch()) === 31
    assert Timex.days_in_month(2012, 2) === 29
    assert Timex.days_in_month(2013, 2) === 28
  end

  test "month_to_num" do
    assert Timex.month_to_num("April") == 4
    assert Timex.month_to_num("april") == 4
    assert Timex.month_to_num("Apr") == 4
    assert Timex.month_to_num("apr") == 4
    assert Timex.month_to_num(:apr) == 4
  end

  test "day_to_num" do
    assert Timex.day_to_num("Wednesday") == 3
    assert Timex.day_to_num("wednesday") == 3
    assert Timex.day_to_num("Wed") == 3
    assert Timex.day_to_num("wed") == 3
    assert Timex.day_to_num(:wed) == 3
  end

  test "is_leap" do
    assert not Timex.is_leap?(DateTime.epoch())
    assert Timex.is_leap?(2012)
    assert not Timex.is_leap?(2100)
  end

  test "is_valid?" do
    assert Timex.is_valid?(DateTime.now())
    assert Timex.is_valid?(Timex.datetime({1,1,1}))
    assert Timex.is_valid?(Timex.datetime({{1,1,1}, {1,1,1}}))
    assert Timex.is_valid?(Timex.datetime({{1,1,1}, {0,0,0}}))
    assert Timex.is_valid?(Timex.datetime({{1,1,1}, {23,59,59}}))
    assert Timex.is_valid?({{1,1,1}, {1, 1, 1}, Timezone.get(:utc)})

    new_date = %DateTime{timezone: %TimezoneInfo{}}
    assert not Timex.is_valid?(new_date |> Timex.set([date: {12,13,14}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([date: {12,12,34}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([date: {1,0,1}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([date: {1,1,0}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([datetime: {{12,12,12}, {24,0,0}}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([datetime: {{12,12,12}, {23,60,0}}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([datetime: {{12,12,12}, {23,59,60}}, validate: false]))
    assert not Timex.is_valid?(new_date |> Timex.set([datetime: {{12,12,12}, {-1,59,59}}, validate: false]))
    assert Timex.is_valid?({{12,12,12}, {1,59,59}, %TimezoneInfo{}})
    assert not Timex.is_valid?({{12,12,12}, {-1,59,59}, Timezone.get(:utc)})
  end

  test "normalize" do
    tz = Timezone.get(:utc)
    date = { {1,13,44}, {-8,60,61}, tz }
    assert %DateTime{year: 1, month: 12, day: 31, hour: 0, minute: 59, second: 59, timezone: _} = Timex.normalize(date)
  end

  test "set" do
    import Timex.Convertable, only: [to_gregorian: 1]

    eet = Timezone.get("Europe/Athens", Timex.datetime({{2013,3,17}, {17,26,5}}))
    utc = Timezone.get(:utc)
    %TimezoneInfo{:abbreviation => eet_name} = eet
    %TimezoneInfo{:abbreviation => utc_name} = utc

    tuple = {{2013,3,17}, {17,26,5}}
    date = Timex.datetime(tuple, "Europe/Athens")
    assert to_gregorian(Timex.set(date, date: {1,1,1}))        === { {1,1,1}, {17,26,5}, {-2, eet_name} }
    assert to_gregorian(Timex.set(date, hour: 0))              === { {2013,3,17}, {0,26,5}, {-2, eet_name} }
    assert to_gregorian(Timex.set(date, timezone: Timex.timezone(:utc, tuple))) === { {2013,3,17}, {17,26,5}, {0, utc_name} }

    assert to_gregorian(Timex.set(date, [date: {1,1,1}, hour: 13, second: 61, timezone: utc]))    === { {1,1,1}, {13,26,59}, {0, utc_name} }
    assert to_gregorian(Timex.set(date, [date: {-1,-2,-3}, hour: 33, second: 61, timezone: utc])) === { {0,1,1}, {23,26,59}, {0, utc_name} }
  end

  test "compare" do
    assert Timex.compare(DateTime.epoch(), DateTime.zero()) === 1
    assert Timex.compare(DateTime.zero(), DateTime.epoch()) === -1

    tz1   = Timezone.get(2)
    tz2   = Timezone.get(-3)
    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz1}
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: tz2}
    assert Timex.compare(date1, date2) === 0

    tz3   = Timezone.get(3)
    date3 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz3}
    assert Timex.compare(date1, date3) === 1

    date = DateTime.now()
    assert Timex.compare(DateTime.epoch(), date) === -1

    assert Timex.compare(date, :distant_past) === +1
    assert Timex.compare(date, :distant_future) === -1

    date = Date.today
    assert Timex.compare(date, :epoch) === 1
    assert Timex.compare(date, :zero) === 1
    assert Timex.compare(date, :distant_past) === 1
    assert Timex.compare(date, :distant_future) === -1
  end

  test "compare with granularity" do
    tz1   = Timezone.get(2)
    tz2   = Timezone.get(-3)
    date1 = %DateTime{year: 2013, month: 3, day: 18, hour: 13, minute: 44, timezone: tz1}
    date2 = %DateTime{year: 2013, month: 3, day: 18, hour: 8, minute: 44, timezone: tz2}
    date3 = %DateTime{year: 2013, month: 4, day: 18, hour: 8, minute: 44, second: 10, timezone: tz2}
    date4 = %DateTime{year: 2013, month: 4, day: 18, hour: 8, minute: 44, second: 23, timezone: tz2}

    assert Timex.compare(date1, date2, :years) === 0
    assert Timex.compare(date1, date2, :months) === 0
    assert Timex.compare(date1, date3, :months) === -1
    assert Timex.compare(date3, date1, :months) === 1
    assert Timex.compare(date1, date3, :weeks) === -1
    assert Timex.compare(date1, date2, :days) === 0
    assert Timex.compare(date1, date3, :days) === -1
    assert Timex.compare(date1, date2, :hours) === 0
    assert Timex.compare(date3, date4, :minutes) === 0
    assert Timex.compare(date3, date4, :seconds) === -1
  end

  test "equal" do
    assert Timex.equal?(Date.today, Date.today)
    refute Timex.equal?(Date.today, Date.epoch)
    assert Timex.equal?(DateTime.today, DateTime.today)
    refute Timex.equal?(DateTime.now, DateTime.epoch)
  end

  test "diff" do
    epoch = DateTime.epoch()
    date1 = Timex.datetime({1971,1,1})
    date2 = Timex.datetime({1973,1,1})

    assert Timex.diff(date1, date2, :seconds)   === Timex.diff(date2, date1, :seconds)
    assert Timex.diff(date1, date2, :minutes)   === Timex.diff(date2, date1, :minutes)
    assert Timex.diff(date1, date2, :hours)  === Timex.diff(date2, date1, :hours)
    assert Timex.diff(date1, date2, :days)   === Timex.diff(date2, date1, :days)
    assert Timex.diff(date1, date2, :weeks)  === Timex.diff(date2, date1, :weeks)
    assert Timex.diff(date1, date2, :months) === Timex.diff(date2, date1, :months)
    assert Timex.diff(date1, date2, :years)  === Timex.diff(date2, date1, :years)

    d1 = Timex.date({1971,1,1})
    d2 = Timex.date({1973,1,1})
    assert Timex.diff(d1, d2, :hours)  === Timex.diff(d2, d1, :hours)
    assert Timex.diff(d1, d2, :days)  === Timex.diff(d2, d1, :days)
    assert Timex.diff(d1, d2, :weeks)  === Timex.diff(d2, d1, :weeks)
    assert Timex.diff(d1, d2, :months)  === Timex.diff(d2, d1, :months)
    assert Timex.diff(d1, d2, :years)  === Timex.diff(d2, d1, :years)

    date3 = Timex.datetime({2015,1,1})
    date4 = Timex.datetime({2015,12,31})
    assert 52 = Timex.diff(date3, date4, :weeks)
    assert 53 = Timex.diff(date3, date4, :calendar_weeks)
    assert 52 = Timex.diff(date4, date3, :weeks)
    assert 53 = Timex.diff(date4, date3, :calendar_weeks)

    date5 = Timex.datetime({2015,12,31})
    date6 = Timex.datetime({2016,1,1})
    assert 1 = Timex.diff(date5, date6, :days)
    assert 0 = Timex.diff(date5, date6, :weeks)
    assert 0 = Timex.diff(date5, date6, :calendar_weeks)
    assert 0 = Timex.diff(date5, date6, :years)

    assert Timex.diff(date1, date2, :timestamp) === {63, 158400, 0}
    assert Timex.diff(Timex.date({1971,1,1}), Timex.date({1973,1,1}), :timestamp) === {63, 158400, 0}

    assert Timex.diff(epoch, date1, :days) === 365
    assert Timex.diff(epoch, date1, :seconds) === 365 * 24 * 3600
    assert Timex.diff(epoch, date1, :years) === 1

    # additional day is added because 1972 was a leap year
    assert Timex.diff(epoch, date2, :days) === 365*3 + 1
    assert Timex.diff(epoch, date2, :seconds) === (365*3 + 1) * 24 * 3600
    assert Timex.diff(epoch, date2, :years) === 3

    assert Timex.diff(epoch, date1, :months) === 12
    assert Timex.diff(epoch, date2, :months) === 36
    assert Timex.diff(date1, date2, :months) === 24

    date1 = Timex.datetime({1971,3,31})
    date2 = Timex.datetime({1969,2,11})
    assert Timex.diff(date1, date2, :months) === 25
    assert Timex.diff(date2, date1, :months) === 25

    date7 = Timex.date({2016, 3, 27})
    date8 = Timex.date({2016, 4, 3})
    assert Timex.diff(date7, date8, :days) == 7
    assert Timex.diff(date8, date7, :days) == 7
    assert Timex.diff(date7, date8, :weeks) == 1
    assert Timex.diff(date8, date7, :weeks) == 1
  end

  test "timestamp diff same datetime" do
      dt = Timex.datetime({1984, 5, 10})
      assert Timex.diff(dt, dt, :timestamp) === Time.zero
  end

  test "beginning_of_year" do
    year_start = Timex.datetime({{2015, 1, 1},  {0, 0, 0}})
    assert Timex.beginning_of_year(2015) == Timex.to_date(year_start)
    assert Timex.beginning_of_year(%DateTime{year: 2015, month: 6, day: 15}) == year_start
    assert Timex.beginning_of_year(Timex.datetime({2015, 6, 15})) == year_start
  end

  test "end_of_year" do
    year_end = Timex.datetime({{2015, 12, 31},  {23, 59, 59}})
    assert Timex.end_of_year(2015) == Timex.to_date(year_end)
    assert Timex.end_of_year(%DateTime{year: 2015, month: 6, day: 15}) == year_end
    assert Timex.end_of_year(Timex.datetime({2015, 6, 15})) == year_end
  end

  test "beginning_of_month" do
    assert Timex.beginning_of_month(%DateTime{year: 2016, month: 2, day: 15}) == Timex.datetime({{2016, 2, 1},  {0, 0, 0}})
    assert Timex.beginning_of_month(Timex.datetime({{2014,2,15},{14,14,14}})) == Timex.datetime({{2014, 2, 1},  {0, 0, 0}})
  end

  test "end_of_month" do
    assert Timex.end_of_month(%DateTime{year: 2016, month: 2, day: 15}) == Timex.datetime({{2016, 2, 29},  {23, 59, 59}})
    refute Timex.end_of_month(%DateTime{year: 2016, month: 2, day: 15}) == Timex.datetime({{2016, 2, 28},  {23, 59, 59}})
    assert Timex.end_of_month(Timex.datetime({{2014,2,15},{14,14,14}})) == Timex.datetime({{2014, 2, 28},  {23, 59, 59}})
    assert Timex.end_of_month(2015, 11) == Timex.date({{2015, 11, 30},  {23, 59, 59}})

    assert {:error, _} = Timex.end_of_month 2015, 13
    assert {:error, _} = Timex.end_of_month -2015, 12
  end

  test "beginning_of_quarter" do
    assert Timex.beginning_of_quarter(%DateTime{year: 2016, month: 3, day: 15}) == Timex.datetime({{2016, 1, 1},  {0, 0, 0}})
    assert Timex.beginning_of_quarter(Timex.datetime({{2014,2,15},{14,14,14}})) == Timex.datetime({{2014, 1, 1},  {0, 0, 0}})
    assert Timex.beginning_of_quarter(%DateTime{year: 2016, month: 5, day: 15}) == Timex.datetime({{2016, 4, 1},  {0, 0, 0}})
    assert Timex.beginning_of_quarter(%DateTime{year: 2016, month: 8, day: 15}) == Timex.datetime({{2016, 7, 1},  {0, 0, 0}})
    assert Timex.beginning_of_quarter(%DateTime{year: 2016, month: 11, day: 15}) == Timex.datetime({{2016, 10, 1},  {0, 0, 0}})
  end

  test "end_of_quarter" do
    assert Timex.end_of_quarter(%DateTime{year: 2016, month: 2, day: 15}) == Timex.datetime({{2016, 3, 31},  {23, 59, 59}})
    assert Timex.end_of_quarter(Timex.datetime({{2014,2,15},{14,14,14}})) == Timex.datetime({{2014, 3, 31},  {23, 59, 59}})
    assert Timex.end_of_quarter(2015, 1) == Timex.date({2015, 3, 31})

    assert {:error, _} = Timex.end_of_quarter(2015, 13)
  end

  test "beginning_of_week" do
    # Monday 30th November 2015
    date = Timex.datetime({{2015, 11, 30}, {13, 30, 30}})

    # Monday..Monday
    monday = Timex.datetime({2015, 11, 30})
    assert Timex.days_to_beginning_of_week(date) == 0
    assert Timex.days_to_beginning_of_week(date, 1) == 0
    assert Timex.days_to_beginning_of_week(date, :mon) == 0
    assert Timex.days_to_beginning_of_week(date, "Monday") == 0
    assert Timex.beginning_of_week(date) == monday
    assert Timex.beginning_of_week(date, 1) == monday
    assert Timex.beginning_of_week(date, :mon) == monday
    assert Timex.beginning_of_week(date, "Monday") == monday

    # Monday..Tuesday
    tuesday = Timex.datetime({2015, 11, 24})
    assert Timex.days_to_beginning_of_week(date, 2) == 6
    assert Timex.days_to_beginning_of_week(date, :tue) == 6
    assert Timex.days_to_beginning_of_week(date, "Tuesday") == 6
    assert Timex.beginning_of_week(date, 2) == tuesday
    assert Timex.beginning_of_week(date, :tue) == tuesday
    assert Timex.beginning_of_week(date, "Tuesday") == tuesday

    # Monday..Wednesday
    wednesday = Timex.datetime({2015, 11, 25})
    assert Timex.days_to_beginning_of_week(date, 3) == 5
    assert Timex.days_to_beginning_of_week(date, :wed) == 5
    assert Timex.days_to_beginning_of_week(date, "Wednesday") == 5
    assert Timex.beginning_of_week(date, 3) == wednesday
    assert Timex.beginning_of_week(date, :wed) == wednesday
    assert Timex.beginning_of_week(date, "Wednesday") == wednesday

    # Monday..Thursday
    thursday = Timex.datetime({2015, 11, 26})
    assert Timex.days_to_beginning_of_week(date, 4) == 4
    assert Timex.days_to_beginning_of_week(date, :thu) == 4
    assert Timex.days_to_beginning_of_week(date, "Thursday") == 4
    assert Timex.beginning_of_week(date, 4) == thursday
    assert Timex.beginning_of_week(date, :thu) == thursday
    assert Timex.beginning_of_week(date, "Thursday") == thursday

    # Monday..Friday
    friday = Timex.datetime({2015, 11, 27})
    assert Timex.days_to_beginning_of_week(date, 5) == 3
    assert Timex.days_to_beginning_of_week(date, :fri) == 3
    assert Timex.days_to_beginning_of_week(date, "Friday") == 3
    assert Timex.beginning_of_week(date, 5) == friday
    assert Timex.beginning_of_week(date, :fri) == friday
    assert Timex.beginning_of_week(date, "Friday") == friday

    # Monday..Saturday
    saturday = Timex.datetime({2015, 11, 28})
    assert Timex.days_to_beginning_of_week(date, 6) == 2
    assert Timex.days_to_beginning_of_week(date, :sat) == 2
    assert Timex.days_to_beginning_of_week(date, "Saturday") == 2
    assert Timex.beginning_of_week(date, 6) == saturday
    assert Timex.beginning_of_week(date, :sat) == saturday
    assert Timex.beginning_of_week(date, "Saturday") == saturday

    # Monday..Sunday
    sunday = Timex.datetime({2015, 11, 29})
    assert Timex.days_to_beginning_of_week(date, 7) == 1
    assert Timex.days_to_beginning_of_week(date, :sun) == 1
    assert Timex.days_to_beginning_of_week(date, "Sunday") == 1
    assert Timex.beginning_of_week(date, 7) == sunday
    assert Timex.beginning_of_week(date, :sun) == sunday
    assert Timex.beginning_of_week(date, "Sunday") == sunday

    # Invalid start of week - out of range
    assert {:error, _} = Timex.days_to_beginning_of_week(date, 0)
    assert {:error, _} = Timex.beginning_of_week(date, 0)

    # Invalid start of week - out of range
    assert {:error, _} = Timex.days_to_beginning_of_week(date, 8)
    assert {:error, _} = Timex.beginning_of_week(date, 8)

    # Invalid start of week string
    assert {:error, _} = Timex.days_to_beginning_of_week(date, "Made up day")
    assert {:error, _} = Timex.beginning_of_week(date, "Made up day")
  end

  test "end_of_week" do
    # Monday 30th November 2015
    date = Timex.datetime({2015, 11, 30})

    # Monday..Sunday
    sunday = Timex.datetime({{2015, 12, 6}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date) == 6
    assert Timex.days_to_end_of_week(date, 1) == 6
    assert Timex.days_to_end_of_week(date, :mon) == 6
    assert Timex.days_to_end_of_week(date, "Monday") == 6
    assert Timex.end_of_week(date) == sunday
    assert Timex.end_of_week(date, 1) == sunday
    assert Timex.end_of_week(date, :mon) == sunday
    assert Timex.end_of_week(date, "Monday") == sunday

    # Monday..Monday
    monday = Timex.datetime({{2015, 11, 30}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 2) == 0
    assert Timex.days_to_end_of_week(date, :tue) == 0
    assert Timex.days_to_end_of_week(date, "Tuesday") == 0
    assert Timex.end_of_week(date, 2) == monday
    assert Timex.end_of_week(date, :tue) == monday
    assert Timex.end_of_week(date, "Tuesday") == monday

    # Monday..Tuesday
    tuesday = Timex.datetime({{2015, 12, 1}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 3) == 1
    assert Timex.days_to_end_of_week(date, :wed) == 1
    assert Timex.days_to_end_of_week(date, "Wednesday") == 1
    assert Timex.end_of_week(date, 3) == tuesday
    assert Timex.end_of_week(date, :wed) == tuesday
    assert Timex.end_of_week(date, "Wednesday") == tuesday

    # Monday..Wednesday
    wednesday = Timex.datetime({{2015, 12, 2}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 4) == 2
    assert Timex.days_to_end_of_week(date, :thu) == 2
    assert Timex.days_to_end_of_week(date, "Thursday") == 2
    assert Timex.end_of_week(date, 4) == wednesday
    assert Timex.end_of_week(date, :thu) == wednesday
    assert Timex.end_of_week(date, "Thursday") == wednesday

    # Monday..Thursday
    thursday = Timex.datetime({{2015, 12, 3}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 5) == 3
    assert Timex.days_to_end_of_week(date, :fri) == 3
    assert Timex.days_to_end_of_week(date, "Friday") == 3
    assert Timex.end_of_week(date, 5) == thursday
    assert Timex.end_of_week(date, :fri) == thursday
    assert Timex.end_of_week(date, "Friday") == thursday

    # Monday..Friday
    friday = Timex.datetime({{2015, 12, 4}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 6) == 4
    assert Timex.days_to_end_of_week(date, :sat) == 4
    assert Timex.days_to_end_of_week(date, "Saturday") == 4
    assert Timex.end_of_week(date, 6) == friday
    assert Timex.end_of_week(date, :sat) == friday
    assert Timex.end_of_week(date, "Saturday") == friday

    # Monday..Saturday
    saturday = Timex.datetime({{2015, 12, 5}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 7) == 5
    assert Timex.days_to_end_of_week(date, :sun) == 5
    assert Timex.days_to_end_of_week(date, "Sunday") == 5
    assert Timex.end_of_week(date, 7) == saturday
    assert Timex.end_of_week(date, :sun) == saturday
    assert Timex.end_of_week(date, "Sunday") == saturday

    # Invalid start of week - out of range
    assert {:error, _} = Timex.days_to_end_of_week(date, 0)
    assert {:error, _} = Timex.end_of_week(date, 0)

    # Invalid start of week - out of range
    assert {:error, _} = Timex.days_to_end_of_week(date, 8)
    assert {:error, _} = Timex.end_of_week(date, 8)

    # Invalid start of week string
    assert {:error, _} = Timex.days_to_end_of_week(date, "Made up day")
    assert {:error, _} = Timex.end_of_week(date, "Made up day")
  end

  test "beginning_of_day" do
    date = Timex.datetime({{2015, 1, 1}, {13, 14, 15}})
    assert Timex.beginning_of_day(date) == Timex.datetime({{2015, 1, 1}, {0, 0, 0}})
  end

  test "end_of_day" do
    date = Timex.datetime({{2015, 1, 1}, {13, 14, 15}})
    assert Timex.end_of_day(date) == Timex.datetime({{2015, 1, 1}, {23, 59, 59}})
  end

end
