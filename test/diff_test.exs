defmodule DiffTests do
  use ExUnit.Case, async: true
  use Timex

  test "diff with same month and end day greater than start day" do
    difference = Timex.diff(~D[2018-01-02], ~D[2017-01-01], :months)
    expected = 12
    assert expected === difference
  end

  test "diff with same month and end day equal to start day" do
    difference = Timex.diff(~D[2018-01-01], ~D[2017-01-01], :months)
    expected = 12
    assert expected === difference
  end

  test "diff with same month and end day smaller than start day" do
    difference = Timex.diff(~D[2018-01-01], ~D[2017-01-02], :months)
    expected = 11
    assert expected === difference
  end

  test "supports singular timeunits" do
    date1 = Timex.to_datetime({1971, 1, 1})
    date2 = Timex.to_datetime({1973, 1, 1})

    assert Timex.diff(date1, date2, :seconds) == Timex.diff(date1, date2, :second)
    assert Timex.diff(date1, date2, :minutes) == Timex.diff(date1, date2, :minute)
    assert Timex.diff(date1, date2, :hours) == Timex.diff(date1, date2, :hour)
    assert Timex.diff(date1, date2, :days) == Timex.diff(date1, date2, :day)
    assert Timex.diff(date1, date2, :weeks) == Timex.diff(date1, date2, :week)
    assert Timex.diff(date1, date2, :months) == Timex.diff(date1, date2, :month)
    assert Timex.diff(date1, date2, :years) == Timex.diff(date1, date2, :year)
  end
end
