# Basic Usage

**Some common scenarios with examples**

## Getting Dates/DateTimes

### Getting the current datetime in UTC

```elixir
iex> DateTime.now
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 45, month: 6,
 millisecond: 730, second: 8,
 timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
  full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}

iex> Date.today
%Date{calendar: :gregorian, day: 24, month: 6, year: 2015}
```

### Getting the current datetime in the local timezone

```elixir
iex> DateTime.local
%DateTime{calendar: :gregorian, day: 23, hour: 23, minute: 45, month: 6,
 millisecond: 713, second: 58,
 timezone: %TimezoneInfo{abbreviation: "CDT",
  from: {:sunday, {{2015, 3, 8}, {2, 0, 0}}}, full_name: "America/Chicago",
  offset_std: 60, offset_utc: -360,
  until: {:sunday, {{2015, 11, 1}, {1, 0, 0}}}}, year: 2015}
```

### Getting the current datetime in an arbitrary timezone

```elixir
iex> DateTime.now("Europe/Copenhagen")
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 millisecond: 308, second: 34,
 timezone: %TimezoneInfo{abbreviation: "CEST",
  from: {:sunday, {{2015, 3, 29}, {2, 0, 0}}}, full_name: "Europe/Copenhagen",
  offset_std: 60, offset_utc: 60,
  until: {:sunday, {{2015, 10, 25}, {2, 0, 0}}}}, year: 2015}
```

## Constructing Dates/DateTimes

### Constructing a date in UTC

```elixir
iex> Timex.date({2015, 6, 24})
%Date{calendar: :gregorian, day: 24, month: 6, year: 2015}

iex> Timex.datetime({{2015, 6, 24}, {4, 50, 34}})
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 millisecond: 0, second: 34,
 timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
  full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}
```

### Constructing a date in the local timezone

```elixir
iex> Timex.datetime({{2015, 6, 24}, {4, 50, 34}}, :local)
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 millisecond: 0, second: 34,
 timezone: %TimezoneInfo{abbreviation: "CDT",
  from: {:sunday, {{2015, 3, 8}, {2, 0, 0}}}, full_name: "America/Chicago",
  offset_std: 60, offset_utc: -360,
  until: {:sunday, {{2015, 11, 1}, {1, 0, 0}}}}, year: 2015}
```

### Constructing a date in an arbitrary timezone

```elixir
iex> Timex.datetime({{2015, 6, 24}, {4, 50, 34}}, "Europe/Copenhagen")
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 millisecond: 0, second: 34,
 timezone: %TimezoneInfo{abbreviation: "CEST",
  from: {:sunday, {{2015, 3, 29}, {2, 0, 0}}}, full_name: "Europe/Copenhagen",
  offset_std: 60, offset_utc: 60,
  until: {:sunday, {{2015, 10, 25}, {2, 0, 0}}}}, year: 2015}
```

## Parsing DateTime strings

### Parsing an ISO 8601-formatted DateTime string

```elixir
# With timezone offset
iex> date = "2015-06-24T04:50:34-05:00"
iex> Timex.parse(date, "{ISO}")
{:ok,
 %DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
  millisecond: 0, second: 34,
  timezone: %TimezoneInfo{abbreviation: "GMT+5", from: :min,
   full_name: "Etc/GMT+5", offset_std: 0, offset_utc: -300, until: :max},
  year: 2015}}

# Without timezone offset
> date = "2015-06-24T04:50:34Z"
> Timex.parse(date, "{ISOz}")
{:ok,
 %DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
  millisecond: 0, second: 34,
  timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}}
```

## Formatting DateTimes

### Formatting a DateTime as an ISO 8601 string

```elixir
> DateTime.local |> Timex.format("{ISO}")
{:ok, "2015-06-24T00:04:09.293-05:00"}
> DateTime.local |> Timex.format("{ISOz}")
{:ok, "2015-06-24T05:04:13.910Z"}
```
