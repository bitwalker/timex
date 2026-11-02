defmodule Timex.Parse.FractionalPrecisionTest do
  use ExUnit.Case, async: true

  @format "{YYYY}-{0M}-{0D} {h24}:{m}:{s}{ss}"

  test "explicit zero fractions retain their input precision across timezone paths" do
    for precision <- 1..6,
        {suffix, zone_format} <- [
          {"", ""},
          {" America/New_York", " {Zname}"},
          {" +05:30", " {Z:}"}
        ] do
      fraction = String.duplicate("0", precision)
      input = "2022-06-24 08:00:00.#{fraction}#{suffix}"
      parsed = Timex.parse!(input, @format <> zone_format)

      assert parsed.microsecond == {0, precision}
      assert parsed.hour == 8
      assert Timex.format!(parsed, "{ss}") == ".#{fraction}"
    end
  end

  test "nonzero fractions preserve leading and trailing zero precision" do
    for {fraction, expected} <- [
          {"1", {100_000, 1}},
          {"01", {10_000, 2}},
          {"010", {10_000, 3}},
          {"0010", {1_000, 4}},
          {"00010", {100, 5}},
          {"000010", {10, 6}}
        ] do
      parsed = Timex.parse!("2022-06-24 08:00:00.#{fraction}", @format)
      assert parsed.microsecond == expected
      assert Timex.format!(parsed, "{ss}") == ".#{fraction}"
    end
  end

  test "omitted optional fractions retain zero precision" do
    assert Timex.parse!("2022-06-24T08:00:00", "{ISO:Extended}").microsecond == {0, 0}
  end

  test "zero precision agrees with ISO and strftime fractional parsing" do
    for precision <- 1..6 do
      fraction = String.duplicate("0", precision)
      input = "2022-06-24T08:00:00.#{fraction}"
      assert Timex.parse!(input, "{ISO:Extended}").microsecond == {0, precision}
      assert Timex.parse!(input, "%FT%T.%f", :strftime).microsecond == {0, precision}
    end
  end
end
