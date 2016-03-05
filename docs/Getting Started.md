# Getting Started

**Learn how to add timex to your Elixir project and start using it.**

If you are looking for a general reference of what functions are available to you, take a
look at the `Timex`, `Timex.Date`, `Timex.DateTime`, and `Timex.Time` modules, as they cover
the vast majority of functionality you will care about. The other modules, and even some functions
in Date and DateTime are there to support the main API as accessed via the `Timex` module.

## Project Setup

To use Timex with your projects, edit your `mix.exs` file and add it as a dependency, as well as add `:tzdata` to your applications list.

```elixir
def application do
  [applications: [:timex]]
end

defp deps do
  [{:timex, "~> x.x.x"}]
end
```

To use Timex modules without the Timex namespace, add `use Timex` to the top of each module you plan on referencing Timex from. You can then reference the modules directly, for example: `DateTime.now`, versus `Timex.DateTime.now`. This is for compatibility with other libraries which might define their own Date/DateTime/Time implementations. You can also alias individual modules if that suits your needs better, but for purposes of this documentation, we'll assume that you're going the `use Timex` route.

### What Is Timex

Timex aims to be the richest, most comprehensive date/time library for Elixir projects, with the ultimate goal of being merged into the standard library, if such functionality is ever considered for inclusion.

A rough list of current features:

- create datetimes in an arbitrary timezone
- create datetimes from Erlang dates or datetimes
- get dates/datetimes representing special points in time:
  - end/beginning of year
  - end/beginning of quarter
  - end/beginning of month
  - end/beginning of week
  - end/beginning of day
- convert to/from dates/datetimes in various units (seconds, minutes, hours, etc.) since year zero or UNIX epoch
- convert to/from dates/datetimes in various standard ISO forms:
  - ISO triplets
  - ISO day
  - ISO week
- convert to/from dates/datetimes in various formats:
  - gregorian
  - gregorian_seconds
  - Erlang dates or datetimes
  - UNIX timestamps
- shift datetimes across timezones
- shift dates/datetimes through time using various units
- format/parse datetime strings
- compare and diff dates/datetimes
- normalize dates/datetimes
- create intervals between points in time which can be enumerated
- create timestamps and convert them to other time units
- compare and diff timestamps and various time units
- measure execution time of a function
- add and subtract time or datetimes
- and more..
