defmodule IntervalTests do
  use ExUnit.Case, async: true
  use Timex

  doctest Timex.Interval

  test "can enumerate days in an interval" do
    dates = Interval.new(from: Timex.datetime({2014, 9, 22}), until: [days: 3])
            |> Enum.map(&(Timex.format!(&1, "%Y-%m-%d", :strftime)))
    assert ["2014-09-22", "2014-09-23", "2014-09-24"] == dates
  end

  test "can exclude end date" do
    dates = Interval.new(from: Timex.datetime({2014, 9, 22}), until: [days: 3], left_open: false, right_open: false)
            |> Enum.map(&(Timex.format!(&1, "%Y-%m-%d", :strftime)))
    assert ["2014-09-22", "2014-09-23", "2014-09-24", "2014-09-25"] == dates
  end

  test "can exclude start date" do
    dates = Interval.new(from: Timex.datetime({2014, 9, 22}), until: [days: 3], left_open: true, right_open: false)
            |> Enum.map(&(Timex.format!(&1, "%Y-%m-%d", :strftime)))
    assert ["2014-09-23", "2014-09-24", "2014-09-25"] == dates
  end

  test "can enumerate by other units in an interval" do
    steps = Interval.new(from: Timex.datetime({{2014, 9, 22}, {15, 0, 0}}), until: [hours: 1])
            |> Interval.with_step(minutes: 10)
            |> Enum.map(&(Timex.format!(&1, "%H:%M", :strftime)))
    assert ["15:00", "15:10", "15:20", "15:30", "15:40", "15:50"] == steps
  end

  test "can get duration of an interval" do
    duration = Interval.new(from: Timex.datetime({2014, 9, 22}), until: [months: 5])
               |> Interval.duration(:months)
    assert 5 == duration

    duration = Interval.new(from: Timex.datetime({{2014, 9, 22}, {15, 30, 0}}), until: [minutes: 20])
               |> Interval.duration(:timestamp)
    assert {0, 1200, 0} == duration
  end
end
