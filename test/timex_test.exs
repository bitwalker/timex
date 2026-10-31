defmodule TimexTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex

  test "century" do
    assert 21 === Timex.century()

    date = Timex.to_datetime({{2015, 6, 24}, {14, 27, 52}})
    c = date |> Timex.century()
    assert 21 === c
  end

  test "add" do
    date = Timex.to_datetime({{2015, 6, 24}, {14, 27, 52}})
    expected = Timex.to_datetime({{2015, 7, 2}, {14, 27, 52}})
    result = Timex.add(date, Duration.from_days(8))
    assert expected === result
  end

  test "add microseconds" do
    time = Timex.to_datetime({{2015, 6, 24}, {14, 27, 52}})
    time = %{time | microsecond: {900_000, 6}}
    added = Timex.add(time, Duration.from_microseconds(42))
    assert added.microsecond === {900_042, 6}
  end

  test "subtract" do
    date = Timex.to_datetime({{2015, 6, 24}, {14, 27, 52}})
    expected = Timex.to_datetime({{2015, 6, 16}, {14, 27, 52}})
    result = Timex.subtract(date, Duration.from_days(8))
    assert expected === result
  end

  test "subtract milliseconds" do
    time = Timex.to_datetime({{2015, 6, 24}, {14, 27, 52}})
    time = %{time | microsecond: {910_000, 2}}
    subtracted = Timex.subtract(time, Duration.from_milliseconds(10))
    assert subtracted.microsecond === {900_000, 2}
  end

  test "weekday" do
    localdate = {{2013, 3, 17}, {11, 59, 10}}
    assert Timex.weekday(Timex.to_datetime(localdate)) === 7
    assert Timex.weekday(Timex.epoch()) === 4
    assert {:error, :invalid_date} = Timex.weekday("Made up date")
    assert {:error, :invalid_date} = Timex.weekday(nil)
  end

  test "day" do
    assert Timex.day(Timex.to_datetime({3, 1, 1})) === 1
    assert Timex.day(Timex.to_datetime({3, 2, 1})) === 32
    assert Timex.day(Timex.to_datetime({3, 12, 31})) === 365
    assert Timex.day(Timex.to_datetime({2012, 12, 31})) === 366
    assert {:error, :invalid_date} = Timex.day("Made up day")
    assert {:error, :invalid_date} = Timex.day(nil)
  end

  test "week" do
    localdate = {{2013, 3, 17}, {11, 59, 10}}
    assert Timex.iso_week(localdate) === {2013, 11}
    assert Timex.iso_week(Timex.to_datetime(localdate)) === {2013, 11}
    assert Timex.iso_week(Timex.epoch()) === {1970, 1}
    assert {:error, :invalid_date} = Timex.iso_week("Made up date")
    assert {:error, :invalid_date} = Timex.iso_week(nil)
  end

  test "iso_triplet" do
    localdate = {{2013, 3, 17}, {11, 59, 10}}
    assert Timex.iso_triplet(Timex.to_datetime(localdate)) === {2013, 11, 7}
    assert Timex.iso_triplet(Timex.epoch()) === {1970, 1, 4}
  end

  test "from_iso_day" do
    localdate = {{2016, 3, 17}, {11, 59, 10}}
    expected = {{2016, 2, 29}, {11, 59, 10}}
    assert Timex.from_iso_day(60, localdate) === expected
    assert Timex.from_iso_day(60, Timex.to_datetime(localdate)) === Timex.to_datetime(expected)
    assert Timex.from_iso_day(60, Timex.to_date(localdate)) === Timex.to_date(expected)

    assert Timex.from_iso_day(60, Timex.to_naive_datetime(localdate)) ===
             Timex.to_naive_datetime(expected)
  end

  describe "from_iso_triplet" do
    test "first day of first iso week is first day of the year" do
      assert Timex.from_iso_triplet({2001, 1, 1}) === Timex.to_date({2001, 1, 1})
    end

    test "first iso week includes the maximum number of days from the previous year" do
      assert Timex.from_iso_triplet({2004, 1, 1}) === Timex.to_date({2003, 12, 29})
    end

    test "last iso week includes the maximum number of days in the next year" do
      assert Timex.from_iso_triplet({2026, 53, 7}) === Timex.to_date({2027, 1, 3})
    end

    test "last iso week of leap year includes the maximum number of days in the next year" do
      assert Timex.from_iso_triplet({2020, 53, 7}) === Timex.to_date({2021, 1, 3})
    end

    test "iso week that includes a leap day" do
      assert Timex.from_iso_triplet({2000, 9, 2}) === Timex.to_date({2000, 2, 29})
    end

    test "first iso week starts on the last day of the year" do
      assert Timex.from_iso_triplet({2013, 1, 1}) === Timex.to_date({2012, 12, 31})
    end

    test "last day of last iso week ends on last day of the year" do
      assert Timex.from_iso_triplet({2028, 52, 7}) == Timex.to_date({2028, 12, 31})
    end
  end

  describe "from_unix" do
    test "defaults to unit :second" do
      assert Timex.from_unix(1_549_021_655) == Timex.to_datetime({{2019, 2, 1}, {11, 47, 35}})
    end

    test "has seconds as unit" do
      assert Timex.from_unix(1_549_021_655, :seconds) ==
               Timex.to_datetime({{2019, 2, 1}, {11, 47, 35}})
    end

    test "has milliseconds as unit" do
      assert Timex.from_unix(1_549_021_655_901, :milliseconds) ==
               Timex.to_datetime({{2019, 2, 1}, {11, 47, 35, 901_000}})
    end

    test "has microseconds as unit" do
      assert Timex.from_unix(1_549_021_655_900_123, :microseconds) ==
               Timex.to_datetime({{2019, 2, 1}, {11, 47, 35, 900_123}})
    end

    test "has nanoseconds as unit" do
      assert Timex.from_unix(1_549_021_655_900_123_456, :nanoseconds) ==
               Timex.to_datetime({{2019, 2, 1}, {11, 47, 35, 900_123}})
    end

    test "has System.convert_time_unit/3 units" do
      assert Timex.from_unix(1_549_021_655_900_123, :microsecond) ==
               Timex.to_datetime({{2019, 2, 1}, {11, 47, 35, 900_123}})
    end
  end

  test "days_in_month" do
    localdate = {{2013, 2, 17}, {11, 59, 10}}
    assert Timex.days_in_month(Timex.to_datetime(localdate)) === 28

    localdate = {{2000, 2, 17}, {11, 59, 10}}
    assert Timex.days_in_month(Timex.to_datetime(localdate)) === 29

    assert Timex.days_in_month(Timex.epoch()) === 31
    assert Timex.days_in_month(2012, 2) === 29
    assert Timex.days_in_month(2013, 2) === 28

    assert {:error, :invalid_date} = Timex.days_in_month("Made up date")
    assert {:error, :invalid_date} = Timex.days_in_month(nil)
  end

  test "week_of_month" do
    assert Timex.week_of_month(~D[2019-01-01]) == 1

    assert Timex.week_of_month(~D[2021-01-01]) == 1
    assert Timex.week_of_month(~D[2021-01-04]) == 2
    assert Timex.week_of_month(~D[2021-01-11]) == 3

    assert Timex.week_of_month(~D[2021-02-08]) == 2

    assert Timex.week_of_month(~D[2019-12-01]) == 1
    assert Timex.week_of_month(~D[2019-12-31]) == 6

    assert Timex.week_of_month(~N[2021-01-01T00:00:00Z]) == 1

    assert Timex.week_of_month(2019, 12, 31) == 6
    assert Timex.week_of_month(2021, 1, 11) == 3

    assert {:error, :invalid_date} = Timex.week_of_month(2020, 40, 40)
    assert {:error, :invalid_date} = Timex.week_of_month(2020, nil, 10)
    assert {:error, :invalid_date} = Timex.week_of_month(nil)
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
    refute Timex.is_leap?(Timex.epoch())
    assert Timex.is_leap?(2012)
    refute Timex.is_leap?(2100)

    assert {:error, :invalid_date} = Timex.is_leap?("Made up year")
    assert {:error, :invalid_date} = Timex.is_leap?(nil)
  end

  test "is_valid?" do
    assert Timex.is_valid?(Timex.now())
    assert Timex.is_valid?({1, 1, 1})
    assert Timex.is_valid?(Timex.to_date({1, 1, 1}))
    assert Timex.is_valid?(Timex.to_naive_datetime({{1, 1, 1}, {0, 0, 0}}))
    assert Timex.is_valid?(Timex.to_naive_datetime({{1, 1, 1}, {23, 59, 59}}))
    assert Timex.is_valid?(Timex.to_datetime({{1, 1, 1}, {1, 1, 1}}, "Etc/UTC"))

    new_date = %DateTime{
      year: 0,
      month: 0,
      day: 0,
      hour: 0,
      minute: 0,
      second: 0,
      microsecond: {0, 0},
      time_zone: "Etc/UTC",
      zone_abbr: "UTC",
      utc_offset: 0,
      std_offset: 0
    }

    refute Timex.is_valid?(Timex.set(new_date, date: {12, 13, 14}, validate: false))
    refute Timex.is_valid?(Timex.set(new_date, date: {12, 12, 34}, validate: false))
    refute Timex.is_valid?(Timex.set(new_date, date: {1, 0, 1}, validate: false))
    refute Timex.is_valid?(Timex.set(new_date, date: {1, 1, 0}, validate: false))

    refute Timex.is_valid?(
             Timex.set(new_date, datetime: {{12, 12, 12}, {24, 0, 0}}, validate: false)
           )

    refute Timex.is_valid?(
             Timex.set(new_date, datetime: {{12, 12, 12}, {23, 60, 0}}, validate: false)
           )

    refute Timex.is_valid?(
             Timex.set(new_date, datetime: {{12, 12, 12}, {23, 59, 60}}, validate: false)
           )

    refute Timex.is_valid?(
             Timex.set(new_date, datetime: {{12, 12, 12}, {-1, 59, 59}}, validate: false)
           )

    refute Timex.is_valid?("Made up date")
    refute Timex.is_valid?(nil)
  end

  test "set" do
    utc = Timezone.get(:utc)

    tuple = {{2013, 3, 17}, {17, 26, 5}}
    date = Timex.to_datetime(tuple, "Europe/Athens")
    assert {{1, 1, 1}, {17, 26, 5}} == Timex.to_erl(Timex.set(date, date: {1, 1, 1}))
    assert {{2013, 3, 17}, {0, 26, 5}} == Timex.to_erl(Timex.set(date, hour: 0))

    assert {{2013, 3, 17}, {17, 26, 5}} ==
             Timex.to_erl(Timex.set(date, timezone: Timex.timezone(:utc, tuple)))

    assert {{1, 1, 1}, {13, 26, 59}} ==
             Timex.to_erl(Timex.set(date, date: {1, 1, 1}, hour: 13, second: 61, timezone: utc))

    assert {{0, 1, 1}, {23, 26, 59}} ==
             Timex.to_erl(
               Timex.set(date, date: {-1, -2, -3}, hour: 33, second: 61, timezone: utc)
             )

    assert {{0, 1, 1}, {23, 26, 59}} ==
             Timex.to_erl(
               Timex.set(Timex.to_erl(date),
                 date: {-1, -2, -3},
                 hour: 33,
                 second: 61,
                 timezone: utc
               )
             )
  end

  test "compare" do
    assert Timex.compare(Timex.epoch(), Timex.zero()) === 1
    assert Timex.compare(Timex.zero(), Timex.epoch()) === -1

    date1 = Timex.to_datetime({{2013, 3, 18}, {13, 44, 0}}, 2)
    date2 = Timex.to_datetime({{2013, 3, 18}, {8, 44, 0}}, -3)
    assert Timex.compare(date1, date2) === 0

    date3 = Timex.to_datetime({{2013, 3, 18}, {13, 44, 0}}, 3)
    assert Timex.compare(date1, date3) === 1

    date = Timex.now()
    assert Timex.compare(Timex.epoch(), date) === -1

    assert Timex.compare(date, :distant_past) === +1
    assert Timex.compare(date, :distant_future) === -1

    date = Timex.today()
    assert Timex.compare(date, :epoch) === 1
    assert Timex.compare(date, :zero) === 1
    assert Timex.compare(date, :distant_past) === 1
    assert Timex.compare(date, :distant_future) === -1

    assert Timex.compare(~T[09:00:00], ~T[12:00:00]) === -1
    assert Timex.compare(~T[09:00:00], ~T[09:00:00]) === 0
    assert Timex.compare(~T[09:00:00], ~T[07:00:00]) === 1
  end

  test "compare with granularity" do
    date1 = Timex.to_datetime({{2013, 3, 18}, {13, 44, 0}}, 2)
    date2 = Timex.to_datetime({{2013, 3, 18}, {8, 44, 0}}, -3)
    date3 = Timex.to_datetime({{2013, 4, 18}, {8, 44, 10}}, -3)
    date4 = Timex.to_datetime({{2013, 4, 18}, {8, 44, 23}}, -3)

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

    assert Timex.compare(~T[09:00:00], ~T[09:00:00.56423], :hours) === 0
    assert Timex.compare(~T[09:00:00], ~T[09:00:00.56423], :milliseconds) === -1
  end

  test "before?/after?" do
    now = Timex.now()
    assert false == Timex.before?(now, now)
    assert false == Timex.after?(now, now)
    assert true == Timex.before?(Timex.epoch(), now)
    assert false == Timex.after?(Timex.epoch(), now)

    assert true == Timex.before?({{2013, 1, 1}, {1, 1, 1}}, {{2013, 1, 1}, {1, 1, 2}})
    assert true == Timex.after?({{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 1}})

    assert_raise ArgumentError, fn ->
      Timex.before?({}, {{2013, 1, 1}, {1, 1, 2}})
    end

    assert_raise ArgumentError, fn ->
      Timex.after?({{2013, 1, 1}, {1, 1, 2}}, {})
    end

    assert Timex.before?(~T[09:00:00], ~T[12:00:00])
    refute Timex.before?(~T[09:00:00], ~T[09:00:00])
    assert Timex.after?(~T[09:00:00], ~T[07:00:00])
    refute Timex.after?(~T[09:00:00], ~T[12:00:00])
  end

  describe "between?" do
    test "w/o options" do
      date1 = Timex.to_datetime({{2013, 1, 1}, {0, 0, 0}})
      date2 = Timex.to_datetime({{2013, 1, 5}, {0, 0, 0}})
      date3 = Timex.to_datetime({{2013, 1, 9}, {0, 0, 0}})

      assert true == Timex.between?(date2, date1, date3)

      assert false == Timex.between?(date1, date2, date3)
      assert false == Timex.between?(date3, date1, date2)
      assert false == Timex.between?(date1, date1, date3)
      assert false == Timex.between?(date3, date1, date3)

      assert_raise ArgumentError, fn ->
        Timex.between?({}, {{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}})
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {}, {{2013, 1, 1}, {1, 1, 2}})
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, {})
      end

      assert Timex.between?(~T[12:00:00], ~T[09:00:00], ~T[17:00:00])
      refute Timex.between?(~T[07:00:00], ~T[09:00:00], ~T[17:00:00])
    end

    test "inclusive: true" do
      date1 = Timex.to_datetime({{2013, 1, 1}, {0, 0, 0}})
      date2 = Timex.to_datetime({{2013, 1, 5}, {0, 0, 0}})
      date3 = Timex.to_datetime({{2013, 1, 9}, {0, 0, 0}})

      options = [inclusive: true]

      assert true == Timex.between?(date2, date1, date3, options)
      assert true == Timex.between?(date1, date1, date3, options)
      assert true == Timex.between?(date3, date1, date3, options)

      assert false == Timex.between?(date1, date2, date3, options)
      assert false == Timex.between?(date3, date1, date2, options)

      assert_raise ArgumentError, fn ->
        Timex.between?({}, {{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, options)
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {}, {{2013, 1, 1}, {1, 1, 2}}, options)
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, {}, options)
      end
    end

    test "inclusive: :start" do
      date1 = Timex.to_datetime({{2013, 1, 1}, {0, 0, 0}})
      date2 = Timex.to_datetime({{2013, 1, 5}, {0, 0, 0}})
      date3 = Timex.to_datetime({{2013, 1, 9}, {0, 0, 0}})

      options = [inclusive: :start]

      assert true == Timex.between?(date2, date1, date3, options)
      assert true == Timex.between?(date1, date1, date3, options)
      assert false == Timex.between?(date3, date1, date3, options)

      assert false == Timex.between?(date1, date2, date3, options)
      assert false == Timex.between?(date3, date1, date2, options)

      assert_raise ArgumentError, fn ->
        Timex.between?({}, {{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, options)
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {}, {{2013, 1, 1}, {1, 1, 2}}, options)
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, {}, options)
      end
    end

    test "inclusive: :end" do
      date1 = Timex.to_datetime({{2013, 1, 1}, {0, 0, 0}})
      date2 = Timex.to_datetime({{2013, 1, 5}, {0, 0, 0}})
      date3 = Timex.to_datetime({{2013, 1, 9}, {0, 0, 0}})

      options = [inclusive: :end]

      assert true == Timex.between?(date2, date1, date3, options)
      assert false == Timex.between?(date1, date1, date3, options)
      assert true == Timex.between?(date3, date1, date3, options)

      assert false == Timex.between?(date1, date2, date3, options)
      assert false == Timex.between?(date3, date1, date2, options)

      assert_raise ArgumentError, fn ->
        Timex.between?({}, {{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, options)
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {}, {{2013, 1, 1}, {1, 1, 2}}, options)
      end

      assert_raise ArgumentError, fn ->
        Timex.between?({{2013, 1, 1}, {1, 1, 2}}, {{2013, 1, 1}, {1, 1, 2}}, {}, options)
      end
    end

    test "cycled: true" do
      date1 = Timex.to_datetime({{2013, 1, 1}, {0, 0, 0}})
      date2 = Timex.to_datetime({{2013, 1, 5}, {0, 0, 0}})
      date3 = Timex.to_datetime({{2013, 1, 9}, {0, 0, 0}})

      assert_raise ArgumentError, fn ->
        assert true == Timex.between?(date2, date1, date3, cycled: true)
      end

      assert Timex.between?(~T[01:00:00], ~T[00:00:00], ~T[02:00:00], cycled: true)
      refute Timex.between?(~T[01:00:00], ~T[23:00:00], ~T[02:00:00], cycled: false)
      assert Timex.between?(~T[01:00:00], ~T[23:00:00], ~T[02:00:00], cycled: true)

      assert Timex.between?(~T[00:00:00], ~T[23:00:00], ~T[00:00:00],
               cycled: true,
               inclusive: :end
             )

      assert Timex.between?(~T[23:00:00], ~T[23:00:00], ~T[00:00:00],
               cycled: true,
               inclusive: :start
             )
    end
  end

  test "equal" do
    assert Timex.equal?(Timex.today(), Timex.today())
    refute Timex.equal?(Timex.today(), Timex.epoch())
    assert Timex.equal?(Timex.today(), Timex.today())
    refute Timex.equal?(Timex.now(), Timex.epoch())

    date1 = Timex.to_datetime({{2013, 3, 18}, {13, 44, 0, 50000}}, 2)
    date2 = Timex.to_datetime({{2013, 3, 18}, {8, 44, 0}}, -3)
    date3 = Timex.to_datetime({{2013, 3, 18}, {7, 45, 0}}, -3)
    assert Timex.equal?(date1, date2)
    refute Timex.equal?(date1, date2, :microseconds)
    assert Timex.equal?(date2, date3, :hours)

    assert Timex.equal?(~T[12:00:00], ~T[12:00:00])
    assert Timex.equal?(~T[12:00:00], ~T[12:00:00.0123], :seconds)
    refute Timex.equal?(~T[12:00:00], ~T[12:00:00.0123], :milliseconds)
  end

  test "diff" do
    epoch = Timex.epoch()
    date1 = Timex.to_datetime({1971, 1, 1})
    date2 = Timex.to_datetime({1973, 1, 1})

    assert Timex.diff(date1, date2, :seconds) === Timex.diff(date2, date1, :seconds) * -1
    assert Timex.diff(date1, date2, :minutes) === Timex.diff(date2, date1, :minutes) * -1
    assert Timex.diff(date1, date2, :hours) === Timex.diff(date2, date1, :hours) * -1
    assert Timex.diff(date1, date2, :days) === Timex.diff(date2, date1, :days) * -1
    assert Timex.diff(date1, date2, :weeks) === Timex.diff(date2, date1, :weeks) * -1
    assert Timex.diff(date1, date2, :months) === Timex.diff(date2, date1, :months) * -1
    assert Timex.diff(date1, date2, :years) === Timex.diff(date2, date1, :years) * -1

    d1 = Timex.to_date({1971, 1, 1})
    d2 = Timex.to_date({1973, 1, 1})
    assert Timex.diff(d1, d2, :hours) === Timex.diff(d2, d1, :hours) * -1
    assert Timex.diff(d1, d2, :days) === Timex.diff(d2, d1, :days) * -1
    assert Timex.diff(d1, d2, :weeks) === Timex.diff(d2, d1, :weeks) * -1
    assert Timex.diff(d1, d2, :months) === Timex.diff(d2, d1, :months) * -1
    assert Timex.diff(d1, d2, :years) === Timex.diff(d2, d1, :years) * -1

    date3 = Timex.to_datetime({2015, 1, 1})
    date4 = Timex.to_datetime({2015, 12, 31})
    assert 52 = Timex.diff(date4, date3, :weeks)
    assert 53 = Timex.diff(date4, date3, :calendar_weeks)
    assert -52 = Timex.diff(date3, date4, :weeks)
    assert -53 = Timex.diff(date3, date4, :calendar_weeks)

    date5 = Timex.to_datetime({2015, 12, 31})
    date6 = Timex.to_datetime({2016, 1, 1})
    assert 1 = Timex.diff(date6, date5, :days)
    assert 0 = Timex.diff(date6, date5, :weeks)
    assert 1 = Timex.diff(date6, date5, :calendar_weeks)
    assert 0 = Timex.diff(date6, date5, :years)

    assert Timex.diff(date2, date1, :duration) === %Duration{
             megaseconds: 63,
             seconds: 158_400,
             microseconds: 0
           }

    assert Timex.diff(date1, epoch, :days) === 365
    assert Timex.diff(date1, epoch, :seconds) === 365 * 24 * 3600
    assert Timex.diff(date1, epoch, :years) === 1

    # additional day is added because 1972 was a leap year
    assert Timex.diff(date2, epoch, :days) === 365 * 3 + 1
    assert Timex.diff(date2, epoch, :seconds) === (365 * 3 + 1) * 24 * 3600
    assert Timex.diff(date2, epoch, :years) === 3

    assert Timex.diff(date1, epoch, :months) === 12
    assert Timex.diff(date2, epoch, :months) === 36
    assert Timex.diff(date2, date1, :months) === 24

    date1 = Timex.to_datetime({1971, 3, 31})
    date2 = Timex.to_datetime({1969, 2, 11})
    assert Timex.diff(date1, date2, :months) === 25
    assert Timex.diff(date2, date1, :months) === -25

    assert Timex.diff(~T[09:00:00], ~T[12:30:23]) == -((3 * 60 + 30) * 60 + 23) * 1_000 * 1_000

    assert Timex.diff(~D[2017-12-18], ~D[2017-10-19], :months) == 1
    assert Timex.diff(~D[2017-12-19], ~D[2017-10-19], :months) == 2
    assert Timex.diff(~D[2017-12-20], ~D[2017-10-19], :months) == 2

    assert Timex.diff(~D[2018-01-18], ~D[2017-10-19], :months) == 2
    assert Timex.diff(~D[2018-01-19], ~D[2017-10-19], :months) == 3
    assert Timex.diff(~D[2018-01-20], ~D[2017-10-19], :months) == 3

    assert Timex.diff(~D[2018-09-18], ~D[2017-10-19], :months) == 10
    assert Timex.diff(~D[2018-09-19], ~D[2017-10-19], :months) == 11
    assert Timex.diff(~D[2018-09-20], ~D[2017-10-19], :months) == 11

    assert Timex.diff(~D[2018-10-18], ~D[2017-10-19], :months) == 11
    assert Timex.diff(~D[2018-10-19], ~D[2017-10-19], :months) == 12
    assert Timex.diff(~D[2018-10-20], ~D[2017-10-19], :months) == 12

    assert Timex.diff(~D[2018-11-18], ~D[2017-10-19], :months) == 12
    assert Timex.diff(~D[2018-11-19], ~D[2017-10-19], :months) == 13
    assert Timex.diff(~D[2018-11-20], ~D[2017-10-19], :months) == 13

    assert {:error, {:invalid_granularity, :dayz}} === Timex.diff(date1, date1, :dayz)
    assert {:error, {:invalid_granularity, :dayz}} === Timex.diff(d1, d1, :dayz)

    assert {:error, {:invalid_granularity, :dayz}} ===
             Timex.diff(~T[12:00:00], ~T[12:00:00], :dayz)
  end

  test "month diff is asymmetrical for months of different lengths" do
    assert Timex.diff(~D[2017-02-28], ~D[2017-01-27], :months) === 1
    assert Timex.diff(~D[2017-02-28], ~D[2017-01-28], :months) === 1
    assert Timex.diff(~D[2017-02-28], ~D[2017-01-29], :months) === 0
    assert Timex.diff(~D[2017-02-28], ~D[2017-01-30], :months) === 0
    assert Timex.diff(~D[2017-02-28], ~D[2017-01-31], :months) === 0

    assert Timex.diff(~D[2017-01-27], ~D[2017-02-28], :months) === -1
    assert Timex.diff(~D[2017-01-28], ~D[2017-02-28], :months) === -1
    assert Timex.diff(~D[2017-01-29], ~D[2017-02-28], :months) === -1
    assert Timex.diff(~D[2017-01-30], ~D[2017-02-28], :months) === -1
    assert Timex.diff(~D[2017-01-31], ~D[2017-02-28], :months) === -1

    assert Timex.diff(~D[2017-01-27], ~D[2017-02-27], :months) === -1
    assert Timex.diff(~D[2017-01-28], ~D[2017-02-27], :months) === 0
    assert Timex.diff(~D[2017-01-29], ~D[2017-02-27], :months) === 0
    assert Timex.diff(~D[2017-01-30], ~D[2017-02-27], :months) === 0
    assert Timex.diff(~D[2017-01-31], ~D[2017-02-27], :months) === 0
  end

  test "month diff matches month shift for native dates" do
    date = ~D[2017-01-27]

    Enum.each(0..34, fn x ->
      date1 = Timex.shift(date, days: x)

      date2 = Timex.shift(date1, months: 1)
      assert Timex.diff(date1, date2, :months) === -1

      date2 = Timex.shift(date1, months: -1)
      assert Timex.diff(date1, date2, :months) === 1
    end)
  end

  test "month diff matches month shift for datetimes" do
    date = ~D[2017-01-27] |> Timex.to_datetime()

    Enum.each(0..34, fn x ->
      date1 = Timex.shift(date, days: x)

      date2 = Timex.shift(date1, months: 1)
      assert Timex.diff(date1, date2, :months) === -1

      date2 = Timex.shift(date1, months: -1)
      assert Timex.diff(date1, date2, :months) === 1
    end)
  end

  test "timestamp diff same datetime" do
    dt = Timex.to_datetime({1984, 5, 10})
    assert Timex.diff(dt, dt, :duration) === Duration.zero()
  end

  test "beginning_of_year" do
    year_start = Timex.to_datetime({{2015, 1, 1}, {0, 0, 0}})
    assert Timex.beginning_of_year(2015) == Timex.to_date(year_start)
    assert Timex.beginning_of_year({2015, 6, 15}) == {2015, 1, 1}

    assert {:error, :invalid_date} = Timex.beginning_of_year("Made up date")
    assert {:error, :invalid_date} = Timex.beginning_of_year(nil)
  end

  test "end_of_year" do
    year_end = Timex.to_datetime({{2015, 12, 31}, {23, 59, 59}})
    assert Timex.end_of_year(2015) == Timex.to_date(year_end)
    assert {2015, 12, 31} = Timex.end_of_year({2015, 6, 15})

    assert {:error, :invalid_date} = Timex.end_of_year("Made up date")
    assert {:error, :invalid_date} = Timex.end_of_year(nil)
  end

  test "beginning_of_month" do
    assert Timex.beginning_of_month({2016, 2, 15}) == {2016, 2, 1}

    assert Timex.beginning_of_month(Timex.to_datetime({{2014, 2, 15}, {14, 14, 14}})) ==
             Timex.to_datetime({{2014, 2, 1}, {0, 0, 0}})

    assert Timex.beginning_of_month(
             Timex.to_datetime({{2018, 11, 15}, {14, 14, 14}}, "America/New_York")
           ) == Timex.to_datetime({{2018, 11, 1}, {0, 0, 0}}, "America/New_York")

    assert {:error, :invalid_date} = Timex.beginning_of_month("Made up date")
    assert {:error, :invalid_date} = Timex.beginning_of_month(nil)
  end

  test "end_of_month" do
    assert Timex.end_of_month({2016, 2, 15}) == {2016, 2, 29}
    refute Timex.end_of_month(~D[2016-02-15]) == ~D[2016-02-28]
    assert Timex.end_of_month(~N[2014-02-15T14:14:14]) == ~N[2014-02-28T23:59:59]
    assert Timex.end_of_month(~N[2014-02-15T14:14:14.012]) == ~N[2014-02-28T23:59:59.999]
    assert Timex.end_of_month(2015, 11) == ~D[2015-11-30]

    assert {:error, _} = Timex.end_of_month(2015, 13)
    assert {:error, _} = Timex.end_of_month(-2015, 12)

    assert {:error, :invalid_date} = Timex.end_of_month("Made up date")
    assert {:error, :invalid_date} = Timex.end_of_month(nil)
  end

  test "beginning_of_quarter" do
    assert Timex.beginning_of_quarter({2016, 3, 15}) == {2016, 1, 1}

    assert Timex.beginning_of_quarter(~N[2014-02-15T14:14:14]) ==
             Timex.to_naive_datetime({{2014, 1, 1}, {0, 0, 0}})

    assert Timex.beginning_of_quarter({2016, 5, 15}) == {2016, 4, 1}
    assert Timex.beginning_of_quarter({2016, 8, 15}) == {2016, 7, 1}
    assert Timex.beginning_of_quarter({2016, 11, 15}) == {2016, 10, 1}

    assert {2016, 3, 15} |> Timex.to_date() |> Timex.beginning_of_quarter() ==
             Timex.to_date({2016, 1, 1})

    assert {:error, :invalid_date} = Timex.beginning_of_quarter("Made up date")
    assert {:error, :invalid_date} = Timex.beginning_of_quarter(nil)
  end

  test "end_of_quarter" do
    assert Timex.end_of_quarter({2016, 2, 15}) == {2016, 3, 31}
    expected = Timex.to_datetime({{2014, 3, 31}, {23, 59, 59}})
    assert Timex.end_of_quarter(Timex.to_datetime({{2014, 2, 15}, {14, 14, 14}})) == expected
    assert Timex.end_of_quarter(2015, 1) == Timex.to_date({2015, 3, 31})

    assert {:error, _} = Timex.end_of_quarter(2015, 13)

    assert {:error, :invalid_date} = Timex.end_of_quarter("Made up date")
    assert {:error, :invalid_date} = Timex.end_of_quarter(nil)
  end

  test "beginning_of_week" do
    # Monday 30th November 2015
    date = Timex.to_datetime({{2015, 11, 30}, {13, 30, 30}})

    # Monday..Monday
    monday = Timex.to_datetime({2015, 11, 30})
    assert Timex.days_to_beginning_of_week(date) == 0
    assert Timex.days_to_beginning_of_week(date, 1) == 0
    assert Timex.days_to_beginning_of_week(date, :mon) == 0
    assert Timex.days_to_beginning_of_week(date, "Monday") == 0
    assert Timex.beginning_of_week(date) == monday
    assert Timex.beginning_of_week(date, 1) == monday
    assert Timex.beginning_of_week(date, :mon) == monday
    assert Timex.beginning_of_week(date, "Monday") == monday

    # Monday..Tuesday
    tuesday = Timex.to_datetime({2015, 11, 24})
    assert Timex.days_to_beginning_of_week(date, 2) == 6
    assert Timex.days_to_beginning_of_week(date, :tue) == 6
    assert Timex.days_to_beginning_of_week(date, "Tuesday") == 6
    assert Timex.beginning_of_week(date, 2) == tuesday
    assert Timex.beginning_of_week(date, :tue) == tuesday
    assert Timex.beginning_of_week(date, "Tuesday") == tuesday

    # Monday..Wednesday
    wednesday = Timex.to_datetime({2015, 11, 25})
    assert Timex.days_to_beginning_of_week(date, 3) == 5
    assert Timex.days_to_beginning_of_week(date, :wed) == 5
    assert Timex.days_to_beginning_of_week(date, "Wednesday") == 5
    assert Timex.beginning_of_week(date, 3) == wednesday
    assert Timex.beginning_of_week(date, :wed) == wednesday
    assert Timex.beginning_of_week(date, "Wednesday") == wednesday

    # Monday..Thursday
    thursday = Timex.to_datetime({2015, 11, 26})
    assert Timex.days_to_beginning_of_week(date, 4) == 4
    assert Timex.days_to_beginning_of_week(date, :thu) == 4
    assert Timex.days_to_beginning_of_week(date, "Thursday") == 4
    assert Timex.beginning_of_week(date, 4) == thursday
    assert Timex.beginning_of_week(date, :thu) == thursday
    assert Timex.beginning_of_week(date, "Thursday") == thursday

    # Monday..Friday
    friday = Timex.to_datetime({2015, 11, 27})
    assert Timex.days_to_beginning_of_week(date, 5) == 3
    assert Timex.days_to_beginning_of_week(date, :fri) == 3
    assert Timex.days_to_beginning_of_week(date, "Friday") == 3
    assert Timex.beginning_of_week(date, 5) == friday
    assert Timex.beginning_of_week(date, :fri) == friday
    assert Timex.beginning_of_week(date, "Friday") == friday

    # Monday..Saturday
    saturday = Timex.to_datetime({2015, 11, 28})
    assert Timex.days_to_beginning_of_week(date, 6) == 2
    assert Timex.days_to_beginning_of_week(date, :sat) == 2
    assert Timex.days_to_beginning_of_week(date, "Saturday") == 2
    assert Timex.beginning_of_week(date, 6) == saturday
    assert Timex.beginning_of_week(date, :sat) == saturday
    assert Timex.beginning_of_week(date, "Saturday") == saturday

    # Monday..Sunday
    sunday = Timex.to_datetime({2015, 11, 29})
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

    # Invalid start of week - invalid date
    assert {:error, :invalid_date} = Timex.beginning_of_week("Made up date", "Made up day")
    assert {:error, :invalid_date} = Timex.beginning_of_week(nil, nil)
  end

  test "end_of_week" do
    # Monday 30th November 2015
    date = Timex.to_datetime({2015, 11, 30})

    # Monday..Sunday
    sunday = Timex.to_datetime({{2015, 12, 6}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date) == 6
    assert Timex.days_to_end_of_week(date, 1) == 6
    assert Timex.days_to_end_of_week(date, :mon) == 6
    assert Timex.days_to_end_of_week(date, "Monday") == 6
    assert Timex.end_of_week(date) == sunday
    assert Timex.end_of_week(date, 1) == sunday
    assert Timex.end_of_week(date, :mon) == sunday
    assert Timex.end_of_week(date, "Monday") == sunday

    # Monday..Monday
    monday = Timex.to_datetime({{2015, 11, 30}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 2) == 0
    assert Timex.days_to_end_of_week(date, :tue) == 0
    assert Timex.days_to_end_of_week(date, "Tuesday") == 0
    assert Timex.end_of_week(date, 2) == monday
    assert Timex.end_of_week(date, :tue) == monday
    assert Timex.end_of_week(date, "Tuesday") == monday

    # Monday..Tuesday
    tuesday = Timex.to_datetime({{2015, 12, 1}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 3) == 1
    assert Timex.days_to_end_of_week(date, :wed) == 1
    assert Timex.days_to_end_of_week(date, "Wednesday") == 1
    assert Timex.end_of_week(date, 3) == tuesday
    assert Timex.end_of_week(date, :wed) == tuesday
    assert Timex.end_of_week(date, "Wednesday") == tuesday

    # Monday..Wednesday
    wednesday = Timex.to_datetime({{2015, 12, 2}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 4) == 2
    assert Timex.days_to_end_of_week(date, :thu) == 2
    assert Timex.days_to_end_of_week(date, "Thursday") == 2
    assert Timex.end_of_week(date, 4) == wednesday
    assert Timex.end_of_week(date, :thu) == wednesday
    assert Timex.end_of_week(date, "Thursday") == wednesday

    # Monday..Thursday
    thursday = Timex.to_datetime({{2015, 12, 3}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 5) == 3
    assert Timex.days_to_end_of_week(date, :fri) == 3
    assert Timex.days_to_end_of_week(date, "Friday") == 3
    assert Timex.end_of_week(date, 5) == thursday
    assert Timex.end_of_week(date, :fri) == thursday
    assert Timex.end_of_week(date, "Friday") == thursday

    # Monday..Friday
    friday = Timex.to_datetime({{2015, 12, 4}, {23, 59, 59}})
    assert Timex.days_to_end_of_week(date, 6) == 4
    assert Timex.days_to_end_of_week(date, :sat) == 4
    assert Timex.days_to_end_of_week(date, "Saturday") == 4
    assert Timex.end_of_week(date, 6) == friday
    assert Timex.end_of_week(date, :sat) == friday
    assert Timex.end_of_week(date, "Saturday") == friday

    # Monday..Saturday
    saturday = Timex.to_datetime({{2015, 12, 5}, {23, 59, 59}})
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

    # Invalid end of week - invalid date
    assert {:error, :invalid_date} = Timex.beginning_of_week("Made up date", "Made up day")
    assert {:error, :invalid_date} = Timex.beginning_of_week(nil, nil)
  end

  test "beginning_of_day" do
    date = Timex.to_datetime({{2015, 1, 1}, {13, 14, 15}})
    assert Timex.beginning_of_day(date) == Timex.to_datetime({{2015, 1, 1}, {0, 0, 0}})
    assert {:error, :invalid_date} == Timex.beginning_of_day({"Made up date"})
    assert {:error, :invalid_date} == Timex.beginning_of_day(nil)
  end

  test "end_of_day" do
    date = Timex.to_datetime({{2015, 1, 1}, {13, 14, 15}})
    expected = Timex.to_datetime({{2015, 1, 1}, {23, 59, 59}})
    assert Timex.end_of_day(date) == expected

    assert {:error, :invalid_date} == Timex.end_of_day({"Made up date"})
    assert {:error, :invalid_date} == Timex.end_of_day(nil)
  end

  test "to_datetime with invalid dates" do
    # invalid date tuple
    assert {:error, :invalid_date} == Timex.to_datetime({2015, 1}, {0, 0, 0})
    assert {:error, :invalid_date} == Timex.to_datetime({2015, 1, 1, 1}, {0, 0, 0})

    # just plain wrong
    assert {:error, :invalid_date} == Timex.to_datetime("some day", {0, 0, 0})
    assert {:error, :invalid_date} == Timex.to_datetime("some day", "some time")
  end

  test "start and end for all types" do
    datetime = Timex.now()

    for type_fn <- [:to_datetime, :to_date, :to_naive_datetime, :to_erl],
        modifier_fn_base <- ["day", "week", "month", "quarter", "year"],
        start_or_end <- ["beginning", "end"] do
      modifier_fn = String.to_atom("#{start_or_end}_of_#{modifier_fn_base}")

      datetime_result = apply(Timex, modifier_fn, [datetime])

      # should always set the clock to the first or last second in the given date
      case start_or_end do
        "beginning" -> assert {_, {0, 0, 0}} = Timex.to_erl(datetime_result)
        "end" -> assert {_, {23, 59, 59}} = Timex.to_erl(datetime_result)
      end

      # should return the same value for each implementation
      expected_result = apply(Timex, type_fn, [datetime_result])
      input = apply(Timex, type_fn, [datetime])
      result = apply(Timex, modifier_fn, [input])

      assert expected_result == result,
             "#{modifier_fn} for #{type_fn}:\n#{inspect(expected_result)} should equal #{inspect(result)}"
    end
  end
end
