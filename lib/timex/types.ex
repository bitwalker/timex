defmodule Timex.Types do
  @moduledoc false

  # Date types
  @type year :: non_neg_integer
  @type month :: 1..12
  @type day :: 1..31
  @type daynum :: 1..366
  @type weekday :: 1..7
  @type weeknum :: 1..53
  @type num_of_days :: 28..31
  # Time types
  @type hour :: 0..23
  @type minute :: 0..59
  @type second :: 0..59
  @type timestamp :: {megaseconds, seconds, microseconds }
  @type megaseconds :: non_neg_integer
  @type seconds :: non_neg_integer
  @type milliseconds :: non_neg_integer
  @type microseconds :: non_neg_integer
  # Timezone types
  @type tz_offset :: -12..12
  @type valid_timezone :: Timex.TimezoneInfo.t | String.t | tz_offset | :utc | :local
  # Complex types
  @type weekday_name :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type shift_units :: :milliseconds | :seconds | :minutes | :hours | :days | :weeks | :years
  @type time_units :: :microseconds | :milliseconds | :seconds | :minutes | :hours | :days | :weeks | :years
  @type time :: { hour, minute, second } | { hour, minute, second, milliseconds }
  @type date :: { year, month, day }
  @type datetime :: { date, time }
  @type gregorian :: { datetime, Timex.TimezoneInfo.t }
  @type iso_triplet :: { year, weeknum, weekday }
  @type phoenix_datetime_select_params :: %{String.t => String.t}
  @type valid_datetime :: Timex.Date.t | Timex.DateTime.t | date | datetime
  @type all_valid_datetime :: valid_datetime | gregorian
end
