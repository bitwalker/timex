# Working with DateTime

A breakdown of the Timex.Date API

**NOTE:** As a rule, Timex validates dates/times are valid within certain constraints, but it makes no guarantees around user-provided input. Some functions in the Timex API have high complexity relative to the input values, and if you are not careful to sanitize input to these functions, an attacker can exploit this to lock processes calling these functions, and potentially DoS your system. The only general exception to this rule is with datetime parsing, which is very strict about what values are considered valid. Some format strings do allow unbounded values to be provided however, such as the {s-epoch} format token. As such, it is recommended that you take care to specify format strings which are as restrictive as possible.

## Get the current date

```elixir
# In UTC
> Date.now
# In the local timezone
> Date.local
# In an arbitrary timezone
> Date.now("America/Chicago")

# Get the number of seconds since Epoch
> Date.now(:secs)
```

## Convert to a timezone

```elixir
# To local time
> date |> Date.local
# To universal time
> date |> Date.universal
# To an arbitrary timezone
> date |> Timezone.convert("America/Chicago")
```

## Addition/subtraction

### Adding

```elixir
# Date.add takes a DateTime and a timestamp ({megasecs, secs, microsecs})
> date = Date.now
%DateTime{calendar: :gregorian, day: 24, hour: 14, minute: 27, month: 6,
 ms: 821, second: 52,
 timezone: %TimezoneInfo{...}, year: 2015}
> date |> Date.add(Time.to_timestamp(8, :days))
%DateTime{calendar: :gregorian, day: 2, hour: 14, minute: 27, month: 7,
 ms: 0, second: 52,
 timezone: %TimezoneInfo{...}, year: 2015}
```

### Subtracting

```elixir
# Date.subtract, like add, takes a DateTime and a timestamp
> date = Date.now
%DateTime{calendar: :gregorian, day: 24, hour: 14, minute: 27, month: 6,
 ms: 821, second: 52,
 timezone: %TimezoneInfo{...}, year: 2015}
> date |> Date.subtract(Time.to_timestamp(8, :days))
%DateTime{calendar: :gregorian, day: 16, hour: 14, minute: 27, month: 6,
 ms: 0, second: 52,
 timezone: %TimezoneInfo{...}, year: 2015}
```

## Shifting through time

Shifts rely on a specification of how to shift the DateTime, the valid values for these shift specs are: `:timestamp`, `:secs`, `:mins`, `:hours`, `:days`, `:weeks`, `:months`, `:years`.

**NOTE:** Currently `:months` is not supported in complex shifts (i.e. `[months: 2, days: 3]`).

```elixir
# Shifts are a more flexible way of moving a DateTime through time and
# range from simple shifts...
> date = Date.now
> date |> Date.shift(days: 5)
# To more complex shifts...
> date |> Date.shift([days: 5, hours: 3, mins: 2])
```

### Get the century for a given DateTime

```elixir
# Gets the current century
> Date.century
21
# Gets the century of the provided DateTime
> Date.from({{1437, 3, 5}, {12, 0, 0}}) |> Date.century
15
```

## Comparisons

Compare two dates returning one of the following values:

   * `-1` -- the first date comes before the second one
   * `0`  -- both arguments represent the same date when coalesced to the same timezone.
   * `1`  -- the first date comes after the second one

You can optionality specify a granularity using:

  * :years
  * :months
  * :weeks
  * :days
  * :hours
  * :mins
  * :secs
  * :timestamp

The dates will be compared with the corresponding accuracy. The default granularity is :secs.

```elixir
# Comparing two DateTimes
> date1 = Date.now
> date2 = Date.now |> Date.add(Time.to_timestamp(10, :mins))
> Date.compare(date1, date2)
-1
> Date.compare(date1, date1)
0
> Date.compare(date2, date1)
1

# Comparing a DateTime against reference points
> date = Date.now
> Date.compare(date, :epoch)
1
> date = Date.from({{1969, 1, 1}, {12, 0, 0}})
> Date.compare(date, :epoch)
-1
> Date.compare(date, :zero)
1
> Date.compare(date, :distant_past)
1 # This is always 1
> Date.compare(date, :distant_future)
-1 # This is always -1
```

## Equality

```elixir
> date1 = Date.now
> date2 = Date.now |> Date.add(Time.to_timestamp(10, :mins))
> Date.equal?(date1, date2)
false
> Date.equal?(date1, date1)
true
```

## Ordinal Conversions

### Get day of the year for a given DateTime

```elixir
> Date.now |> Date.day
175
```

### Determine the ordinal day of the week for a given DateTime

```elixir
> Date.now |> Date.weekday
3
```

### Get the name of the day of week based on ordinal number

```elixir
> Date.day_name(1)
"Monday"

# Or the abbreviated name
> Date.day_shortname(1)
"Mon"
```

### Get the ordinal weekday for the given weekday name

```elixir
> Date.day_to_num("Monday")
1
> Date.day_to_num("Mon")
1
> Date.day_to_num(:mon)
1
```

### Get the number of days in the month for a DateTime or year/month combo

```elixir
> Date.now |> Date.days_in_month
30
> Date.days_in_month(2015, 6)
30
```

## Diffs

### Get the difference between two dates in the given units

Valid units are:
    * :timestamp
    * :years
    * :months
    * :weeks
    * :days
    * :hours
    * :mins
    * :secs

```elixir
> date1 = Date.from({{1970, 1, 1}, {0, 0, 0}})
> date2 = Date.from({{1970, 2, 4}, {12, 5, 5}})
> Date.diff(date1, date2, :timestamp)
{2, 981105, 0}
> Date.diff(date1, date2, :secs)
2981105
> Date.diff(date1, date2, :weeks)
4
```

## Epoch

### Get the Epoch in various forms

```elixir
> Date.epoch
%DateTime{}
> Date.epoch(:timestamp)
{0,0,0}
> Date.epoch(:secs)
62167219200
```

## Constructing DateTimes

### Convert to DateTime from various representations

```elixir
# From date tuple (time is in UTC and set to midnight)
> Date.from({2015, 1, 1})

# From date tuple w/ timezone
> Date.from({2015, 1, 1}, "America/Chicago")

# From date tuple using local timezone
> Date.from({2015, 1, 1}, :local)

# You can do all of the above with datetime tuples, e.x:
> Date.from({{2015, 1, 1}, {4, 0, 0}}, "America/Chicago")

# There is a special datetime tuple containing milliseconds which is also supported
> Date.from({{2015, 1, 1}, {4, 0, 0, 132}}, "America/Chicago")

# Convert from timestamp (assumes timestamp from Epoch)
> Date.from(Time.now, :timestamp)

# Convert from timestamp relative to year zero
> Date.from(Time.now, :timestamp, :zero)

# Convert from microseconds, seconds or days from Epoch or year zero
> Date.from(1000, :us)
> Date.from(1000, :secs)
> Date.from(1000, :days)
> Date.from(1000, :days, :zero)
```

### Convert to DateTime from ISO triplet (year, weeknumber, weekday)

```elixir
> Date.from_iso_triplet({2015, 3, 5})
%DateTime{calendar: :gregorian, day: 17, hour: 0, minute: 0, month: 1,
 ms: 0, second: 0,
 timezone: %TimezoneInfo{...}, year: 2015}
```

## Leap Years

Determine if the given year is a leap year

```elixir
> Date.is_leap?(2012)
true
> Date.is_leap?(2015)
false
```

## Validation

Determine if the given DateTime represents a valid point in time

```elixir
> Date.now |> Date.is_valid?
true
> %DateTime{year: -1} |> Date.is_valid?
false
```

## ISO Conversions

### Convert from ISO day of the year to DateTime

```elixir
> 175 |> Date.from_iso_day
%DateTime{calendar: :gregorian, day: 25, hour: 0, minute: 0, month: 6,
 ms: 0, second: 0,
 timezone: %TimezoneInfo{...}, year: 2015}

# You can also shift a date to the given ISO day, which will preserve the timezone (unless a transition is required) and time information.
> date = Date.now
> Date.from_iso_day(120, date)
```

### Get the ISO triplet (year, week number, week day) from a DateTime

```elixir
> Date.now |> Date.iso_triplet
{2015, 26, 3}
```

### Get the ISO week number from a DateTime

```elixir
> Date.now |> Date.iso_week
{2015, 26}
```

### Get the name of the month corresponding to its ordinal number

```elixir
> Date.month_name(3)
"March"
> Date.month_shortname(3)
"Mar"
```

### Convert a month name to its ordinal number

```elixir
> Date.month_to_num("March")
3
> Date.month_to_num("Mar")
3
> Date.month_to_num(:mar)
3
```

## Normalization

Take unvalidated input, normalize it to ensure all the components are clamped to valid values, and convert to a DateTime

```elixir
> {{-1,3,5}, {26,60,60}} |> Date.normalize
%DateTime{calendar: :gregorian, day: 5, hour: 23, minute: 59, month: 3,
 ms: 0, second: 59,
 timezone: %TimezoneInfo{...}, year: 0}
```

## Manipulation

### Set components of a DateTime manually

Returns a new date with the specified fields replaced by new values.

Values are automatically validated and clamped to good values by default. If you wish to skip validation, perhaps for performance reasons, pass `validate: false`.

Values are applied in order, so if you pass `[datetime: dt, date: d]`, the date value from `date` will override `datetime`'s date value.

```elixir
# Set components of the DateTime, `date` allows you to set all date components easily
> Date.now |> Date.set(date: {1,1,1})
> Date.now |> Date.set(hour: 0)
> Date.now |> Date.set([date: {1,1,1}, hour: 30])

# `datetime` is like `date`, but includes time components
# order matters though, in this case `date` will override the date component of `datetime`
> Date.now |> Date.set([datetime: {{1,1,1}, {0,0,0}}, date: {2,2,2}])

# You can disable validation, but be careful
> Date.now |> Date.set([minute: 74, validate: false])
```

## Timezones

### Get the Timezone for a moment in time

```elixir
# For the current time
> Date.timezone("America/Chicago")
# For a specific time
> Date.epoch |> Date.timezone("Europe/Cophenhagen")
```

## Relative Conversions

### Convert a DateTime to number of days since Epoch/Year Zero

```elixir
> Date.to_days(Date.now) # From Epoch
> Date.to_days(Date.now, :zero)
```

### Convert a DateTime to number of seconds since Epoch/Year Zero

```elixir
> Date.to_secs(Date.now) # From Epoch
> Date.to_secs(Date.now, :zero)
```

### Convert a DateTime to a timestamp relative to Epoch/Year Zero

```elixir
> Date.to_timestamp(Date.now) # From Epoch
> Date.to_timestamp(Date.now, :zero)
```
