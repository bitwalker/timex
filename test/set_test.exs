defmodule SetTests do
  use ExUnit.Case, async: true
  use Timex

  test "sets from time struct" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3}})
    new_date = Timex.set(original_date, [time: ~T[09:52:33.000]])

    assert original_date.year == new_date.year
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
  end

  test "sets from time struct with more than one change requested" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3}})
    new_date = Timex.set(original_date, [time: ~T[09:52:33.000], year: 1989])

    assert new_date.year == 1989
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
  end

  test "sets from date struct" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {12, 0, 0}})
    new_date = Timex.set(original_date, [date: ~D[2018-09-02], hour: 16])

    assert new_date.year == 2018
    assert new_date.month == 9
    assert new_date.day == 2

    assert new_date.hour == 16
    assert new_date.minute == 0
    assert new_date.second == 0
  end
end
