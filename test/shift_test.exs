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

  test "issue 230 - shifting epoch by -13 months takes you to 1969" do
    date = Timex.shift(Timex.epoch, months: -24)
    expected = ~D[1968-01-01]
    assert expected === date
  end

end
