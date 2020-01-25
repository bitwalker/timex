defmodule ComparableTests do
  use ExUnit.Case, async: true
  alias Timex.Comparable
  alias Timex.AmbiguousDateTime

  test "compare tuple" do
    assert 0 = Comparable.compare({2016, 1, 1}, {2016, 1, 1})
    assert 1 = Comparable.compare({2016, 1, 1}, :distant_past)
    assert -1 = Comparable.compare({2016, 1, 1}, :distant_future)
    assert 1 = Comparable.compare({2016, 1, 1}, {2015, 1, 1})
    assert -1 = Comparable.compare({2015, 1, 1}, {2016, 1, 1})

    assert {:error, :invalid_date} = Comparable.compare({0, 0, 0}, {2015, 1, 1})
    assert 0 = Comparable.compare({{2015, 1, 2}, {12, 30, 0}}, {{2015, 1, 2}, {12, 30, 0}})
    assert 1 = Comparable.compare({{2015, 1, 2}, {12, 30, 0}}, {{2015, 1, 2}, {12, 20, 0}})
    assert -1 = Comparable.compare({{2015, 1, 2}, {12, 20, 0}}, {{2015, 1, 2}, {12, 30, 0}})

    assert 0 =
             Comparable.compare({{2015, 1, 2}, {12, 30, 0}}, {{2015, 1, 2}, {12, 20, 0}}, :hours)
  end

  test "diff tuple" do
    assert 0 = Comparable.diff({2016, 1, 1}, {2016, 1, 1})
    assert -1 = Comparable.diff({2016, 1, 1}, {2016, 1, 2}, :days)
    assert {:error, :invalid_date} = Comparable.diff({0, 0, 0}, {2015, 1, 1})
  end

  test "compare ambiguous_datetime" do
    lmt_jwst = Timex.to_datetime({{1895, 12, 31}, {23, 55, 0}}, "Asia/Taipei")
    assert 0 = Comparable.compare(lmt_jwst, lmt_jwst)
    assert 1 = Comparable.compare(lmt_jwst, :distant_past)
    assert -1 = Comparable.compare(lmt_jwst, :distant_future)
  end

  test "diff ambiguous_datetime" do
    lmt_jwst = Timex.to_datetime({{1895, 12, 31}, {23, 55, 0}}, "Asia/Taipei")
    amb = %AmbiguousDateTime{before: lmt_jwst, after: lmt_jwst}
    assert 0 = Comparable.compare(amb, amb)

    assert {:error, {:ambiguous_comparison, _}} =
             Comparable.compare(amb, Timex.to_naive_datetime({2015, 1, 1}))
  end

  test "compare naive_datetime" do
    naive_dt = Timex.to_naive_datetime({1970, 1, 1})
    assert -1 == Comparable.compare(naive_dt, :distant_future)
    assert +1 == Comparable.compare(naive_dt, :distant_past)
    assert 0 == Comparable.compare(naive_dt, :epoch)
    assert +1 == Comparable.compare(naive_dt, :zero)
  end

  test "supports singular timeunits" do
    date1 = Timex.to_datetime({1971, 1, 1})
    date2 = Timex.to_datetime({1973, 1, 1})

    assert Timex.compare(date1, date2, :seconds) == Timex.compare(date1, date2, :second)
    assert Timex.compare(date1, date2, :minutes) == Timex.compare(date1, date2, :minute)
    assert Timex.compare(date1, date2, :hours) == Timex.compare(date1, date2, :hour)
    assert Timex.compare(date1, date2, :days) == Timex.compare(date1, date2, :day)
    assert Timex.compare(date1, date2, :weeks) == Timex.compare(date1, date2, :week)
    assert Timex.compare(date1, date2, :months) == Timex.compare(date1, date2, :month)
    assert Timex.compare(date1, date2, :years) == Timex.compare(date1, date2, :year)
  end
end
