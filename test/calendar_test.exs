defmodule CalendarTests do
  use ExUnit.Case, async: true
  alias Timex.Calendar

  test "day_of_week starting sunday" do
    # {2017, 1, 1} was a sunday
    day_numbers = for day <- 1..7, do: Calendar.Julian.day_of_week({2017, 1, day}, :sun)
    assert day_numbers == Enum.to_list(0..6)
  end

  test "day_of_week starting monday" do
    # {2017, 1, 2} was a monday
    day_numbers = for day <- 2..8, do: Calendar.Julian.day_of_week({2017, 1, day}, :mon)
    assert day_numbers == Enum.to_list(1..7)
  end

  test "julian day of year, leap year, leaps disallowed" do
    assert ~D[2020-02-28] = Calendar.Julian.date_for_day_of_year(59, 2020)
    assert ~D[2020-03-01] = Calendar.Julian.date_for_day_of_year(60, 2020)
  end

  test "julian day of year, non-leap year, leaps disallowed" do
    assert ~D[2021-02-28] = Calendar.Julian.date_for_day_of_year(59, 2021)
    assert ~D[2021-03-01] = Calendar.Julian.date_for_day_of_year(60, 2021)
  end

  test "julian day of year, leap year, leaps allowed" do
    assert ~D[2020-02-28] = Calendar.Julian.date_for_day_of_year(58, 2020, leaps: true)
    assert ~D[2020-02-29] = Calendar.Julian.date_for_day_of_year(59, 2020, leaps: true)
    assert ~D[2020-03-01] = Calendar.Julian.date_for_day_of_year(60, 2020, leaps: true)
  end

  test "julian day of year, non-leap year, leaps allowed" do
    assert ~D[2021-02-28] = Calendar.Julian.date_for_day_of_year(58, 2021, leaps: true)
    assert ~D[2021-03-01] = Calendar.Julian.date_for_day_of_year(59, 2021, leaps: true)
    assert ~D[2021-03-02] = Calendar.Julian.date_for_day_of_year(60, 2021, leaps: true)
  end
end
