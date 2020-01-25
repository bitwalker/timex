defmodule Timex.Calendar.JulianTest do
  use ExUnit.Case, async: true
  alias Timex.Calendar.Julian

  # test values generated from:
  # http://aa.usno.navy.mil/data/docs/JulianDate.php

  test "Test Julian Date" do
    assert Julian.julian_date(2018, 10, 1) == 2_458_393
  end

  test "Test Julian Date right after midnight" do
    assert Julian.julian_date(2018, 10, 1, 0, 0, 1) == 2_458_392.500011574
  end

  test "Test Julian Date at noon" do
    assert Julian.julian_date(2018, 10, 1, 12, 0, 0) == 2_458_393
  end

  test "Test Julian Date morning hour" do
    assert Julian.julian_date(2018, 10, 1, 6, 0, 0) == 2_458_392.75
  end

  test "Test Julian Date evening hour" do
    assert Julian.julian_date(2018, 10, 1, 18, 0, 0) == 2_458_393.25
  end
end
