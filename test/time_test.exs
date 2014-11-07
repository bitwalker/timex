defmodule TimeTests do
  use ExUnit.Case, async: true
  use Timex

  test :diff do
    timestamp1 = {1362,568903,363960}
    timestamp2 = {1362,568958,951099}
    assert Time.diff(timestamp2, timestamp1) == {0, 55, 587139}
    assert Time.diff(timestamp2, timestamp1, :usecs) == 55587139
    assert Time.diff(timestamp2, timestamp1, :msecs) == 55587.139
    assert Time.diff(timestamp2, timestamp1, :secs)  == 55.587139
    assert Time.diff(timestamp2, timestamp1, :mins)  == 55.587139 / 60
    assert Time.diff(timestamp2, timestamp1, :hours) == 55.587139 / 3600
  end

  test :convert do
    timestamp = {1362,568903,363960}
    assert Time.convert(timestamp, :usecs) == 1362568903363960
    assert Time.convert(timestamp, :msecs) == 1362568903363.960
    assert Time.convert(timestamp, :secs)  == 1362568903.363960
    assert Time.convert(timestamp, :mins)  == 1362568903.363960 / 60
    assert Time.convert(timestamp, :hours) == 1362568903.363960 / 3600
  end

  test :to_usecs do
    assert Time.to_usecs({1362,568903,363960}) == 1362568903363960
    assert Time.to_usecs(13, :usecs) == 13
    assert Time.to_usecs(13, :msecs) == 13000
    assert Time.to_usecs(13, :secs)  == 13000000
    assert Time.to_usecs(13, :mins)  == 13000000 * 60
    assert Time.to_usecs(13, :hours) == 13000000 * 3600
    assert Time.to_usecs({1,2,3}, :hms) == (3600 + 2 * 60 + 3) * 1000000
  end

  test :to_msecs do
    assert Time.to_msecs({1362,568903,363960}) == 1362568903363.960
    assert Time.to_msecs(13, :usecs) == 0.013
    assert Time.to_msecs(13, :msecs) == 13
    assert Time.to_msecs(13, :secs)  == 13000
    assert Time.to_msecs(13, :mins)  == 13000 * 60
    assert Time.to_msecs(13, :hours) == 13000 * 3600
    assert Time.to_msecs({1,2,3}, :hms) == (3600 + 2 * 60 + 3) * 1000
  end

  test :to_secs do
    assert Time.to_secs({1362,568903,363960}) == 1362568903.363960
    assert Time.to_secs(13, :usecs) == 0.000013
    assert Time.to_secs(13, :msecs) == 0.013
    assert Time.to_secs(13, :secs)  == 13
    assert Time.to_secs(13, :mins)  == 13 * 60
    assert Time.to_secs(13, :hours) == 13 * 3600
    assert Time.to_secs({1,2,3}, :hms) == 3600 + 2 * 60 + 3
  end

  test :elapsed do
    previous_time = {1362,568902,363960}
    now = {1362,568903,363960}
    time_in_millis = Time.to_msecs(previous_time)

    assert Time.elapsed(previous_time, now, :usecs) == 1000000
    assert Time.elapsed(previous_time, now, :msecs) == 1000
    assert Time.elapsed(previous_time, now, :secs) == 1
    assert Time.elapsed(previous_time, now, :mins) == 0.016666666666666666
    assert Time.elapsed(previous_time, now, :hours) == 0.0002777777777777778
    assert_raise FunctionClauseError, fn ->
      Time.elapsed(time_in_millis, :msecs)
    end
  end
end
