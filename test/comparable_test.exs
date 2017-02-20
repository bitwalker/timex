defmodule ComparableTests do
  use ExUnit.Case, async: true
  alias Timex.Comparable

  test "compare tuple" do
    assert 0 = Comparable.compare({2016,1,1}, {2016,1,1})
    assert 1 = Comparable.compare({2016,1,1}, :distant_past)
    assert -1 = Comparable.compare({2016,1,1}, :distant_future)
    assert 1 = Comparable.compare({2016,1,1}, {2015,1,1})
    assert -1 = Comparable.compare({2015,1,1}, {2016,1,1})

    assert {:error, :invalid_date} = Comparable.compare({0,0,0}, {2015,1,1})
    assert 0 = Comparable.compare({{2015,1,2},{12,30,0}}, {{2015,1,2},{12,30,0}})
    assert 1 = Comparable.compare({{2015,1,2},{12,30,0}}, {{2015,1,2},{12,20,0}})
    assert -1 = Comparable.compare({{2015,1,2},{12,20,0}}, {{2015,1,2},{12,30,0}})
    assert 0 = Comparable.compare({{2015,1,2},{12,30,0}}, {{2015,1,2},{12,20,0}}, :hours)
  end

  test "diff tuple" do
    assert 0 = Comparable.diff({2016,1,1}, {2016,1,1})
    assert -1 = Comparable.diff({2016,1,1}, {2016,1,2}, :days)
    assert {:error, :invalid_date} = Comparable.diff({0,0,0}, {2015,1,1})
  end

  test "compare ambiguous_datetime" do
    lmt_jwst = Timex.to_datetime({{1895,12,31},{23,55,0}}, "Asia/Taipei")
    assert 0 = Comparable.compare(lmt_jwst, lmt_jwst)
    assert 1 = Comparable.compare(lmt_jwst, :distant_past)
    assert -1 = Comparable.compare(lmt_jwst, :distant_future)
  end

  test "diff ambiguous_datetime" do
    lmt_jwst = Timex.to_datetime({{1895,12,31},{23,55,0}}, "Asia/Taipei")
    assert 0 = Comparable.compare(lmt_jwst, lmt_jwst)
    assert {:error, {:ambiguous_comparison, _}} = Comparable.compare(lmt_jwst, Timex.to_naive_datetime({2015, 1, 1}))
  end

  test "calculate difference in months" do
    assert   0 == Comparable.diff({2017,4,30}, {2017,3,31}, :months)
    assert   1 == Comparable.diff({2017,4,30}, {2017,3,30}, :months)
    assert  12 == Comparable.diff({2017,5, 1}, {2016,4,30}, :months)
    assert -12 == Comparable.diff({2016,4,30}, {2017,5, 1}, :months)
  end

  test "calculate difference in years" do
    assert   1 == Comparable.diff({2017,3,  1}, {2016,2,29}, :years)
    assert   0 == Comparable.diff({2017,4, 10}, {2016,4,15}, :years)
    assert  -1 == Comparable.diff({2015,2, 28}, {2016,2,28}, :years)
  end
end
