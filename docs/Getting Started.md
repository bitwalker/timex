# Getting Started

**Learn how to add timex to your Elixir project and start using it.**

## Project Setup

To use Timex with your projects, edit your `mix.exs` file and add it as a dependency, as well as add `:tzdata` to your applications list.

```elixir
def application do
  [applications: [:tzdata]]
end

defp deps do
  [{:timex, "~> x.x.x"}]
end
```

To use Timex modules without the Timex namespace, add `use Timex` to the top of each module you plan on referencing Timex from. You can then reference the modules directly, for example: `Date.now`, versus `Timex.Date.now`. This is for compatibility with other libraries which might define their own Date/DateTime/Time implementations. You can also alias individual modules if that suits your needs better, but for purposes of this documentation, we'll assume that you're going the `use Timex` route.

## What Is Timex

The goal of this project is to provide a complete set of Date/Time functionality for Elixir projects, with the hope of being eventually merged into the standard library.

There are a small set of core modules you'll deal with for most tasks with Timex: `Date`, `Time`, `Timezone`, and `DateFormat`. A brief description of each is below, and they will be covered in more detail on their own pages.

The `Date` module is for creating, manipulating, and converting to/from DateTime structs (which represents a combined date and time + timezone). You can create a date in any timezone in the Olson timezone database, convert an Erlang datetime tuple to a DateTime struct, shift dates in time (which transparently handles timezone transitions), shift them across timezones, and query metadata about datetimes, such as what the ISO week of that date was, etc. You can diff two dates, compare them for sorting, and more.

The `Time` module supports a finer grained level of arithmetic over time intervals. It is intended for use as timestamps in logs, measuring code execution times, converting time units, etc. It does not care about timezones, but is rather used to represent a given moment in time down to the nanosecond.

The `Timezone` module is used primarily for converting a DateTime to a new timezone, fetching a TimezoneInfo struct (which contains metadata about the timezone for a given zone, i.e. "America/Chicago" and point in time), or for determining the offset in minutes betweeen a given DateTime and a target timezone (`Timezone.diff/2`).

The `DateFormat` module is used for formatting DateTimes as strings, and parsing DateTimes from strings. In both cases you provide a format string using one of two different formatters ("default" and "strftime"). This module is extensible, and allows you to implement your own parsers/formatters if desired.
