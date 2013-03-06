defmodule TimeTest do
  use ExUnit.Case, async: true

  test :diff do
    timestamp1 = {1362,568903,363960}
    timestamp2 = {1362,568958,951099}
    assert Time.diff(timestamp2, timestamp1) == {0, 55, 587139}
    assert Time.diff(timestamp2, timestamp1, :usec) == 55587139
    assert Time.diff(timestamp2, timestamp1, :msec) == 55587.139
    assert Time.diff(timestamp2, timestamp1, :sec)  == 55.587139
    assert Time.diff(timestamp2, timestamp1, :min)  == 55.587139 / 60
    assert Time.diff(timestamp2, timestamp1, :hour) == 55.587139 / 3600
  end

  test :convert do
    timestamp = {1362,568903,363960}
    assert Time.convert(timestamp, :usec) == 1362568903363960
    assert Time.convert(timestamp, :msec) == 1362568903363.960
    assert Time.convert(timestamp, :sec)  == 1362568903.363960
    assert Time.convert(timestamp, :min)  == 1362568903.363960 / 60
    assert Time.convert(timestamp, :hour) == 1362568903.363960 / 3600
  end

  test :to_usec do
    assert Time.to_usec({1362,568903,363960}) == 1362568903363960
    assert Time.to_usec(13, :usec) == 13
    assert Time.to_usec(13, :msec) == 13000
    assert Time.to_usec(13, :sec)  == 13000000
    assert Time.to_usec(13, :min)  == 13000000 * 60
    assert Time.to_usec(13, :hour) == 13000000 * 3600
    assert Time.to_usec({1,2,3}, :hms) == (3600 + 2 * 60 + 3) * 1000000
  end

  test :to_msec do
    assert Time.to_msec({1362,568903,363960}) == 1362568903363.960
    assert Time.to_msec(13, :usec) == 0.013
    assert Time.to_msec(13, :msec) == 13
    assert Time.to_msec(13, :sec)  == 13000
    assert Time.to_msec(13, :min)  == 13000 * 60
    assert Time.to_msec(13, :hour) == 13000 * 3600
    assert Time.to_msec({1,2,3}, :hms) == (3600 + 2 * 60 + 3) * 1000
  end

  test :to_sec do
    assert Time.to_sec({1362,568903,363960}) == 1362568903.363960
    assert Time.to_sec(13, :usec) == 0.000013
    assert Time.to_sec(13, :msec) == 0.013
    assert Time.to_sec(13, :sec)  == 13
    assert Time.to_sec(13, :min)  == 13 * 60
    assert Time.to_sec(13, :hour) == 13 * 3600
    assert Time.to_sec({1,2,3}, :hms) == 3600 + 2 * 60 + 3
  end
end
