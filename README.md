## Timex

[![Master](https://travis-ci.org/bitwalker/timex.svg?branch=master)](https://travis-ci.org/bitwalker/timex)
[![Hex.pm Version](http://img.shields.io/hexpm/v/timex.svg?style=flat)](https://hex.pm/packages/timex)
[![InchCI](https://inch-ci.org/github/bitwalker/timex.svg?branch=master)](https://inch-ci.org/github/bitwalker/timex)
[![Coverage Status](https://coveralls.io/repos/github/bitwalker/timex/badge.svg?branch=master)](https://coveralls.io/github/bitwalker/timex?branch=master)

Timex is a rich, comprehensive Date/Time library for Elixir projects, with full timezone support via the `:tzdata` package. If
you need to manipulate dates, times, datetimes, timestamps, etc., then Timex is for you! It is very easy to use Timex types
in place of default Erlang types, as well as Ecto types via the `timex_ecto` package.

The complete documentation for Timex is located [here](https://hexdocs.pm/timex).

## Migrating to Timex 2.x

See the Migrating section further down for details.

## Getting Started

There are some brief examples on usage below, but I highly recommend you review the
API docs [here](https://hexdocs.pm/timex), there are many examples, and some extra pages with
richer documentation on specific subjects such as custom formatters/parsers, etc.

### Adding Timex To Your Project

To use Timex with your projects, edit your `mix.exs` file and add it as a dependency:

```elixir
defp deps do
  [{:timex, "~> x.x.x"}]
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
> date = Date.today
%Date{year: 2016, month: 2, day: 29}

> datetime = DateTime.today
%DateTime{year: 2016, month: 2, day: 29,
          hour: 12, minute: 30, second: 30, millisecond: 120, timezone: %TimezoneInfo{...}}

> timestamp = Time.now
{1457, 137754, 906908}

> {:ok, default_str} = Timex.format(datetime, "{ISO:Extended}")
{:ok, "2016-02-29T12:30:30.120+00:00"}

> {:ok, strftime_str} = Timex.format(datetime, "%FT%T%:z", :strftime)
{:ok, "2016-02-29T12:30:30+00:00"}

> Timex.parse(default_str, "{ISO:Extended}")
{:ok, %DateTime{...}}

> Timex.parse(strftime_str, "%FT%T%:z", :strftime)
{:ok, %DateTime{...}}

> Time.diff(Time.now, Time.zero, :days)
16850

> Timex.shift(date, days: 3)
%Date{year: 2016, month: 3, day: 3}

> Timex.shift(date, hours: 2, minutes: 13)
%DateTime{year: 2016, month: 2, day: 29,
          hour: 14, minute: 43, second: 30, millisecond: 120, timezone: %TimezoneInfo{...}}

> timezone = Timex.timezone("America/Chicago", DateTime.today)
%Timex.TimezoneInfo{abbreviation: "CST",
 from: {:sunday, {{2015, 11, 1}, {1, 0, 0}}}, full_name: "America/Chicago",
 offset_std: 0, offset_utc: -360, until: {:sunday, {{2016, 3, 13}, {2, 0, 0}}}}

> Timezone.convert(datetime, timezone)
%DateTime{year: 2016, month: 2, day: 29,
          hour: 6, minute: 30, second: 30, millisecond: 120,
          timezone: %TimezoneInfo{abbreviation: "CST", ...}}

> Timex.equal?(Date.today, DateTime.today)
true

> Timex.before?(Date.today, Timex.shift(Date.today, days: 1))
true
```

There are a ton of other functions for Dates, Times, and DateTimes, way more than can be covered here. Hopefully the above
gives you a taste of what the API is like!

## Extensibility

Timex exposes a number of extension points for you, in order to accomodate different use cases:

You can use custom Date/DateTime types with Timex via the `Timex.Convertable` protocol, which gives you a way to convert your type to various Timex types, and then use the Timex API to manipulate them, for example, you could use the Calendar library's types with Timex via Comparable, or Ecto's, or your own!

You can compare/diff custom Date/DateTime types with Timex via the `Timex.Comparable` protocol, which also understands types which implement `Timex.Convertable`, allowing you to use Comparable as soon as you've implemented Convertable!

The same is true for Timex's API in general - if you pass a type which implements `Timex.Convertable`, and the type is not a native Timex one, it will be coerced to one via that protocol.

You can provide your own formatter/parser for Date/DateTime strings by implementing the `Timex.Format.DateTime.Formatter` and/or `Timex.Parse.DateTime.Parser` behaviours, depending on your needs.

## Common Issues

**Warning**: Timex functions of the form `iso_*` behave based on how the ISO calendar represents dates/times and not the ISO8601 date format. This confusion has occured before, and it's important to note this!

- If you need to use Timex from within an escript, add `{:tzdata, "~> 0.1.8", override: true}` to your deps,
  more recent versions of :tzdata are unable to work in an escript because of the need to load ETS table files
  from priv, and due to the way ETS loads these files, it's not possible to do so.

## Migrating

If you have been using Timex pre-2.x, and you are looking to migrate, it's fairly painless, but important to review the list of breaking
changes and new features.

### Overview of 2.x changes

Please see the `CHANGELOG.md` file for the list of all changes made, below are a brief recap of the major points, and
instructions on how to migrate your existing Timex-based code to 2.x. I promise it's easy!

- There are now three date types: `Date`, `DateTime`, and `AmbiguousDateTime`. The first two are pretty obvious, but to recap:
  - If you are working with dates and don't care about time information - use `Date`
  - For everything else, use `DateTime`
  - `AmbiguousDateTime` is returned in cases where timezone information is ambiguous for a given point in time. The struct
    has two fields `before` and `after`, containing `DateTime` structs to choose from, based on what your intent is. It is up
    to you to choose one, or raise an error if you aren't sure what do to.
- To accompany `AmbiguousDateTime` there is also `AmbiguousTimezoneInfo`, which is almost the same thing, except it's fields contain
  `TimezoneInfo` structs to choose from. This one is used mostly internally, but if you use `Timezone.get`, you'll need to plan for this.
- All functions which are not specific to a given date type, are now found under the Timex module itself, all functions which
  are shared or common between `Date` and `DateTime` can also be found under `Timex` and it will delegate to the appropriate module,
  this should make it easier to use `Date` and `DateTime` together without having to remember which API to call for a specific value,
  Timex will just do the right thing for you.
- `Timex.Date` and `Timex.DateTime` expose APIs specific to those types, `Timex.DateTime` is effectively the older API you are familiar with from pre-2.x Timex. **Timex.Date is no longer the main API module, use Timex**
- Date/DateTime formatting and parsing APIs are exposed via the `Timex` module, but the old formatter and parser modules are still there,
**the exception being DateFormat, which has been removed, if you were using it, change to Timex**.
- Date/DateTime/Erlang datetime tuple/etc. common conversions are now exposed via the `Timex.Convertable` protocol. Implementations for those types are already included. **Timex.Date.Convert is removed, as well as the DateConvert alias, use Timex.Convertable instead**

There was a significant amount of general project improvements done as part of this release as well:

- Shifting dates/times is now far more accurate, and more flexible than it was previously,
  shifting across leaps, timezone changes, and non-existent time periods are now all fully supported
- The API does a much better job of validation and is strict about inputs, and because all APIs now return
  error tuples instead of raising exceptions, it is much easier to handle gracefully.
- The code has been reorganized into a more intuitive structure
- Fixed typespecs, docs, and tests across the board
- Almost 100 more tests, with more to come
- Cleaned up dirty code along the way (things like single-piping, inconsistent parens, etc.)


### Migration steps (1.x -> 2.x)

Depending on how heavily you are using the various features of Timex's API, the migration can be anywhere from 15 minutes to a couple of hours, but the steps below are a guide which should help the process go smoothly. For the vast majority of folks, I anticipate that it will be a very small time investment.

1. Change all `Timex.Date` references to `Timex`, except those which are creating `DateTime` values, such as `Date.now`, those references should be changed to point to `DateTime` now.
2. Change all `DateFormat` references to `Timex`, `DateFormat` was removed.
3. Change all `Timex.Date.Convert` or `DateConvert` references to `Timex` or `Timex.Convertable`, the former have become the latter
4. Make sure you upgrade `timex_ecto` as well if you are using it with your project
5. Compile, if you get warnings about missing methods on `Timex`, they are type-specific functions for `DateTime`,
   so change those references to `Timex.DateTime`
6. You'll need to modify your code to handle error tuples instead of exceptions
7. You'll need to handle the new `AmbiguousDateTime` and `AmbiguousTimezoneInfo` structs, the best approach is to pattern match on API return values, use `DateTime` if it was given, or select `:before` or `:after` values from the `Ambiguous*` structs. Your code will become a lot safer as a result of this change!
8. Unit names are soft-deprecated for now, but you'll want to change references to abbreviated units like `secs` to their full names (i.e. `seconds`) in order to make the stderr warnings go away.

And that's it! If you have any issues migrating, please ping me, and I'll be glad to help. If you have a dependency that uses Timex which you'd like to get updated to 2.x, open an issue here, and I'll submit a PR to those projects to help bring them up to speed quicker.

## Roadmap

The following are an unordered list of things I plan for Timex in the future, if you
have specific requests, please open an issue with "RFC" in the title, and we can discuss
it, and hopefully get input from the community.

- 100% test coverage (well under way!)
- QuickCheck tests (haven't started this, but I really want to start ASAP)
- Locale-aware formatting/parsing (a relatively high priority)
- `{ASP.NET}` formatting/parsing token for interop with .NET services (probably in the next release)
- Relative time formatter/parser, along the lines of Moment.js's `fromNow`, `toNow`, `timeTo`, and `timeFrom` formatting functions.
- Calendar time formatter/parser, along the lines of Moment.js's calendar time formatter
- Richer duration support via the `Interval` module
- Recurring dates/times API
- Support for calendars other than Gregorian (e.g. Julian)

## License

This software is licensed under [the MIT license](LICENSE.md).
