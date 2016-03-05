defmodule Timex.Constants  do
  @moduledoc false

  defmacro __using__(_) do
    quote do

      @weekday_abbrs       ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
      @weekday_abbrs_lower ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]
      @weekday_names       ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
      @weekday_names_lower ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
      @weekdays            Enum.map(Enum.with_index(@weekday_names), fn {name, i} -> {name, i + 1} end)

      @month_names [
        "January", "February", "March", "April",
        "May", "June", "July", "August",
        "September", "October", "November", "December"
      ]
      @months              Enum.map(Enum.with_index(@month_names), fn {name, i} -> {name, i + 1} end)
      @valid_months 1..12

      @ordinal_day_map [
        {true, 1, 0}, {false, 1, 0},
        {true, 2, 31}, {false, 2, 31},
        {true, 3, 60}, {false, 3, 59},
        {true, 4, 91}, {false, 4, 90},
        {true, 5, 121}, {false, 5, 120},
        {true, 6, 152}, {false, 6, 151},
        {true, 7, 182}, {false, 7, 181},
        {true, 8, 213}, {false, 8, 212},
        {true, 9, 244}, {false, 9, 243},
        {true, 10, 274}, {false, 10, 273},
        {true, 11, 305}, {false, 11, 304},
        {true, 12, 335}, {false, 12, 334}
      ]


      @usecs_in_sec  1_000_000
      @usecs_in_msec 1_000
      @msecs_in_sec  1_000
      @secs_in_min   60
      @secs_in_hour  @secs_in_min * 60
      @secs_in_day   @secs_in_hour * 24
      @secs_in_week  @secs_in_day * 7
      @million       1_000_000

    end
  end

end
