## Timex

[![Master](https://travis-ci.org/bitwalker/timex.svg?branch=master)](https://travis-ci.org/bitwalker/timex)
[![Hex.pm Version](http://img.shields.io/hexpm/v/timex.svg?style=flat)](https://hex.pm/packages/timex)
[![InchCI](https://inch-ci.org/github/bitwalker/timex.svg?branch=master)](https://inch-ci.org/github/bitwalker/timex)
[![Coverage Status](https://coveralls.io/repos/github/bitwalker/timex/badge.svg?branch=master)](https://coveralls.io/github/bitwalker/timex?branch=master)

Timex is a rich, comprehensive Date/Time library for Elixir projects, with full timezone support via the `:tzdata` package. If
you need to manipulate dates, times, datetimes, timestamps, etc., then Timex is for you! It is very easy to use Timex types
in place of default Erlang types, as well as Ecto types via the `timex_ecto` package.

The complete documentation for Timex is located [here](https://hexdocs.pm/timex).

## Migrating to Timex 3.x

See the Migrating section further down for details. If you are migrating from earlier than 2.x,
please review [this migration doc for 1.x to 2.x](https://github.com/bitwalker/timex/tree/2.2.1#migrating).

Timex 3.0 is a significant rewrite, in order to accomodate Elixir 1.3's new Calendar types in a semantically
correct way. The external API is mostly the same, but there are changes, many without deprecations, so please
read the changelog carefully.

## Getting Started

There are some brief examples on usage below, but I highly recommend you review the
API docs [here](https://hexdocs.pm/timex), there are many examples, and some extra pages with
richer documentation on specific subjects such as custom formatters/parsers, etc.

### Adding Timex To Your Project

To use Timex with your projects, edit your `mix.exs` file and add it as a dependency:

```elixir
defp deps do
  [{:timex, "~> 3.0"}]
end

defp application do
  [applications: [:timex]]
end
```

### Quickfast introduction

To use Timex, I recommend you add `use Timex` to the top of the module where you will be working with Timex modules,
all it does is alias common types so you can work with them more comfortably. If you want to see the specific aliases
added, check the top of the `Timex` module, in the `__using__/1` macro definition.

Here's a few simple examples:

```elixir
> use Timex
> Timex.today
~D[2016-02-29]

> datetime = Timex.now
#<DateTime(2016-02-29T12:30:30.120+00:00Z Etc/UTC)

> Timex.now("America/Chicago")
#<DateTime(2016-02-29T06:30:30.120-06:00 America/Chicago)

> Duration.now
#<Duration(P46Y6M24DT21H57M33.977711S)>

> {:ok, default_str} = Timex.format(datetime, "{ISO:Extended}")
{:ok, "2016-02-29T12:30:30.120+00:00"}

> strftime_str = Timex.format!(datetime, "%FT%T%:z", :strftime)
"2016-02-29T12:30:30+00:00"

> Timex.parse(default_str, "{ISO:Extended}")
{:ok, #<DateTime(2016-02-29T12:30:30.120+00:00 Etc/Utc)}

> Timex.parse!(strftime_str, "%FT%T%:z", :strftime)
#<DateTime(2016-02-29T12:30:30.120+00:00 Etc/Utc)

> Duration.diff(Duration.now, Duration.zero, :days)
16850

> Timex.shift(date, days: 3)
~D[2016-03-03]

> Timex.shift(datetime, hours: 2, minutes: 13)
#<DateTime(2016-02-29T14:43:30.120Z Etc/UTC)>

> timezone = Timezone.get("America/Chicago", Timex.now)
#<TimezoneInfo(America/Chicago - CDT (-06:00:00))>

> Timezone.convert(datetime, timezone)
#<DateTime(2016-02-29T06:30:30.120-06:00 America/Chicago)>

> Timex.before?(Timex.today, Timex.shift(Timex.today, days: 1))
true

> Timex.before?(Timex.shift(Timex.today, days: 1), Timex.today)
true
```

There are a ton of other functions, all of which work with Erlang datetime tuples, Date, NaiveDateTime, and DateTime. The Duration module contains functions for working with Durations, including Erlang timestamps (such as those returned from `:timer.tc`)

## Extensibility

Timex exposes a number of extension points for you, in order to accomodate different use cases:

Timex itself defines it's core operations on the Date, DateTime, and NaiveDateTime types using the `Timex.Protocol` protocol. From there, all other Timex functionality is derived. If you have custom date/datetime types you want to use with Timex, this is the protocol you would need to implement.

Timex also defines a `Timex.Comparable` protocol, which you can extend to add comparisons to custom date/datetime types.

You can provide your own formatter/parser for datetime strings by implementing the `Timex.Format.DateTime.Formatter` and/or `Timex.Parse.DateTime.Parser` behaviours, depending on your needs.

## Common Issues

**Warning**: Timex functions of the form `iso_*` behave based on how the ISO calendar represents dates/times and not the ISO8601 date format. This confusion has occured before, and it's important to note this!

- If you need to use Timex from within an escript, add `{:tzdata, "~> 0.1.8", override: true}` to your deps,
  more recent versions of :tzdata are unable to work in an escript because of the need to load ETS table files
  from priv, and due to the way ETS loads these files, it's not possible to do so.

## Migrating

If you have been using Timex pre-3.x, and you are looking to migrate, it will be fairly painless as long as you review the `CHANGELOG.md` file and make note of anything that has changed which you are using. In almost every single case, the functionality has simply moved, or is accessed slightly differently. In some cases behaviour has changed, but the old behaviour can be acheived manually. For those things which were removed or are no longer available, it is almost certainly because those things are no longer recommended, or no longer make sense for this library. If I have missed something, or there is a good justification for re-adding something which was removed, I'm always open to discussing it on the issue tracker.

### Overview of 3.x changes

Please see the `CHANGELOG.md` file for the list of all changes made, below are a brief recap of the major points, and
instructions on how to migrate your existing Timex-based code to 3.x.

- Virtually all of Timex's API is consolidated around three modules: `Timex`, `Duration`, and `Interval`. There are public APIs in other modules of course, but most everything you do can be done via one of those three.
- All Timex-provided types have been removed, with the exception of `Time` which has been renamed to `Duration` to better fit it's purpose,
`TimezoneInfo`, which is still used internally, and accessible externally, and `AmbiguousDateTime`, which is still required when dealing with ambiguous `DateTime` structs. `Date` and `DateTime` are now part of Elixir 1.3, and `NaiveDateTime` has been added as a first class type as well.
- Conversions have been rehashed, and are now accessed via the `Timex` module: `to_date`, `to_datetime`, `to_naive_datetime`, `to_erl`, `to_unix`, `to_gregorian_seconds`, and `to_gregorian_microseconds`. Use these to convert back and forth between types. With very few exceptions, there are no `from_*` conversions. You must construct a standard type either with the standard library functions (such as `NaiveDateTime.new`), or by converting from another standard type (i.e. Erlang datetime tuple to NaiveDateTime).

A variety of improvements came about as well:

- Microsecond precision everywhere it can be maintained
- Various bug fixes from the 2.x release which were held back
- A lot of code clean up
- Faster compilation
- Fixed typespecs, docs, and tests across the board
- Added Julian calendar support


## Roadmap

The following are an unordered list of things I plan for Timex in the future, if you
have specific requests, please open an issue with "RFC" in the title, and we can discuss
it, and hopefully get input from the community.

- 100% test coverage (well under way!)
- QuickCheck tests (haven't started this, but I really want to start ASAP)
- `{ASP.NET}` formatting/parsing token for interop with .NET services (probably in the next release)
- Relative time formatter/parser, along the lines of Moment.js's `fromNow`, `toNow`, `timeTo`, and `timeFrom` formatting functions.
- Calendar time formatter/parser, along the lines of Moment.js's calendar time formatter
- Recurring dates/times API

## License

This software is licensed under [the MIT license](LICENSE.md).
