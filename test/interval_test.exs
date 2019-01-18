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
      assert %Interval{step: [seconds: 5]} = Interval.new(step: [seconds: 5])
      assert %Interval{step: [minutes: 5]} = Interval.new(step: [minutes: 5])
      assert %Interval{step: [hours: 5]} = Interval.new(step: [hours: 5])
      assert %Interval{step: [days: 5]} = Interval.new(step: [days: 5])
      assert %Interval{step: [weeks: 5]} = Interval.new(step: [weeks: 5])
      assert %Interval{step: [months: 5]} = Interval.new(step: [months: 5])
      assert %Interval{step: [years: 5]} = Interval.new(step: [years: 5])
    end

    test "returns an error tuple when given an invalid step" do
      assert {:error, :invalid_step} = Interval.new(step: [invalid_step: 5])
    end

    test "returns an Interval when given a valid until field" do
      from = ~N[2017-04-03 00:00:00]
      assert %Interval{} = Interval.new(from: from, until: ~N[2017-04-03 01:01:01])
      assert %Interval{} = Interval.new(from: from, until: DateTime.utc_now())
      assert %Interval{} = Interval.new(from: from, until: %Date{year: 2017, month: 4, day: 4})
    end

    test "returns an Interval with shifted until when given a shift for until" do
      interval = Interval.new(from: ~D[2014-04-03], until: [days: 10])
      assert %Interval{until: ~N[2014-04-13 00:00:00]} = interval
    end

    test "returns an error tuple when given an invalid until" do
      assert {:error, :invalid_until} = Interval.new(until: "invalid_until")
    end
  end

  describe "with_step/2" do
    test "updates step to step with valid step unit" do
      interval = Interval.new()
      assert %Interval{step: [microseconds: 5]} = Interval.with_step(interval, microseconds: 5)
      assert %Interval{step: [milliseconds: 5]} = Interval.with_step(interval, milliseconds: 5)
      assert %Interval{step: [seconds: 5]} = Interval.with_step(interval, seconds: 5)
      assert %Interval{step: [minutes: 5]} = Interval.with_step(interval, minutes: 5)
      assert %Interval{step: [hours: 5]} = Interval.with_step(interval, hours: 5)
      assert %Interval{step: [days: 5]} = Interval.with_step(interval, days: 5)
      assert %Interval{step: [weeks: 5]} = Interval.with_step(interval, weeks: 5)
      assert %Interval{step: [months: 5]} = Interval.with_step(interval, months: 5)
      assert %Interval{step: [years: 5]} = Interval.with_step(interval, years: 5)
    end

    test "returns error tuple when given invalid step unit" do
      interval = Interval.new()
      assert {:error, :invalid_step} = Interval.with_step(interval, invalid_step: 3)
    end
  end

  test "can enumerate days in an interval" do
    dates =
      Interval.new(from: ~D[2014-09-22], until: [days: 3])
      |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))

    assert ["2014-09-22", "2014-09-23", "2014-09-24"] == dates
  end

  test "right closed interval includes until" do
    dates =
      Interval.new(from: ~D[2014-09-22], until: [days: 3], right_open: false)
      |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))

    assert ["2014-09-22", "2014-09-23", "2014-09-24", "2014-09-25"] == dates
  end

  test "left open interval excludes from" do
    dates =
      Interval.new(from: ~D[2014-09-22], until: [days: 3], left_open: true)
      |> Enum.map(&Timex.format!(&1, "%Y-%m-%d", :strftime))

    assert ["2014-09-23", "2014-09-24"] == dates
  end

  test "can enumerate by other units in an interval" do
    steps =
      Interval.new(from: ~N[2014-09-22T15:00:00], until: [hours: 1])
      |> Interval.with_step(minutes: 10)
      |> Enum.map(&Timex.format!(&1, "%H:%M", :strftime))

    assert ["15:00", "15:10", "15:20", "15:30", "15:40", "15:50"] == steps
  end

  test "raises FormatError when enumerating with an invalid step unit" do
    interval = %Interval{from: ~D[2017-04-02], until: ~D[2017-05-02], step: [invalid_step: 1]}

    assert_raise Interval.FormatError, "Invalid step unit for interval: :invalid_step", fn ->
      Enum.count(interval)
    end
  end

  test "can get duration of an interval" do
    duration =
      Interval.new(from: ~D[2014-09-22], until: [months: 5])
      |> Interval.duration(:months)

    assert 5 == duration

    duration =
      Interval.new(from: ~N[2014-09-22T15:30:00], until: [minutes: 20])
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

    test "default half-closed interval includes from, not until" do
      interval = Interval.new(from: ~D[2014-09-22], until: ~D[2014-09-23])
      refute interval.until in interval
      assert interval.from in interval
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

    test "left open and right closed bounds do not overlap" do
      a = Interval.new(from: ~N[2017-01-02 15:00:00], until: ~N[2017-01-02 15:15:00])
      b = Interval.new(from: ~N[2017-01-02 14:00:00], until: ~N[2017-01-02 15:00:00])

      refute Interval.overlaps?(a, b)
      refute Interval.overlaps?(b, a)
    end
  end

  describe "contains?/2" do
    test "non-overlapping" do
      earlier = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-04])
      later = Interval.new(from: ~D[2018-01-05], until: ~D[2018-01-10])

      refute Interval.contains?(earlier, later)
    end

    test "first subset of second" do
      superset = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-31])
      subset_a = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-30])
      subset_b = Interval.new(from: ~D[2018-01-02], until: ~D[2018-01-15])

      refute Interval.contains?(subset_a, superset)
      refute Interval.contains?(subset_b, superset)
    end

    test "first superset of second" do
      superset = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-31])
      subset_a = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-30])
      subset_b = Interval.new(from: ~D[2018-01-02], until: ~D[2018-01-15])

      assert Interval.contains?(superset, subset_a)
      assert Interval.contains?(superset, subset_b)
    end

    test "first partially ahead of second" do
      first = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-10])
      second = Interval.new(from: ~D[2018-01-05], until: ~D[2018-01-15])

      refute Interval.contains?(first, second)
    end

    test "first partially behind second" do
      first = Interval.new(from: ~D[2018-01-05], until: ~D[2018-01-15])
      second = Interval.new(from: ~D[2018-01-01], until: ~D[2018-01-10])

      refute Interval.contains?(first, second)
    end

    test "contains itself" do
      from = ~D[2018-01-01]
      until = ~D[2018-01-15]

      interval_a = Interval.new(from: from, until: until, left_open: true, right_open: false)
      assert Interval.contains?(interval_a, interval_a)

      interval_b = Interval.new(from: from, until: until, left_open: true, right_open: true)
      assert Interval.contains?(interval_b, interval_b)

      interval_c = Interval.new(from: from, until: until, left_open: false, right_open: true)
      assert Interval.contains?(interval_c, interval_c)

      interval_d = Interval.new(from: from, until: until, left_open: false, right_open: false)
      assert Interval.contains?(interval_d, interval_d)
    end
  end

  describe "difference/2 removes the part of one interval that overlaps with another" do
    test "returns a list with the original interval when there is no overlap" do
      midnight_to_noon =
        Timex.Interval.new(
          from: ~N[2018-01-01 00:00:00.000],
          until: ~N[2018-01-01 12:00:00.000]
        )

      two_pm_to_four_pm =
        Timex.Interval.new(
          from: ~N[2018-01-01 14:00:00.000],
          until: ~N[2018-01-01 16:00:00.000]
        )

      assert Interval.difference(midnight_to_noon, two_pm_to_four_pm) == [midnight_to_noon]

      assert Interval.difference(two_pm_to_four_pm, midnight_to_noon) == [two_pm_to_four_pm]
    end

    test "returns an empty list when removal interval completely covers the original" do
      two_to_four =
        Timex.Interval.new(
          from: ~N[2018-01-01 02:00:00.000],
          until: ~N[2018-01-01 04:00:00.000]
        )

      one_to_five =
        Timex.Interval.new(
          from: ~N[2018-01-01 01:00:00.000],
          until: ~N[2018-01-01 05:00:00.000]
        )

      assert Interval.difference(two_to_four, one_to_five) == []
      assert Interval.difference(two_to_four, two_to_four) == []
      assert Interval.difference(one_to_five, one_to_five) == []
    end

    test "trims the original interval when the removal interval overlaps one end" do
      two_to_three =
        Timex.Interval.new(
          from: ~N[2018-01-01 02:00:00.000],
          until: ~N[2018-01-01 03:00:00.000]
        )

      two_to_four =
        Timex.Interval.new(
          from: ~N[2018-01-01 02:00:00.000],
          until: ~N[2018-01-01 04:00:00.000]
        )

      three_to_four =
        Timex.Interval.new(
          from: ~N[2018-01-01 03:00:00.000],
          until: ~N[2018-01-01 04:00:00.000]
        )

      three_to_five =
        Timex.Interval.new(
          from: ~N[2018-01-01 03:00:00.000],
          until: ~N[2018-01-01 05:00:00.000]
        )

      assert Interval.difference(two_to_four, two_to_three) ==
               [
                 Timex.Interval.new(
                   from: ~N[2018-01-01 03:00:00.000],
                   until: ~N[2018-01-01 04:00:00.000]
                 )
               ]

      assert Interval.difference(two_to_four, three_to_four) ==
               [
                 Timex.Interval.new(
                   from: ~N[2018-01-01 02:00:00.000],
                   until: ~N[2018-01-01 03:00:00.000]
                 )
               ]

      assert Interval.difference(two_to_four, three_to_five) ==
               [
                 Timex.Interval.new(
                   from: ~N[2018-01-01 02:00:00.000],
                   until: ~N[2018-01-01 03:00:00.000]
                 )
               ]

      assert Interval.difference(three_to_five, two_to_four) ==
               [
                 Timex.Interval.new(
                   from: ~N[2018-01-01 04:00:00.000],
                   until: ~N[2018-01-01 05:00:00.000]
                 )
               ]
    end

    test "splits the original interval when the removal interval falls inside it" do
      one_to_five =
        Timex.Interval.new(
          from: ~N[2018-01-01 01:00:00.000],
          until: ~N[2018-01-01 05:00:00.000]
        )

      two_to_three =
        Timex.Interval.new(
          from: ~N[2018-01-01 02:00:00.000],
          until: ~N[2018-01-01 03:00:00.000]
        )

      assert Interval.difference(one_to_five, two_to_three) ==
               [
                 Timex.Interval.new(
                   from: ~N[2018-01-01 01:00:00.000],
                   until: ~N[2018-01-01 02:00:00.000]
                 ),
                 Timex.Interval.new(
                   from: ~N[2018-01-01 03:00:00.000],
                   until: ~N[2018-01-01 05:00:00.000]
                 )
               ]
    end

    test "other than 'from' and 'until', preserves the original interval's attributes" do
      one_to_fives =
        for left_open <- [true, false],
            right_open <- [true, false],
            step <- [[seconds: 1], [minutes: 2]] do
          Timex.Interval.new(
            from: ~N[2018-01-01 01:00:00.000],
            until: ~N[2018-01-01 05:00:00.000],
            left_open: left_open,
            right_open: right_open,
            step: step
          )
        end

      midnight_to_two =
        Timex.Interval.new(
          from: ~N[2018-01-01 00:00:00.000],
          until: ~N[2018-01-01 02:00:00.000]
        )

      two_to_three =
        Timex.Interval.new(
          from: ~N[2018-01-01 02:00:00.000],
          until: ~N[2018-01-01 03:00:00.000]
        )

      four_to_six =
        Timex.Interval.new(
          from: ~N[2018-01-01 04:00:00.000],
          until: ~N[2018-01-01 06:00:00.000]
        )

      Enum.each(one_to_fives, fn one_to_five ->
        assert [split_1, split_2] = Interval.difference(one_to_five, two_to_three)

        assert split_1.left_open == one_to_five.left_open
        assert split_1.right_open == one_to_five.right_open
        assert split_1.step == one_to_five.step

        assert split_2.left_open == one_to_five.left_open
        assert split_2.right_open == one_to_five.right_open
        assert split_2.step == one_to_five.step

        assert [left_trimmed] = Interval.difference(one_to_five, midnight_to_two)

        assert left_trimmed.left_open == one_to_five.left_open
        assert left_trimmed.right_open == one_to_five.right_open
        assert left_trimmed.step == one_to_five.step

        assert [right_trimmed] = Interval.difference(one_to_five, four_to_six)
        assert right_trimmed.right_open == one_to_five.right_open
        assert right_trimmed.left_open == one_to_five.left_open
        assert right_trimmed.step == one_to_five.step
      end)
    end
  end
end
