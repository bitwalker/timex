defmodule IntervalTests do
  use ExUnit.Case, async: true
  use Timex
  alias Timex.Duration

  doctest Timex.Interval

  describe "new/1" do
    test "returns an Interval when given no options" do
      assert %Interval{} = Interval.new()
    end

    test "returns an Interval when given a valid step unit" do
      assert %Interval{step: [microseconds: 5]} = Interval.new(step: [microseconds: 5])
      assert %Interval{step: [milliseconds: 5]} = Interval.new(step: [milliseconds: 5])
      assert %Interval{step: [seconds: 5]}      = Interval.new(step: [seconds: 5])
      assert %Interval{step: [minutes: 5]}      = Interval.new(step: [minutes: 5])
      assert %Interval{step: [hours: 5]}        = Interval.new(step: [hours: 5])
      assert %Interval{step: [days: 5]}         = Interval.new(step: [days: 5])
      assert %Interval{step: [weeks: 5]}        = Interval.new(step: [weeks: 5])
      assert %Interval{step: [months: 5]}       = Interval.new(step: [months: 5])
      assert %Interval{step: [years: 5]}       =  Interval.new(step: [years: 5])
    end

    test "returns an error tuple when given an invalid step" do
      assert {:error, :invalid_step} = Interval.new(step: [invalid_step: 5])
    end

    test "returns an Interval when given a valid until field" do
      assert %Interval{until: %NaiveDateTime{}} = Interval.new(until: %NaiveDateTime{year: 2017, month: 4, day: 3,
                                                                                     hour: 1, minute: 1, second: 1})
      assert %Interval{until: %NaiveDateTime{}} = Interval.new(until: DateTime.utc_now())
      assert %Interval{until: %NaiveDateTime{}} = Interval.new(until: %Date{year: 2017, month: 4, day: 3})
    end

    test "returns an Interval with shifted until when given a shift for until" do
      interval = Interval.new(from: ~D[2014-04-03], until: [days: 10])
      assert %Interval{until: ~N[2014-04-13 00:00:00]} = interval
    end

    test "returns an error tuple when given an invalid until" do
      assert {:error, :invalid_until} = Interval.new(until: "invalid_until")
    end

    test "returns same type of error when given until that is error tuple" do
      assert {:error, :error_type} = Interval.new(until: {:error, :error_type})
    end
  end

  describe "with_step/2" do
    test "updates step to step with valid step unit" do
      interval = Interval.new()
      assert %Interval{step: [microseconds: 5]} = Interval.with_step(interval, [microseconds: 5])
      assert %Interval{step: [milliseconds: 5]} = Interval.with_step(interval, [milliseconds: 5])
      assert %Interval{step: [seconds: 5]}      = Interval.with_step(interval, [seconds: 5])
      assert %Interval{step: [minutes: 5]}      = Interval.with_step(interval, [minutes: 5])
      assert %Interval{step: [hours: 5]}        = Interval.with_step(interval, [hours: 5])
      assert %Interval{step: [days: 5]}         = Interval.with_step(interval, [days: 5])
      assert %Interval{step: [weeks: 5]}        = Interval.with_step(interval, [weeks: 5])
      assert %Interval{step: [months: 5]}       = Interval.with_step(interval, [months: 5])
      assert %Interval{step: [years: 5]}       =  Interval.with_step(interval, [years: 5])
    end

    test "returns error tuple when given invalid step unit" do
      interval = Interval.new()
      assert {:error, :invalid_step} = Interval.with_step(interval, [invalid_step: 3])
    end
  end

  test "can enumerate days in an interval" do
    dates = Interval.new(from: ~D[2014-09-22], until: [days: 3])
            |> Enum.map(&(Timex.format!(&1, "%Y-%m-%d", :strftime)))
    assert ["2014-09-22", "2014-09-23", "2014-09-24"] == dates
  end

  test "can include end date" do
    dates = Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: false)
            |> Enum.map(&(Timex.format!(&1, "%Y-%m-%d", :strftime)))
    assert ["2014-09-22", "2014-09-23", "2014-09-24", "2014-09-25"] == dates
  end

  test "can exclude start date" do
    dates = Interval.new(from: ~D[2014-09-22], until: [days: 3], left_open: true)
            |> Enum.map(&(Timex.format!(&1, "%Y-%m-%d", :strftime)))
    assert ["2014-09-23", "2014-09-24"] == dates
  end

  test "can enumerate by other units in an interval" do
    steps = Interval.new(from: ~N[2014-09-22T15:00:00], until: [hours: 1])
            |> Interval.with_step(minutes: 10)
            |> Enum.map(&(Timex.format!(&1, "%H:%M", :strftime)))
    assert ["15:00", "15:10", "15:20", "15:30", "15:40", "15:50"] == steps
  end

  test "raises FormatError when enumerating with an invalid step unit" do
    interval = %Interval{from: ~D[2017-04-02], until: ~D[2017-05-02], step: [invalid_step: 1]}
    assert_raise Interval.FormatError, "Invalid step unit for %Timex.Interval{}", fn ->
      Enum.count(interval)
    end
  end

  test "can get duration of an interval" do
    duration = Interval.new(from: ~D[2014-09-22], until: [months: 5])
               |> Interval.duration(:months)
    assert 5 == duration

    duration = Interval.new(from: ~N[2014-09-22T15:30:00], until: [minutes: 20])
               |> Interval.duration(:duration)
    assert Duration.from_minutes(20) == duration
  end

  describe "member" do
    test "membership includes start date" do
      interval = Interval.new(from: ~D[2014-09-22], until: [days: 3])
      assert ~D[2014-09-22] in interval
    end

    test "membership does not include end date" do
      interval = Interval.new(from: ~D[2014-09-22], until: [days: 3])
      refute ~D[2014-09-25] in interval
    end

    test "can exclude start date from membership" do
      interval = Interval.new(from: ~D[2014-09-22], until: [days: 3], left_open: true)
      refute ~D[2014-09-22] in interval
    end

    test "can include end date in membership" do
      interval = Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: false)
      assert ~D[2014-09-25] in interval
    end

    test "open and closed interval" do
      interval = Interval.new(from: ~D[2014-09-22], until: ~D[2014-09-22])
      refute ~D[2014-09-22] in interval
    end

    test "membership includes datetimes in interval" do
      interval = Interval.new(from: ~D[2014-09-22], until: ~D[2014-09-24])
      assert ~N[2014-09-22 00:00:00] in interval
    end
  end

  describe "overlaps?/2" do
    test "non-overlapping" do
      interval_a = Interval.new(from: ~D[2014-09-20], until: ~D[2014-09-24])
      interval_b = Interval.new(from: ~D[2014-09-25], until: ~D[2014-09-30])

      refute Interval.overlaps?(interval_a, interval_b)
    end

    test "first subset of second" do
      interval_a = Interval.new(from: ~D[2014-09-20], until: ~D[2014-09-24])
      interval_b = Interval.new(from: ~D[2014-09-20], until: ~D[2014-09-30])

      assert Interval.overlaps?(interval_a, interval_b)
    end

    test "first superset of second" do
      interval_a = Interval.new(from: ~D[2014-09-20], until: ~D[2014-09-24])
      interval_b = Interval.new(from: ~D[2014-09-20], until: ~D[2014-09-22])

      assert Interval.overlaps?(interval_a, interval_b)
    end

    test "first partially ahead of second" do
      interval_a = Interval.new(from: ~D[2014-09-20], until: ~D[2014-09-24])
      interval_b = Interval.new(from: ~D[2014-09-22], until: ~D[2014-09-26])

      assert Interval.overlaps?(interval_a, interval_b)
    end

    test "first partially behind second" do
      interval_a = Interval.new(from: ~D[2014-09-23], until: ~D[2014-09-28])
      interval_b = Interval.new(from: ~D[2014-09-22], until: ~D[2014-09-26])

      assert Interval.overlaps?(interval_a, interval_b)
    end
  end
end
