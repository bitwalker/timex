defmodule TimeTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex.Time
  doctest Timex.Format.Time.Formatter

  test "to_12hour_clock" do
    assert Time.to_12hour_clock(0) == {12, :am}
    assert Time.to_12hour_clock(2) == {2, :am}
    assert Time.to_12hour_clock(12) == {12, :pm}
    assert Time.to_12hour_clock(17) == {5, :pm}
    assert Time.to_12hour_clock(24) == {12, :am}
  end

  test "to_24hour_clock" do
    assert Time.to_24hour_clock(12, :am) == 0
    assert Time.to_24hour_clock(3, :am) == 3
    assert Time.to_24hour_clock(12, :pm) == 12
    assert Time.to_24hour_clock(1, :pm) == 13
  end

  test "add" do
    assert Time.add({1,2,3}, {4,5,6}) == {5,7,9}

    assert_raise ArithmeticError, fn ->
      Time.add({:x,2,3}, {4,5,6})
    end
  end

  test "sub" do
    assert Time.sub({4,5,6}, {1,2,3}) == {3,3,3}
    # assert Time.sub({4,5,6}, {10,2,3}) == {-6,3,3}
    assert Time.sub({4,5,6}, {-1,2,3}) == {5,3,3}

    assert_raise ArithmeticError, fn ->
      Time.sub({:x,2,3}, {4,5,6})
    end
  end

  test "scale" do
    assert Time.scale({4,5,6}, 2) == {8,10,12}
    # assert Time.scale({4,5,6}, {10,2,3}) == {-6,3,3}
    # assert Time.scale({4,5,6}, 1/2) == {2, 2.5, 3}
    assert Time.scale({4,5,6}, -2) == {-8, -10, -12}

    # assert_raise ArithmeticError, fn ->
    #   Time.scale({4,5,6}, 2)
    # end
  end

  test "diff" do
    timestamp1 = {1362,568903,363960}
    timestamp2 = {1362,568958,951099}
    assert Time.diff(timestamp2, timestamp1) == {0, 55, 587139}
    assert Time.diff(timestamp2, timestamp1, :usecs) == 55587139
    assert Time.diff(timestamp2, timestamp1, :msecs) == 55587.139
    assert Time.diff(timestamp2, timestamp1, :secs)  == 55.587139
    assert Time.diff(timestamp2, timestamp1, :mins)  == 55.587139 / 60
    assert Time.diff(timestamp2, timestamp1, :hours) == 55.587139 / 3600
  end

  test "measure/2" do
    {{_, _, _}, result} = Time.measure(fn x -> x end, [:nothing])
    assert result == :nothing
  end

  test "measure/3" do
    {{_, _, _}, result} = Time.measure(__MODULE__, :something_to_measure, [:nothing])
    assert result == :nothing
  end

  test "convert" do
    timestamp = {1362,568903,363960}
    assert Time.convert(timestamp) == timestamp
    assert Time.convert(timestamp, :usecs) == 1362568903363960
    assert Time.convert(timestamp, :msecs) == 1362568903363.960
    assert Time.convert(timestamp, :secs)  == 1362568903.363960
    assert Time.convert(timestamp, :mins)  == 1362568903.363960 / 60
    assert Time.convert(timestamp, :hours) == 1362568903.363960 / 3600

    assert_raise Timex.Time.InvalidUnitError, fn ->
      Time.convert(timestamp, :wrong_unit)
    end
  end

  test "epoch" do
    assert Time.epoch == {62_167, 219_200, 0}
    assert Time.epoch(:days) == 719_528.0
    assert Time.epoch(:weeks) == 102_789.71428571429
  end

  test "to_usecs" do
    assert Time.to_usecs({1362,568903,363960}) == 1362568903363960
    assert Time.to_usecs(13, :usecs) == 13
    assert Time.to_usecs(13, :msecs) == 13000
    assert Time.to_usecs(13, :secs)  == 13000000
    assert Time.to_usecs(13, :mins)  == 13000000 * 60
    assert Time.to_usecs(13, :hours) == 13000000 * 3600
    assert Time.to_usecs({1,2,3}, :hms) == (3600 + 2 * 60 + 3) * 1000000
  end

  test "to_msecs" do
    assert Time.to_msecs({1362,568903,363960}) == 1362568903363.960
    assert Time.to_msecs(13, :usecs) == 0.013
    assert Time.to_msecs(13, :msecs) == 13
    assert Time.to_msecs(13, :secs)  == 13000
    assert Time.to_msecs(13, :mins)  == 13000 * 60
    assert Time.to_msecs(13, :hours) == 13000 * 3600
    assert Time.to_msecs({1,2,3}, :hms) == (3600 + 2 * 60 + 3) * 1000
  end

  test "to_secs" do
    assert Time.to_secs({1362,568903,363960}) == 1362568903.363960
    assert Time.to_secs(13, :usecs) == 0.000013
    assert Time.to_secs(13, :msecs) == 0.013
    assert Time.to_secs(13, :secs)  == 13
    assert Time.to_secs(13, :mins)  == 13 * 60
    assert Time.to_secs(13, :hours) == 13 * 3600
    assert Time.to_secs({1,2,3}, :hms) == 3600 + 2 * 60 + 3
  end

  test "to_mins" do
    assert Time.to_mins(1, :hours) == 60

    assert_raise Timex.Time.InvalidUnitError, fn ->
      Time.to_mins(1, :hour) == 60
    end
  end

  test "to_hours" do
    assert Time.to_hours(1, :days) == 24

    assert_raise Timex.Time.InvalidUnitError, fn ->
      Time.to_hours(1, :day) == 60
    end
  end

  test "to_timestamp" do
    assert Time.to_timestamp(1, :usecs) == {0, 0, 1}
    assert Time.to_timestamp(1, :msecs) == {0, 0, 1000}
    assert Time.to_timestamp(1, :secs) == {0, 1, 0}
    assert Time.to_timestamp(1, :mins) == {0, 60, 0}
    assert Time.to_timestamp(1, :hours) == {0, 3600, 0}
    assert Time.to_timestamp(1, :days) == {0, 86400, 0}
    assert Time.to_timestamp(1, :weeks) == {0, 604800, 0}
    assert Time.to_timestamp({1, 1, 1}, :hms) == {0, 3661, 0}

    assert_raise Timex.Time.InvalidUnitError, fn ->
      Time.to_timestamp(1, :wrong_unit)
    end
  end

  test "zero" do
    assert Time.zero == {0, 0, 0}
  end

  test "invert" do
    assert Time.invert({1, -2, 3}) == {-1, 2, -3}
  end

  test "abs" do
    # assert Time.abs({-1, -2, 3}) == {1, 2, 3}
  end

  test "elapsed" do
    previous_time = {1362,568902,363960}
    now = {1362,568903,363960}
    time_in_millis = Time.to_msecs(previous_time)

    assert Time.elapsed(previous_time, now, :usecs) == 1000000
    assert Time.elapsed(previous_time, now, :msecs) == 1000
    assert Time.elapsed(previous_time, now, :secs) == 1
    assert Time.elapsed(previous_time, now, :mins) == 0.016666666666666666
    assert Time.elapsed(previous_time, now, :hours) == 0.0002777777777777778

    # How to test when function is based on Time.now/0 ?
    # assert Time.elapsed(previous_time) == Time.diff(Time.now, previous_time, :timestamp)

    assert_raise FunctionClauseError, fn ->
      Time.elapsed(time_in_millis, :msecs)
    end
  end

  # Just make sure that Timex.Time.measure is called at least once in the tests
  test "measure/1" do
    reversed_list = Enum.to_list(100000..1)
    assert { {mega, secs, micro}, ^reversed_list } = Time.measure(fn -> Enum.reverse(1..100000) end)
    assert mega + secs + micro > 0
  end

  def something_to_measure(x), do: x
end
