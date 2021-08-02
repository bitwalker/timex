## Timex

[![Master](https://github.com/bitwalker/timex/workflows/elixir/badge.svg?branch=master)](https://github.com/bitwalker/timex/actions?query=workflow%3A%22elixir%22+branch%3Amaster)
[![Hex.pm Version](https://img.shields.io/hexpm/v/timex.svg?style=flat)](https://hex.pm/packages/timex)
[![Coverage Status](https://coveralls.io/repos/github/bitwalker/timex/badge.svg?branch=master)](https://coveralls.io/github/bitwalker/timex?branch=master)

Timex is a rich, comprehensive Date/Time library for Elixir projects, with full timezone support via the `:tzdata` package. If
you need to manipulate dates, times, datetimes, timestamps, etc., then Timex is for you! It is very easy to use Timex types
in place of default Erlang types, as well as Ecto types via the `timex_ecto` package.

The complete documentation for Timex is located [here](https://hexdocs.pm/timex).

## Migrating to Timex 3.x

If you are coming from an earlier version of Timex, it is recommended that you evaluate whether or not the functionality provided
by the standard library `Calendar` API is sufficient for your needs, as you may be able to avoid the dependency entirely.

For those that require Timex for one reason or another, Timex now delegates to the standard library where possible, and provides
backward compatibility to Elixir 1.8 for APIs which are used. This is to avoid duplicating effort, and to ease the maintenance of
this library in the future. Take a look at the documentation to see what APIs are available and how to use them. Many of them may have
changed, been removed/renamed, or have had their semantics improved since early versions of the library, so if you are coming from
an earlier version, you will need to review how you are using various APIs. The CHANGELOG is a helpful document to sort through what
has changed in general.

Timex is primarily oriented around the Olson timezone database, and so you are encouraged to use those timezones in favor of alternatives. 
Timex does provide compatibility with the POSIX-TZ standard, which allows specification of custom timezones, see 
[this document](https://pubs.opengroup.org/onlinepubs/9699919799/) for more information. Timex does not provide support
for timezones which do not adhere to one of those two standards. While Timex attempted to support timezone abbreviations without context
in prior versions, this was broken, and has been removed.

## Getting Started

There are some brief examples on usage below, but I highly recommend you review the
API docs [here](https://hexdocs.pm/timex), there are many examples, and some extra pages with
richer documentation on specific subjects such as custom formatters/parsers, etc.

### Quickfast introduction

To use Timex, I recommend you add `use Timex` to the top of the module where you will be working with Timex modules,
all it does is alias common types so you can work with them more comfortably. If you want to see the specific aliases
added, check the top of the `Timex` module, in the `__using__/1` macro definition.

Here's a few simple examples:

```elixir
> use Timex
> Timex.today()
~D[2016-02-29]

> datetime = Timex.now()
#<DateTime(2016-02-29T12:30:30.120+00:00Z Etc/UTC)

> Timex.now("America/Chicago")
#<DateTime(2016-02-29T06:30:30.120-06:00 America/Chicago)

> Duration.now()
#<Duration(P46Y6M24DT21H57M33.977711S)>

> {:ok, default_str} = Timex.format(datetime, "{ISO:Extended}")
{:ok, "2016-02-29T12:30:30.120+00:00"}

> {:ok, relative_str} = Timex.shift(datetime, minutes: -3) |> Timex.format("{relative}", :relative)
{:ok, "3 minutes ago"}

> strftime_str = Timex.format!(datetime, "%FT%T%:z", :strftime)
"2016-02-29T12:30:30+00:00"

> Timex.parse(strftime_str, "{ISO:Extended}")
{:ok, #<DateTime(2016-02-29T12:30:30.120+00:00 Etc/Utc)}

> Timex.parse!(strftime_str, "%FT%T%:z", :strftime)
#<DateTime(2016-02-29T12:30:30.120+00:00 Etc/Utc)

> Duration.diff(Duration.now(), Duration.zero(), :days)
16850

> Timex.shift(date, days: 3)
~D[2016-03-03]

> Timex.shift(datetime, hours: 2, minutes: 13)
#<DateTime(2016-02-29T14:43:30.120Z Etc/UTC)>

> timezone = Timezone.get("America/Chicago", Timex.now())
#<TimezoneInfo(America/Chicago - CDT (-06:00:00))>

> Timezone.convert(datetime, timezone)
#<DateTime(2016-02-29T06:30:30.120-06:00 America/Chicago)>

> Timex.before?(Timex.today(), Timex.shift(Timex.today, days: 1))
true

> Timex.before?(Timex.shift(Timex.today(), days: 1), Timex.today())
false

> interval = Timex.Interval.new(from: ~D[2016-03-03], until: [days: 3])
%Timex.Interval{from: ~N[2016-03-03 00:00:00], left_open: false,
 right_open: true, step: [days: 1], until: ~N[2016-03-06 00:00:00]}

> ~D[2016-03-04] in interval
true

> ~N[2016-03-04 00:00:00] in interval
true

> ~N[2016-03-02 00:00:00] in interval
false

> Timex.Interval.overlaps?(Timex.Interval.new(from: ~D[2016-03-04], until: [days: 1]), interval)
true

> Timex.Interval.overlaps?(Timex.Interval.new(from: ~D[2016-03-07], until: [days: 1]), interval)
false

```

There are a ton of other functions, all of which work with Erlang datetime tuples, Date, NaiveDateTime, and DateTime. 
The Duration module contains functions for working with Durations, including Erlang timestamps (such as those returned from `:timer.tc`)

## Extensibility

Timex exposes a number of extension points for you, in order to accommodate different use cases:

Timex itself defines it's core operations on the Date, DateTime, and NaiveDateTime types using the `Timex.Protocol` protocol. 
From there, all other Timex functionality is derived. If you have custom date/datetime types you want to use with Timex, 
this is the protocol you would need to implement.

Timex also defines a `Timex.Comparable` protocol, which you can extend to add comparisons to custom date/datetime types.

You can provide your own formatter/parser for datetime strings by implementing the `Timex.Format.DateTime.Formatter` 
and/or `Timex.Parse.DateTime.Parser` behaviours, depending on your needs.

### Timex with escript

If you need to use Timex from within an escript, add `{:tzdata, "~> 0.1.8", override: true}` to your deps, more recent versions of :tzdata are unable to work in an escript because of the need to load ETS table files from priv, and due to the way ETS loads these files, it's not possible to do so.

If your build still throws an error after this, try removing the `_build` and `deps` folder. Then execute `mix deps.unlock tzdata` and `mix deps.get`.

### Automatic time zone updates

Timex includes the [Tzdata](https://github.com/lau/tzdata) library for time zone data.
Tzdata has an automatic update capability that fetches updates from IANA and which is enabled by default; 
if you want to disable it, check [the Tzdata documentation](https://github.com/lau/tzdata#automatic-data-updates) for details.

## License

This software is licensed under [the MIT license](LICENSE.md).
