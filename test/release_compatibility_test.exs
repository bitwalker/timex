defmodule ReleaseCompatibilityTest do
  use ExUnit.Case, async: true

  test "public comparison and conversion defaults remain available" do
    assert Timex.compare(~D[2024-01-01], ~D[2024-01-02]) == -1
    assert Timex.diff(~N[2024-01-02 00:00:00], ~N[2024-01-01 00:00:00]) == 86_400_000_000
    assert Timex.to_datetime(~D[2024-01-01]) == ~U[2024-01-01 00:00:00Z]
  end

  test "Erlang tuple conversion produces Julian days rather than an internal success tuple" do
    assert Timex.to_julian({2000, 1, 1}) == 2_451_545
    assert Timex.to_julian({{2000, 1, 1}, {12, 0, 0}}) == 2_451_545
    assert Timex.to_julian({2000, 13, 1}) == {:error, :invalid_date}
  end

  test "whole-second shifts preserve declared precision" do
    assert Timex.shift(~U[2024-01-01 00:00:00Z], minutes: 1) == ~U[2024-01-01 00:01:00Z]

    assert Timex.shift(~N[2024-01-01 00:00:00.000], seconds: -1) ==
             ~N[2023-12-31 23:59:59.000]
  end

  test "fractional shifts promote only as far as needed to represent the result" do
    assert Timex.shift(~U[2024-01-01 00:00:00Z], milliseconds: 1) ==
             ~U[2024-01-01 00:00:00.001Z]

    assert Timex.shift(~U[2024-01-01 00:00:00Z], microseconds: -1) ==
             ~U[2023-12-31 23:59:59.999999Z]

    assert Timex.shift(~U[2024-01-01 00:00:00.000000Z], milliseconds: 1) ==
             ~U[2024-01-01 00:00:00.001000Z]

    assert Timex.shift(~U[2024-01-01 00:00:00Z], milliseconds: 1, microseconds: -1000) ==
             ~U[2024-01-01 00:00:00Z]
  end

  test "precision survives elapsed shifts across DST transitions" do
    input = Timex.to_datetime(~U[2024-03-10 06:30:00Z], "America/New_York")
    shifted = Timex.shift(input, hours: 1)
    assert shifted.hour == 3
    assert shifted.microsecond == {0, 0}
    assert DateTime.diff(shifted, input) == 3600
  end
end
