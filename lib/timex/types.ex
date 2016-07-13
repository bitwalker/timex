defmodule Timex.Types do
  @moduledoc false

  # Date types
  @type year :: Calendar.year
  @type month :: Calendar.month
  @type day :: Calendar.day
  @type daynum :: non_neg_integer
  @type weekday :: non_neg_integer
  @type weeknum :: non_neg_integer
  # Time types
  @type hour :: Calendar.hour
  @type minute :: Calendar.minute
  @type second :: Calendar.second
  @type microsecond :: Calendar.microsecond
  @type timestamp :: {megaseconds, seconds, microseconds }
  @type megaseconds :: non_neg_integer
  @type seconds :: non_neg_integer
  @type milliseconds :: non_neg_integer
  @type microseconds :: non_neg_integer
  # Timezone types
  @type time_zone :: Calendar.time_zone
  @type zone_abbr :: Calendar.zone_abbr
  @type utc_offset :: Calendar.utc_offset
  @type std_offset :: Calendar.std_offset
  @type tz_offset :: -12..12
  @type tz_offset_seconds :: integer
  @type valid_timezone :: String.t | tz_offset | tz_offset_seconds | :utc | :local
  # Complex types
  @type weekday_name :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type shift_units :: :milliseconds | :seconds | :minutes | :hours | :days | :weeks | :years
  @type time_units :: :microseconds | :milliseconds | :seconds | :minutes | :hours | :days | :weeks | :years
  @type time :: { hour, minute, second } | { hour, minute, second, milliseconds }
  @type date :: { year, month, day }
  @type datetime :: { date, time }
  @type iso_triplet :: { year, weeknum, weekday }
  @type phoenix_datetime_select_params :: %{String.t => String.t}
  @type valid_datetime :: Date.t | DateTime.t | NaiveDateTime.t | datetime | date
end
