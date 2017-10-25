defmodule ShiftTests do
  use ExUnit.Case, async: true
  use Timex

  test "shift by months in a nonexistent day" do
    date = Timex.shift(~N[2015-06-29T12:00:00], months: -4)
    assert ~N[2015-02-28T12:00:00] = date
  end

  test "shift by year" do
    date = Timex.shift(Timex.epoch, years: 3)
    expected = ~D[1973-01-01]
    assert expected === date
  end

  test "shift by year from leap year" do
    date = Timex.shift(~D[2016-02-29], years: 2)
    expected = ~D[2018-02-28]
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
    date = Timex.shift(Timex.epoch, months: -24)
    expected = ~D[1968-01-01]
    assert expected === date
  end

  test "issue 230 - shifting epoch by -13 months takes you to 1969" do
    date = Timex.shift(Timex.epoch, months: -13)
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
    date = Timex.shift(~N[2017-10-24 12:00:00.100000],
      duration: Timex.Duration.from_microseconds(100))
    expected = ~N[2017-10-24 12:00:00.100100]
    assert expected === date
  end

  test "shift to zero" do
    result = Timex.shift(~N[0000-01-01 00:00:01], seconds: -1)
    expected = ~N[0000-01-01 00:00:00]
    assert expected === result
  end

  test "shift to an invalid datetime" do
    result = Timex.shift(~N[0000-01-01 00:00:00], seconds: -1)
    assert {:error, :shift_to_invalid_date} === result
  end

  test "shift by an invalid unit" do
    date = Timex.shift(~N[2017-10-24 12:00:00.100000], dayz: 1)
    assert {:error, {:unknown_shift_unit, :dayz}} === date
  end
end
