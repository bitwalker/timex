## Timex

[![Master](https://travis-ci.org/bitwalker/timex.svg?branch=master)](https://travis-ci.org/bitwalker/timex)
[![Hex.pm Version](http://img.shields.io/hexpm/v/timex.svg?style=flat)](https://hex.pm/packages/timex)
[![InchCI](https://inch-ci.org/github/bitwalker/timex.svg?branch=master)](https://inch-ci.org/github/bitwalker/timex)

The full documentation for Timex is located [here](https://timex.readme.io).
API documentation for Timex is located [here](http://hexdocs.pm/timex/0.17.0/).

## Getting Started

Learn how to add Timex to your Elixir project and start using it.

### Adding Timex To Your Project

To use Timex with your projects, edit your `mix.exs` file and add it as a dependency:

```elixir
defp deps do
  [{:timex, "~> x.x.x"}]
end

defp application do
  [applications: [:tzdata]]
end
```

To use Timex modules without the Timex namespace, add `use Timex` to the top of each module you plan on referencing Timex from. You can then reference the modules directly, for example: `Date.now`, versus `Timex.Date.now`. This is for compatibility with other libraries which might define their own Date/DateTime/Time implementations. You can also alias individual modules if that suits your needs better, but for purposes of this documentation, we'll assume that you're going the `use Timex` route.

### What Is Timex

The goal of this project is to provide a complete set of Date/Time functionality for Elixir projects, with the hope of being eventually merged into the standard library.

There are a small set of core modules you'll deal with for most tasks with Timex: `Date`, `Time`, `Timezone`, and `DateFormat`. A brief description of each is below, and they will be covered in more detail on their own pages.

The `Date` module is for creating, manipulating, and converting to/from DateTime structs (which represents a combined date and time + timezone). You can create a date in any timezone in the Olson timezone database, convert an Erlang datetime tuple to a DateTime struct, shift dates in time (which transparently handles timezone transitions), shift them across timezones, and query metadata about datetimes, such as what the ISO week of that date was, etc. You can diff two dates, compare them for sorting, and more.

The `Time` module supports a finer grained level of arithmetic over time intervals. It is intended for use as timestamps in logs, measuring code execution times, converting time units, etc. It does not care about timezones, but is rather used to represent a given moment in time down to the nanosecond.

The `Timezone` module is used primarily for converting a DateTime to a new timezone, fetching a TimezoneInfo struct (which contains metadata about the timezone for a given zone, i.e. "America/Chicago" and point in time), or for determining the offset in minutes betweeen a given DateTime and a target timezone (`Timezone.diff/2`).

The `DateFormat` module is used for formatting DateTimes as strings, and parsing DateTimes from strings. In both cases you provide a format string using one of two different formatters ("default" and "strftime"). This module is extensible, and allows you to implement your own parsers/formatters if desired.

## Basic Usage

Some common scenarios with examples.

### Getting the current datetime in UTC

```elixir
> Date.now
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 45, month: 6,
 ms: 730, second: 8,
 timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
  full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}
```

### Getting the current datetime in the local timezone

```elixir
> Date.local
%DateTime{calendar: :gregorian, day: 23, hour: 23, minute: 45, month: 6,
 ms: 713, second: 58,
 timezone: %TimezoneInfo{abbreviation: "CDT",
  from: {:sunday, {{2015, 3, 8}, {2, 0, 0}}}, full_name: "America/Chicago",
  offset_std: 60, offset_utc: -360,
  until: {:sunday, {{2015, 11, 1}, {1, 0, 0}}}}, year: 2015}
```

### Getting the current datetime in an arbitrary timezone

```elixir
> Date.now("Europe/Copenhagen")
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 ms: 308, second: 34,
 timezone: %TimezoneInfo{abbreviation: "CEST",
  from: {:sunday, {{2015, 3, 29}, {2, 0, 0}}}, full_name: "Europe/Copenhagen",
  offset_std: 60, offset_utc: 60,
  until: {:sunday, {{2015, 10, 25}, {2, 0, 0}}}}, year: 2015}
```

### Constructing a date in UTC

```elixir
> Date.from({{2015, 6, 24}, {4, 50, 34}})
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 ms: 0, second: 34,
 timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
  full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}
```

### Constructing a date in the local timezone

```elixir
> Date.from({{2015, 6, 24}, {4, 50, 34}}, :local)
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 ms: 0, second: 34,
 timezone: %TimezoneInfo{abbreviation: "CDT",
  from: {:sunday, {{2015, 3, 8}, {2, 0, 0}}}, full_name: "America/Chicago",
  offset_std: 60, offset_utc: -360,
  until: {:sunday, {{2015, 11, 1}, {1, 0, 0}}}}, year: 2015}
```

### Constructing a date in an arbitrary timezone

```elixir
> Date.from({{2015, 6, 24}, {4, 50, 34}}, "Europe/Copenhagen")
%DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
 ms: 0, second: 34,
 timezone: %TimezoneInfo{abbreviation: "CEST",
  from: {:sunday, {{2015, 3, 29}, {2, 0, 0}}}, full_name: "Europe/Copenhagen",
  offset_std: 60, offset_utc: 60,
  until: {:sunday, {{2015, 10, 25}, {2, 0, 0}}}}, year: 2015}
```

### Parsing an ISO 8601-formatted DateTime string

```elixir
# With timezone offset
> date = "2015-06-24T04:50:34-0500"
> date |> DateFormat.parse("{ISO}")
{:ok,
 %DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
  ms: 0, second: 34,
  timezone: %TimezoneInfo{abbreviation: "GMT+5", from: :min,
   full_name: "Etc/GMT+5", offset_std: 0, offset_utc: -300, until: :max},
  year: 2015}}

# Without timezone offset
> date = "2015-06-24T04:50:34Z"
> date |> DateFormat.parse("{ISOz}")
{:ok,
 %DateTime{calendar: :gregorian, day: 24, hour: 4, minute: 50, month: 6,
  ms: 0, second: 34,
  timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2015}}
```

### Formatting a DateTime as an ISO 8601 string

```elixir
> Date.local |> DateFormat.format("{ISO}")
{:ok, "2015-06-24T00:04:09.293-0500"}
> Date.local |> DateFormat.format("{ISOz}")
{:ok, "2015-06-24T05:04:13.910Z"}
```

## Erlang Interop

How to work with Erlang datetime and time representations.

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

## FAQ

**Which functions provide microsecond precision?**

If you need to work with time intervals down to microsecond precision, you should take a look at the functions in the `Time` module. The `Date` module is designed for things like handling different time zones and working with dates separated by large intervals, so the minimum time unit it uses is milliseconds.

**So how do I work with time intervals defined with microsecond precision?**

Use functions from the `Time` module for time interval arithmetic.

**How do I find the time interval between two dates?**

Use `Date.diff` to obtain the number of milliseconds, seconds, minutes, hours, days, months, weeks, or years between two dates.

**What is the support for timezones?**

Full support for retrieving local timezone configuration on OSX, *NIX, and Windows, conversion to any timezone in the Olson timezone database, and full support for timezone transitions.

Timezone support is also exposed via the `Timezone`, and `Timezone.Local` modules. Their functionality is also exposed via the `Date` module's API, and most common use cases shouldn't need to access the `Timezone` namespace directly, but it's there if needed.

## License

This software is licensed under [the MIT license](LICENSE.md).
