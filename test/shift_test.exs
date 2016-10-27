defmodule ShiftTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex

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

  test "shift by positive month in the same year" do
    date = Timex.shift(~D[2016-01-15], months: 5)
    expected = ~D[2016-06-15]
    assert expected === date
  end

  test "shift by negative month in the same year" do
    date = Timex.shift(~D[2016-06-15], months: -5)
    expected = ~D[2016-01-15]
    assert expected === date
  end

  test "shift by positive month into the next year" do
    date = Timex.shift(~D[2016-09-15], months: 5)
    expected = ~D[2017-02-15]
    assert expected === date
  end

  test "shift by negative month into the previous year" do
    date = Timex.shift(~D[2016-03-15], months: -5)
    expected = ~D[2015-10-15]
    assert expected === date
  end

  test "shift by negative month 3 years and a month" do
    date = Timex.shift(~D[2016-01-01], months: -37)
    expected = ~D[2012-12-01]
    assert expected === date
  end

  test "shift by negative month" do
    date = Timex.shift(Timex.epoch, months: -24)
    expected = ~D[1968-01-01]
    assert expected === date
  end

  test "issue 230 - shifting epoch by -13 months takes you to 1969" do
    date = Timex.shift(Timex.epoch, months: -13)
    expected = ~D[1968-12-01]
    assert expected === date
  end

end
