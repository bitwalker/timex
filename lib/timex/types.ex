defmodule Timex.Types do
  # Date types
  @type year :: Calendar.year()
  @type month :: Calendar.month()
  @type day :: Calendar.day()
  @type num_of_days :: 28..31
  @type daynum :: 1..366
  @type week_of_month :: 1..6
  @type weekday :: 1..7
  @type weeknum :: 1..53
  # Time types
  @type hour :: Calendar.hour()
  @type minute :: Calendar.minute()
  @type second :: Calendar.second()
  @type microsecond :: Calendar.microsecond()
  @type timestamp :: {megaseconds, seconds, microseconds}
  @type megaseconds :: non_neg_integer
  @type seconds :: non_neg_integer
  @type microseconds :: non_neg_integer
  # Timezone types
  @type time_zone :: Calendar.time_zone()
  @type zone_abbr :: Calendar.zone_abbr()
  @type utc_offset :: Calendar.utc_offset()
  @type std_offset :: Calendar.std_offset()
  @type tz_offset :: -14..12
  @type valid_timezone :: String.t() | tz_offset | :utc | :local
  # Complex types
  @type weekday_name ::
          :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type shift_units :: :milliseconds | :seconds | :minutes | :hours | :days | :weeks | :years
  @type time_units ::
          :microsecond
          | :microseconds
          | :millisecond
          | :milliseconds
          | :second
          | :seconds
          | :minute
          | :minutes
          | :hour
          | :hours
          | :day
          | :days
          | :week
          | :weeks
          | :year
          | :years
  @type time :: {hour, minute, second}
  @type microsecond_time :: {hour, minute, second, microsecond | microseconds}
  @type date :: {year, month, day}
  @type datetime :: {date, time}
  @type microsecond_datetime :: {date, microsecond_time}
  @type iso_triplet :: {year, weeknum, weekday}
  @type calendar_types :: Date.t() | DateTime.t() | NaiveDateTime.t() | Time.t()
  @type valid_datetime ::
          Date.t()
          | DateTime.t()
          | NaiveDateTime.t()
          | Time.t()
          | datetime
          | date
          | microsecond_datetime
  @type valid_date :: Date.t() | date
  @type valid_time :: Time.t() | time
  @type weekstart :: weekday | binary | atom
end
