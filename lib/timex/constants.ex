defmodule Timex.Constants do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @weekday_abbrs ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
      @weekday_abbrs_lower ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
      @weekday_names [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
        "Sunday"
      ]
      @weekday_names_lower [
        "monday",
        "tuesday",
        "wednesday",
        "thursday",
        "friday",
        "saturday",
        "sunday"
      ]
      @weekdays Enum.map(Enum.with_index(@weekday_names), fn {name, i} -> {name, i + 1} end)

      @month_names [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
      ]
      @months Enum.map(Enum.with_index(@month_names), fn {name, i} -> {name, i + 1} end)
      @month_abbrs Enum.map(@month_names, fn name -> String.slice(name, 0, 3) end)
      @valid_months 1..12

      # month => {month, ordinal_day_of_first_of_month}
      @ordinals_leap %{
        1 => 1,
        2 => 1 + 31,
        3 => 1 + 31 + 29,
        4 => 1 + 31 + 29 + 31,
        5 => 1 + 31 + 29 + 31 + 30,
        6 => 1 + 31 + 29 + 31 + 30 + 31,
        7 => 1 + 31 + 29 + 31 + 30 + 31 + 30,
        8 => 1 + 31 + 29 + 31 + 30 + 31 + 30 + 31,
        9 => 1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31,
        10 => 1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
        11 => 1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
        12 => 1 + 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30
      }
      @ordinals %{
        1 => 1,
        2 => 1 + 31,
        3 => 1 + 31 + 28,
        4 => 1 + 31 + 28 + 31,
        5 => 1 + 31 + 28 + 31 + 30,
        6 => 1 + 31 + 28 + 31 + 30 + 31,
        7 => 1 + 31 + 28 + 31 + 30 + 31 + 30,
        8 => 1 + 31 + 28 + 31 + 30 + 31 + 30 + 31,
        9 => 1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31,
        10 => 1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30,
        11 => 1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31,
        12 => 1 + 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30
      }

      @usecs_in_sec 1_000_000
      @usecs_in_msec 1_000
      @msecs_in_sec 1_000
      @secs_in_min 60
      @secs_in_hour @secs_in_min * 60
      @secs_in_day @secs_in_hour * 24
      @secs_in_week @secs_in_day * 7
      @million 1_000_000
    end
  end
end
