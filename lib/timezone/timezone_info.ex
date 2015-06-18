defmodule Timex.TimezoneInfo do
  @moduledoc """
  Complete definition of a time zone for a given period
  
  Notes:
    - `full_name` must be unique
    - `abbreviation`:  Abbreviation of timezone
    - `offset_std`:    Integer, offset in minutes from standard for this period
    - `offset_utc`:    Integer, offset in minutes from UTC for this period
  Spec:
    - week_of_year:  integer() | :last, Example: 1 = first week, 2 = second week, N = nth week, etc
    - day_of_week:   atom(), :sun, :mon, :tue, etc
    - month_of_year: atom(), :jan, :feb, :mar, etc
    - `dst_start_time`, `dst_end_time`:         Defined as {hour, min}, represents the time of the daylight savings time transition.
  Spec:
    - hour = integer(), 0..23
    - min  = integer(), 0..59
  """
 
  defstruct full_name:        "UTC",
            abbreviation:     "UTC",
            offset_std:       0,
            offset_utc:       0,
            from:             :min,
            until:            :max
end