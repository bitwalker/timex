defmodule Timex.Parser.Test do
  use ExUnit.Case, async: true
  doctest Timex.Parse.DateTime.Parser

  use Combine
  import Timex.Parse.DateTime.Parsers
  alias Timex.Parse.DateTime.Helpers

  test "helpers: to_month_num" do
    assert [[month: 1]] = Combine.parse("January", month_full([]))
    assert [[month: 1]] = Combine.parse("Jan", month_short([]))
    assert [[month: 2]] = Combine.parse("February", month_full([]))
    assert [[month: 2]] = Combine.parse("Feb", month_short([]))
    assert [[month: 3]] = Combine.parse("March", month_full([]))
    assert [[month: 3]] = Combine.parse("Mar", month_short([]))
    assert [[month: 4]] = Combine.parse("April", month_full([]))
    assert [[month: 4]] = Combine.parse("Apr", month_short([]))
    assert [[month: 5]] = Combine.parse("May", month_full([]))
    assert [[month: 6]] = Combine.parse("June", month_full([]))
    assert [[month: 6]] = Combine.parse("Jun", month_short([]))
    assert [[month: 7]] = Combine.parse("July", month_full([]))
    assert [[month: 7]] = Combine.parse("Jul", month_short([]))
    assert [[month: 8]] = Combine.parse("August", month_full([]))
    assert [[month: 8]] = Combine.parse("Aug", month_short([]))
    assert [[month: 9]] = Combine.parse("September", month_full([]))
    assert [[month: 9]] = Combine.parse("Sep", month_short([]))
    assert [[month: 10]] = Combine.parse("October", month_full([]))
    assert [[month: 10]] = Combine.parse("Oct", month_short([]))
    assert [[month: 11]] = Combine.parse("November", month_full([]))
    assert [[month: 11]] = Combine.parse("Nov", month_short([]))
    assert [[month: 12]] = Combine.parse("December", month_full([]))
    assert [[month: 12]] = Combine.parse("Dec", month_short([]))

    assert {:error, "Expected `full month name` at line 1, column 10."} =
             Combine.parse("Something", month_full([]))
  end

  test "helpers: is_weekday" do
    assert [1] = Combine.parse("Monday", weekday_full([]))
    assert [2] = Combine.parse("Tuesday", weekday_full([]))
    assert [3] = Combine.parse("Wednesday", weekday_full([]))
    assert [4] = Combine.parse("Thursday", weekday_full([]))
    assert [5] = Combine.parse("Friday", weekday_full([]))
    assert [6] = Combine.parse("Saturday", weekday_full([]))
    assert [7] = Combine.parse("Sunday", weekday_full([]))
    assert {:error, _} = Combine.parse("Whatday", weekday_full([]))
  end

  test "helpers: integer" do
    assert [10000] = Combine.parse(" 10000", Helpers.integer(min: -1, padding: :spaces))
    assert [1000] = Combine.parse(" 1000", Helpers.integer(min: 4, padding: :spaces))
    assert {:error, _} = Combine.parse(" 10", Helpers.integer(min: 4, padding: :spaces))

    assert {:error, _} = Combine.parse(" 10", Helpers.integer(min: -1))
    assert [10] = Combine.parse("10", Helpers.integer(min: -1))
    assert [30] = Combine.parse("30", Helpers.integer(min: -1))
  end

  test "parsers: day_of_year" do
    assert [[day_of_year: 365]] = Combine.parse("365", day_of_year(min: 1, max: 3))
    assert {:error, _} = Combine.parse("465", day_of_year(min: 1, max: 3))
  end

  test "parsers: week_of_year" do
    assert [[week_of_year: 3]] = Combine.parse("3", week_of_year(min: 1, max: 2))
    assert {:error, _} = Combine.parse("65", week_of_year(min: 1, max: 2))
  end

  test "parsers: weekday" do
    assert [[weekday: 3]] = Combine.parse("3", weekday(min: 1, max: 1))
    assert {:error, _} = Combine.parse("9", weekday(min: 1, max: 1))
  end

  test "parsers: am/pm lower" do
    assert [[am: "pm"]] = Combine.parse("pm", ampm_lower([]))
    assert [[am: "am"]] = Combine.parse("am", ampm_lower([]))
    assert {:error, _} = Combine.parse("fm", ampm_lower([]))
  end
end
