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
end
