defmodule ShiftTests do
  use ExUnitProperties
  use ExUnit.Case, async: true
  use Timex

  @units [:years, :months, :weeks, :days, :hours, :minutes, :seconds, :microseconds]

  property "is always greater than input date for positive shift values" do
    check all(
            input_date <- PropertyHelpers.date_time_generator(:struct),
            shift <- StreamData.integer(1..1000),
            unit <- StreamData.member_of(@units)
          ) do
      date = Timex.shift(input_date, [{unit, shift}])
      assert Timex.after?(date, input_date)
    end
  end

  property "is always lower than input date for negative shift values" do
    check all(
            input_date <- PropertyHelpers.date_time_generator(:struct),
            shift <- StreamData.integer(-1..-1000),
            unit <- StreamData.member_of(@units)
          ) do
      date = Timex.shift(input_date, [{unit, shift}])
      assert Timex.before?(date, input_date)
    end
  end

  property "does not change for 0 shift values" do
    check all(
            input_date <- PropertyHelpers.date_time_generator(:struct),
            unit <- StreamData.member_of(@units)
          ) do
      date = Timex.shift(input_date, [{unit, 0}])
      assert Timex.equal?(date, input_date)
    end
  end

  test "shift by months in a nonexistent day" do
    date = Timex.shift(~N[2015-06-29T12:00:00], months: -4)
    assert ~N[2015-02-28T12:00:00] = date
  end

  test "shift by year" do
    date = Timex.shift(Timex.epoch(), years: 3)
    expected = ~D[1973-01-01]
    assert expected === date
  end

  test "shift by year from leap year" do
    date = Timex.shift(~D[2016-02-29], years: 2)
    expected = ~D[2018-03-01]
    assert expected === date
  end

  test "shift by 5 month in the same year" do
    date = Timex.shift(~D[2016-01-15], months: 5)
    expected = ~D[2016-06-15]
    assert expected === date
  end

  test "shift by -5 month in the same year" do
    date = Timex.shift(~D[2016-06-15], months: -5)
    expected = ~D[2016-01-15]
    assert expected === date
  end

  test "shift by -1 month into the previous year" do
    date = Timex.shift(~D[2016-01-01], months: -1)
    expected = ~D[2015-12-01]
    assert expected === date
  end

  test "shift by -12 month into the previous year" do
    date = Timex.shift(~D[2016-12-01], months: -12)
    expected = ~D[2015-12-01]
    assert expected === date
  end

  test "shift by -11 month in the same year" do
    date = Timex.shift(~D[2016-12-01], months: -11)
    expected = ~D[2016-01-01]
    assert expected === date
  end

  test "shift by 5 month into the next year" do
    date = Timex.shift(~D[2016-09-15], months: 5)
    expected = ~D[2017-02-15]
    assert expected === date
  end

  test "shift by -5 month into the previous year" do
    date = Timex.shift(~D[2016-03-15], months: -5)
    expected = ~D[2015-10-15]
    assert expected === date
  end

  test "shift by -37 month into past" do
    date = Timex.shift(~D[2016-01-01], months: -37)
    expected = ~D[2012-12-01]
    assert expected === date
  end

  test "shift by -24 month into past" do
    date = Timex.shift(Timex.epoch(), months: -24)
    expected = ~D[1968-01-01]
    assert expected === date
  end

  test "issue 230 - shifting epoch by -13 months takes you to 1969" do
    date = Timex.shift(Timex.epoch(), months: -13)
    expected = ~D[1968-12-01]
    assert expected === date
  end

  test "shift by a month from November" do
    date = Timex.shift(~D[2000-11-01], months: 1)
    expected = ~D[2000-12-01]
    assert expected === date
  end

  test "shift by weeks" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], weeks: 1)
    expected = ~N[2017-10-31 12:00:00.100000]
    assert expected === date
  end

  test "shift by days" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], days: 1)
    expected = ~N[2017-10-25 12:00:00.100000]
    assert expected === date
  end

  test "shift by hours" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], hours: 1)
    expected = ~N[2017-10-24 13:00:00.100000]
    assert expected === date
  end

  test "shift by minutes" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], minutes: 1)
    expected = ~N[2017-10-24 12:01:00.100000]
    assert expected === date
  end

  test "shift by seconds" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], seconds: 1)
    expected = ~N[2017-10-24 12:00:01.100000]
    assert expected === date
  end

  test "shift by milliseconds" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], milliseconds: 1)
    expected = ~N[2017-10-24 12:00:00.101000]
    assert expected === date
  end

  test "shift by microseconds" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], microseconds: 1)
    expected = ~N[2017-10-24 12:00:00.100001]
    assert expected === date
  end

  test "shift by duration" do
    date =
      Timex.shift(~N[2017-10-24 12:00:00.100000],
        duration: Timex.Duration.from_microseconds(100)
      )

    expected = ~N[2017-10-24 12:00:00.100100]
    assert expected === date
  end

  test "shift to zero" do
    result = Timex.shift(~N[0000-01-01 00:00:01], seconds: -1)
    expected = ~N[0000-01-01 00:00:00]
    assert expected === result
  end

  test "shift to an invalid datetime" do
    result = Timex.shift(~N[0000-01-01 00:00:00], months: -1)
    assert {:error, :shift_to_invalid_date} === result
  end

  test "shift by an invalid unit" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], dayz: 1)
    assert {:error, {:unknown_shift_unit, :dayz}} === date
  end

  test "shift datetime by a month from the end of January" do
    date = ~D[2000-01-31] |> Timex.to_datetime() |> Timex.shift(months: 1)
    expected = ~D[2000-02-29] |> Timex.to_datetime()
    assert expected === date
  end

  test "shift November DTS datetime by a month in America/New_York timezone" do
    date = ~D[2018-11-01] |> Timex.to_datetime("America/New_York") |> Timex.shift(months: 1)
    expected = ~D[2018-12-01] |> Timex.to_datetime("America/New_York")
    assert expected === date
  end

  test "shift March DTS datetime by a month in America/New_York timezone" do
    date = ~D[2018-03-01] |> Timex.to_datetime("America/New_York") |> Timex.shift(months: 1)
    expected = ~D[2018-04-01] |> Timex.to_datetime("America/New_York")
    assert expected === date
  end

  test "shift back 4 days should yield first of month" do
    date = ~D[2018-11-05] |> Timex.to_datetime() |> Timex.shift(days: -4)
    expected = ~D[2018-11-01] |> Timex.to_datetime()
    assert expected === date
  end

  test "shift back 5 days should yield last of previous month" do
    date = ~D[2018-11-05] |> Timex.to_datetime() |> Timex.shift(days: -5)
    expected = ~D[2018-10-31] |> Timex.to_datetime()
    assert expected === date
  end

  test "shift back 4 days should yield first of year" do
    date = ~D[2018-01-05] |> Timex.to_datetime() |> Timex.shift(days: -4)
    expected = ~D[2018-01-01] |> Timex.to_datetime()
    assert expected === date
  end

  test "shift back 5 days should yield last of previous year" do
    date = ~D[2018-01-05] |> Timex.to_datetime() |> Timex.shift(days: -5)
    expected = ~D[2017-12-31] |> Timex.to_datetime()
    assert expected === date
  end

  describe "DateTime does not change precision" do
    test "seconds" do
      datetime = Timex.shift(~U[2023-04-13 08:00:00Z], minutes: 1)
      expected = ~U[2023-04-13 08:01:00Z]
      assert expected === datetime
    end

    test "milliseconds" do
      datetime = Timex.shift(~U[2023-04-13 08:00:00.000Z], minutes: 1)
      expected = ~U[2023-04-13 08:01:00.000Z]
      assert expected === datetime
    end

    test "microseconds" do
      datetime = Timex.shift(~U[2023-04-13 08:00:00.000000Z], minutes: 1)
      expected = ~U[2023-04-13 08:01:00.000000Z]
      assert expected === datetime
    end
  end

  describe "NaiveDateTime does not change precision" do
    test "seconds" do
      datetime = Timex.shift(~N[2023-04-13 08:00:00Z], minutes: 1)
      expected = ~N[2023-04-13 08:01:00Z]
      assert expected === datetime
    end

    test "milliseconds" do
      datetime = Timex.shift(~N[2023-04-13 08:00:00.000Z], minutes: 1)
      expected = ~N[2023-04-13 08:01:00.000Z]
      assert expected === datetime
    end

    test "microseconds" do
      datetime = Timex.shift(~N[2023-04-13 08:00:00.000000Z], minutes: 1)
      expected = ~N[2023-04-13 08:01:00.000000Z]
      assert expected === datetime
    end
  end
end
