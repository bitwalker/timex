# Erlang Interop

## Erlang Dates and Times

### How to work with Erlang datetime and time representations

Without Timex, you've probably been working with Erlang's standard library `:calendar` module and/or `:os.timestamp` function, you may have code which already works on them, or need to consume them from another library, etc. The two most common representations of time in Erlang are the datetime and timestamp tuples, `{{year, month, day}, {hour, minute, second}}`, and `{megaseconds, seconds, microseconds}` respectively. The former is of course used for representing dates and times in a familiar format, the latter is used for representing precise moments in time, down to the microsecond.

### Converting from Erlang datetime tuples

```elixir
# To bring the aliases for Timex's modules into scope, we need to "use" Timex
> use Timex

# Our input datetime
> date = :calendar.universal_time
{{2015, 6, 24}, {3, 59, 5}}

# The simplest case, converting a date from Erlang form to DateTime (in universal time)
> date |> Date.from
%DateTime{
  calendar: :gregorian,
  year: 2015, day: 24, hour: 4, minute: 0, month: 6, ms: 0, second: 11,
  timezone: %TimezoneInfo{
    abbreviation: "UTC", from: :min, full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max
  }
}

# I'll truncate the output for further examples, our next is converting a local datetime tuple
> date = :calendar.local_time
{{2015, 6, 23}, {23, 8, 21}}
> tz = Timezone.local
%TimezoneInfo{abbreviation: "CDT", full_name: "America/Chicago", ...}
> date |> Date.from(tz)
%DateTime{..., hour: 23, minute: 8, second: 21,
  timezone: %TimezoneInfo{abbreviation: "CDT", full_name: "America/Chicago", ...}
}

# You can also convert from universal to a given timezone during creation, like so:
> :calendar.universal_time |> Date.from("Europe/Copenhagen")
%DateTime{..., month: 6, day: 24, hour: 4, minute: 13, second: 31, timezone: %TimezoneInfo{abbreviation: "CEST", full_name: "Europe/Copenhagen", ...}
}
```

### Converting from Erlang timestamp tuples

```elixir
# The simplest case, converting from a timestamp to a DateTime, using the highest precision
> time = :os.timestamp
{1435, 119513, 829885}
> time |> Date.from(:timestamp)
%DateTime{..., year: 2015, month: 6, day: 24, hour: 4, minute: 18, second: 33, ms: 830, timezone: %TimezoneInfo{abbreviation: "UTC", ...}}

# Alternatively if you want control over the precision (in this example, we only care about up-to-the-second precision):
> time |> Time.to_secs |> Date.from(:secs)
%DateTime{..., year: 2015, month: 6, day: 24, hour: 4, minute: 18, second: 33, ms: 0, timezone: %TimezoneInfo{abbreviation: "UTC", ...}}
```

### Converting DateTimes to Erlang datetime tuples

```elixir
# Use the Date.Convert module (aliased to DateConvert with "use Timex")
> date = Date.now
%DateTime{..., year: 2015, month: 6, day: 24, hour: 4, minute: 18, second: 33, ms: 0, ...}
> date |> DateConvert.to_erlang_datetime
{{2015, 6, 24}, {4, 18, 33}}

# You can also produce a variant of the Erlang datetime tuple which also contains the timezone offset (in hours) and abbreviation:
> Date.local |> DateConvert.to_gregorian
{{2015, 6, 23}, {23, 28, 47}, {1.0, "CDT"}}
```
