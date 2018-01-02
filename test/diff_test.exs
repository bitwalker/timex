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
end
