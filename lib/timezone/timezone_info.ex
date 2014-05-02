defmodule Timex.TimezoneInfo do
  @moduledoc """
  Complete definition of a time zone, including all name
  variations, offsets, and daylight savings time rules if
  they apply.
  
  Notes:
    - `full_name` must be unique
    - `standard_name`, `standard_abbreviation`: Name and abbreviation of timezone before daylight savings time
    - `dst_name`, `dst_abbreviation`:           Name and abbreviation of timezone after daylight savings time
    - `gmt_offset_std`:                         Integer, GMT offset in minutes, outside of daylight savings time
    - `gmt_offset_dst`:                         Integer, GMT offset in minutes, during daylight savings time
    - `dst_start_day`, `dst_end_day`:           Can be defined as either :none or {week_of_year, day_of_week, month_of_year} 
                                              When not :none, represents the daylight savings time transition rule.
  Spec:
    - week_of_year:  integer() | :last, Example: 1 = first week, 2 = second week, N = nth week, etc
    - day_of_week:   atom(), :sun, :mon, :tue, etc
    - month_of_year: atom(), :jan, :feb, :mar, etc
    - `dst_start_time`, `dst_end_time`:         Defined as {hour, min}, represents the time of the daylight savings time transition.
  Spec:
    - hour = integer(), 0..23
    - min  = integer(), 0..59
  """
 
  defstruct full_name:             "",
            standard_abbreviation: "",
            standard_name:         "",
            dst_abbreviation:      "",
            dst_name:              "",
            gmt_offset_std:        0,
            gmt_offset_dst:        0,
            dst_start_day:         :undef,
            dst_start_time:        :undef,
            dst_end_day:           :undef,
            dst_end_time:          :undef
end