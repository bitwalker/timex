defmodule Timex.TimezoneInfo do
  @moduledoc """
  All relevant timezone information for a given period, i.e. Europe/Moscow on March 3rd, 2013

  Notes:
    - `full_name` is the name of the zone, but does not indicate anything about the current period (i.e. CST vs CDT)
    - `abbreviation` is the abbreviated name for the zone in the current period, i.e. "America/Chicago" on 3/30/15 is "CDT"
    - `offset_std` is the offset in minutes from standard time for this period
    - `offset_utc` is the offset in minutes from UTC for this period
  Spec:
    - `day_of_week`: :sunday, :monday, :tuesday, etc
    - `datetime`:    {{year, month, day}, {hour, minute, second}}
    - `from`:      :min | {day_of_week, datetime}, when this zone starts
    - `until`:     :max | {day_of_week, datetime}, when this zone ends
  """

  defstruct full_name:        "Etc/UTC",
            abbreviation:     "UTC",
            offset_std:       0,
            offset_utc:       0,
            from:             :min,
            until:            :max

  @type day_of_week :: :sunday | :monday | :tuesday |
                       :wednesday | :thursday | :friday | :saturday
  @type datetime :: {{non_neg_integer, 1..12, 1..366}, {0..24,0..59,0..60}}
  @type t :: %__MODULE__{
    full_name: String.t,
    abbreviation: String.t,
    offset_std: integer,
    offset_utc: integer,
    from: :min | {day_of_week, datetime},
    until: :max | {day_of_week, datetime}
  }
end
