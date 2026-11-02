defmodule Timex.Format.WeekNumberTest do
  use ExUnit.Case, async: true

  test "week zero and first week boundaries for every year-start weekday" do
    # Ordinary and leap years, each starting on every weekday Monday through Sunday.
    for {year, first_monday, first_sunday, last_monday_week, last_sunday_week} <- [
          {2018, 1, 7, 53, 52},
          {2019, 7, 6, 52, 52},
          {2025, 6, 5, 52, 52},
          {2026, 5, 4, 52, 52},
          {2021, 4, 3, 52, 52},
          {2022, 3, 2, 52, 52},
          {2023, 2, 1, 52, 53},
          {2024, 1, 7, 53, 52},
          {2036, 7, 6, 52, 52},
          {2020, 6, 5, 52, 52},
          {2032, 5, 4, 52, 52},
          {2016, 4, 3, 52, 52},
          {2028, 3, 2, 52, 53},
          {2012, 2, 1, 53, 53}
        ],
        {first_day, last_week, token, directive} <- [
          {first_monday, last_monday_week, "Wmon", "W"},
          {first_sunday, last_sunday_week, "Wsun", "U"}
        ] do
      if first_day > 1 do
        assert_week(Date.new!(year, 1, 1), token, directive, 0)
        assert_week(Date.new!(year, 1, first_day - 1), token, directive, 0)
      end

      assert_week(Date.new!(year, 1, first_day), token, directive, 1)
      assert_week(Date.new!(year, 1, first_day + 6), token, directive, 1)
      assert_week(Date.new!(year, 1, first_day + 7), token, directive, 2)
      assert_week(Date.new!(year, 12, 31), token, directive, last_week)
    end
  end

  test "Sunday weeks advance on Sunday in years starting Sunday" do
    for {date, week} <- [
          {~D[2023-04-28], 17},
          {~D[2023-04-29], 17},
          {~D[2023-04-30], 18},
          {~D[2023-05-01], 18}
        ] do
      assert_week(date, "Wsun", "U", week)
    end
  end

  test "ISO weeks retain their own year boundary" do
    assert Timex.format!(~D[2023-01-01], "{WYYYY}-{Wiso}") == "2022-52"
    assert Timex.format!(~D[2023-01-01], "%G-%V", :strftime) == "2022-52"
    assert Timex.format!(~D[2024-12-31], "{WYYYY}-{Wiso}") == "2025-01"
    assert Timex.format!(~D[2024-12-31], "%G-%V", :strftime) == "2025-01"
  end

  defp assert_week(date, token, directive, week) do
    plain = Integer.to_string(week)
    zeroes = String.pad_leading(plain, 2, "0")
    spaces = String.pad_leading(plain, 2, " ")

    assert Timex.format!(date, "{#{token}}") == plain
    assert Timex.format!(date, "{0#{token}}") == zeroes
    assert Timex.format!(date, "{_#{token}}") == spaces
    assert Timex.format!(date, "%#{directive}", :strftime) == zeroes
    assert Timex.format!(date, "%-#{directive}", :strftime) == plain
    assert Timex.format!(date, "%_#{directive}", :strftime) == spaces
  end
end
