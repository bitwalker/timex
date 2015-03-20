## Timex

[![Master](https://travis-ci.org/bitwalker/timex.svg?branch=master)](https://travis-ci.org/bitwalker/timex)
[![Hex.pm Version](http://img.shields.io/hexpm/v/timex.svg?style=flat)](https://hex.pm/packages/timex)

## Getting Started

To use timex with your projects, edit your mix.exs file and add it as a dependency:

```elixir
defp deps do
  [{:timex, "~> 0.13.4"}]
end
```

To use Timex modules without the Timex namespace, add `use Timex` to the top of each module you plan on referencing Timex from. You can then reference the modules directly, for example: `Date.now()`, versus `Timex.Date.now()`. This is for compatibility with other libraries which might define their own Date/DateTime/Time implementations.

## Overview

The goal of this project is to provide a complete set of Date/Time functionality for Elixir projects, with the hope of being eventually merged into the standard library.

The `Date` module is for dealing with dates, which includes time and timezone information for those dates. It supports getting current date in any time zone, converting between timezones while taking Daylight Savings Time offsets into account, calculating time intervals between two dates, shifting a date by some amount of seconds/hours/days/years towards past and future, etc. As Erlang provides support only for the Gregorian calendar, that's what timex currently supports, but it is possible to add additional calendars if needed.

The `Time` module supports a finer grained level of arithmetic over time intervals. It is intended for use as timestamps in logs, measuring code execution times, converting time units, etc.

## Usage

### Getting current date

Get current date in the local time zone.

```elixir
date = Date.local
DateFormat.format!(date, "{ISO}")      #=> "2013-09-30T16:40:08+0300"
DateFormat.format!(date, "{RFC1123}")  #=> "Mon, 30 Sep 2013 16:40:08 EEST"
DateFormat.format!(date, "%a, %d %m %Y %T %Z", :strftime) #=> "Mon, 30 09 2013 08:40:08 CDT"
DateFormat.format!(date, "%Y", TimexFormatters.Strftime)  #=> "2013"
```

The date value that `Date` produced encapsulates current date, time, and time zone information. This allows for great flexibility without any overhead on the user's part.

Since Erlang's native date format doesn't carry any time zone information, `Date` provides a bunch of constructors that take Erlang's date value and an optional time zone.

```elixir
datetime = {{2013,3,17},{21,22,23}}

date = Date.from(datetime)           # datetime is assumed to be in UTC by default
DateFormat.format!(date, "{RFC1123}")   #=> "Sun, 17 Mar 2013 21:22:23 GMT"

date = Date.from(datetime, "CST")    # With a provided timezone

date = Date.from(datetime, :local)   # indicates that datetime is in local time zone
DateFormat.format!(date, "{RFC1123}")   #=> "Sun, 17 Mar 2013 21:22:23 CST"

Date.local(date)  # convert date to local time zone (CST for our example)
#=> %DateTime{year: 2013, month: 3, day: 17, hour: 15, minute: 22, second: 23, timezone: ...}

# Let's see what happens if we switch the time zone
date = Timezone.convert(date, Timezone.get("EST"))
DateFormat.format!(date, "{RFC1123}")
#=> "Sun, 17 Mar 2013 17:22:23 EST"

Date.universal(date)  # convert date to UTC
#=> %DateTime{year: 2013, month: 3, day: 17, hour: 21, minute: 22, second: 23, timezone: ...}
```

### Working with time zones

```elixir
date = Date.from({2013,1,1}, "America/Chicago")
DateFormat.format!(date, "{ISO}")
#=> "2013-01-01T00:00:00-0600"
DateFormat.format!(date, "{ISOz}")
#=> "2013-01-01T06:00:00Z"

DateFormat.format!(date, "{RFC1123}")
#=> "Tue, 01 Jan 2013 00:00:00 CST"

date = Date.now
# Convert to UTC
Date.universal(date)                        #=> %DateTime{...}
# Convert a date to local time
Date.local(date)                            #=> %DateTime{...}
# Convert a date to local time, and provide the local timezone
Date.local(date, Date.timezone("PST"))      #=> %DateTime{...}
```

### Extracting information about dates

Find out current weekday, week number, number of days in a given month, etc.

```elixir
date = Date.now
DateFormat.format!(date, "{RFC1123}")
#=> "Wed, 26 Feb 2014 06:02:50 GMT"

Date.weekday(date)           #=> 3
Date.iso_week(date)          #=> {2014, 9}
Date.iso_triplet(date)       #=> {2014, 9, 3}

Date.days_in_month(date)     #=> 28
Date.days_in_month(2012, 2)  #=> 29

Date.is_leap?(date)           #=> false
Date.is_leap?(2012)           #=> true

Date.day_to_num(:mon)         #=> 1
Date.day_to_num("Thursday")   #=> 4 (can use Thursday, thursday, Thu, thu, :thu)
Date.day_name(4)              #=> "Thursday"
Date.day_shortname(4)         #=> "Thu"

Date.month_to_num(:apr)       #=> 4 (same as day_to_num with possible formats)
Date.month_name(4)            #=> "April"
Date.month_shortname(4)       #=> "Apr"

```

### Date arithmetic

`Date` can convert dates to time intervals since UNIX epoch or year 0. Calculating time intervals between two dates is possible via the `diff()` function (not implemented yet).

```elixir
date = Date.now
DateFormat.format!(date, "{RFC1123}")
#=> "Mon, 30 Sep 2013 16:55:02 EEST"

Date.convert(date, :secs)  # seconds since Epoch
#=> 1380549302

Date.to_secs(date, :zero)  # seconds since year 0
#=> 63547768502

DateFormat.format!(Date.epoch(), "{ISO}")
#=> "1970-01-01T00:00:00+0000"

Date.epoch(:secs)  # seconds since year 0 to Epoch
#=> 62167219200

date = Date.from(Date.epoch(:secs) + 144, :secs, :zero)  # :zero indicates year 0
DateFormat.format!(date, "{ISOz}")
#=> "1970-01-01T00:02:24Z"
```

### Shifting dates ###

Shifting refers to moving by some amount of time towards past or future. `Date` supports multiple ways of doing this.

```elixir
date = Date.now
DateFormat.format!(date, "{RFC1123}")
#=> "Mon, 30 Sep 2013 16:58:13 EEST"

DateFormat.format!( Date.shift(date, secs: 78), "{RFC1123}" )
#=> "Mon, 30 Sep 2013 16:59:31 EEST"

DateFormat.format!( Date.shift(date, secs: -1078), "{RFC1123}" )
#=> "Mon, 30 Sep 2013 16:40:15 EEST"

DateFormat.format!( Date.shift(date, days: 1), "{RFC1123}" )
#=> "Tue, 01 Oct 2013 16:58:13 EEST"

DateFormat.format!( Date.shift(date, weeks: 3), "{RFC1123}" )
#=> "Mon, 21 Oct 2013 16:58:13 EEST"

DateFormat.format!( Date.shift(date, years: -13), "{RFC1123}" )
#=> "Sat, 30 Sep 2000 16:58:13 EEST"
```

## Formatting Dates

Formatting dates is pretty straightforward using the `DateFormat` module:

```elixir
date = Date.local

# Format the date using the default formatter `TimexFormatters.Default`
DateFormat.format!(date, "{ISO}")      #=> "2013-09-30T16:40:08+0300"

# There are many different preformatted directives, see the formatter docs to get
# a full breakdown of all options and directives available.
DateFormat.format!(date, "{RFC1123}")  #=> "Mon, 30 Sep 2013 16:40:08 EEST"

# Format the date using the strftime formatter `TimexFormatters.Strftime`
DateFormat.format!(date, "%a, %d %m %Y %T %Z", :strftime) #=> "Mon, 30 09 2013 08:40:08 CDT"

# There are shortcuts for timex's formatters (:default and :strftime), but under
# the covers, those shorthand names are being converted to module names. You can
# provide your own formatter implementation by creating a module with the name:
# `Timex.DateFormat.Formatters.<ModuleName>Formatter`, with
# `use Timex.DateFormat.Formatters.Formatter` which extends the `Formatter` behaviour.
# See the docs for `Formatter` for more information.
DateFormat.format!(date, "%Y", TimexFormatters.Strftime)  #=> "2013"
```

## Parsing Dates

Parsing dates is also a breeze with `DateFormat`:

```elixir
# Parse a date using the default parser
gmt   = Date.timezone("GMT")
date  = Date.from({{2013,3,5},{23,25,19}}, gmt)
{:ok, ^date} = DateFormat.parse("Tue, 05 Mar 2013 23:25:19 GMT", "{RFC1123}")

# Any preformatted directive ending in `z` will shift the date to UTC/Zulu
gmt   = Date.timezone("EET")
date  = Date.from({{2013,3,5},{23,25,19}})
{:ok, ^date} = DateFormat.parse("Tue, 05 Mar 2013 23:25:19 +0200", "{RFC1123z}")

# Simple date format, default parser
date = Date.from({2013, 3, 5})
{:ok, ^date} = DateFormat.parse("2013-03-05", "{YYYY}-{0M}-{0D}")

# Simple date format, strftime parser
date = Date.from({2013, 3, 5})
{:ok, ^date} = DateFormat.parse("2013-03-05", "%Y-%m-%d", :strftime)

# Pluggable architecture, just provide your own parser module
# named like `Timex.Parsers.DateFormat.<Name>Parser`, and which
# contains `use Timex.Parsers.DateFormat.Parser` at the top. This
# extends the `Parser` behavior, and will be validated by timex.
date   = Date.from({2013, 3, 5})
phrase = "two days after the third of march, 2013"
format = "{shift} {direction} {day}, {year}"
{:ok, ^date} = DateFormat.parse(phrase, format, MyHumanizedParser)
```

As seen above, like formatting, parsing also offers a plugin architecture. By extending
`Parser`, and giving your custom parser the same namespace as the other parsers, timex
will know that your parser can be used. Parsing is a complex topic, so if you have questions
about it, please open an issue, or take a look at the Default and Strftime parsers. I hope to
cover this topic in more detail in the future, so if you aren't seeing anything, please ping
me!

## Working with Time module

The `Time` module already has some conversions and functionality for measuring time.

```elixir
## Time.now returns time since UNIX epoch

Time.now
#=> {1362,781057,813380}

Time.now(:secs)
#=> 1362781082.040016

Time.now(:msecs)
#=> 1362781088623.741


## Converting units is easy

t = Time.now
#=> {1362,781097,857429}

Time.to_usecs(t)
#=> 1362781097857429.0

Time.to_secs(t)
#=> 1362781097.857429

Time.to_secs(13, :hours)
#=> 46800

Time.to_secs(13, :msecs)
#=> 0.013


## We can also convert from timestamps to other units using a single function

Time.convert(t, :secs)
#=> 1362781097.857429

Time.convert(t, :mins)
#=> 22713018.297623817

Time.convert(t, :hours)
#=> 378550.30496039696


## elapsed() calculates time interval between now and t

Time.elapsed(t)
#=> {0,68,-51450}

Time.elapsed(t, :secs)
#=> 72.100247

t1 = Time.elapsed(t)
#=> {0,90,-339935}


## diff() calculates time interval between two timestamps

Time.diff(t1, t)
#=> {-1362,-781007,-1197364}

Time.diff(Time.now, t)
#=> {0,105,-300112}

Time.diff(Time.now, t, :hours)
#=> 0.03031450388888889
```

### Converting time units

```elixir
dt = Time.now
Time.convert(dt, :secs)
Time.convert(dt, :mins)
Time.convert(dt, :hours)
Time.to_timestamp(13, :secs)
```

## FAQ

**Which functions provide microsecond precision?**

If you need to work with time intervals down to microsecond precision, you should take a look at the functions in the `Time` module. The `Date` module is designed for things like handling different time zones and working with dates separated by large intervals, so the minimum time unit it uses is seconds.

**So how do I work with time intervals defined with microsecond precision?**

Use functions from the `Time` module for time interval arithmetic.

**How do I find the time interval between two dates?**

Use `Date.diff` to obtain the number of seconds, minutes, hours, days, months, weeks, or years between two dates.

**What is the support for time zones?**

Full support for retreiving local timezone configuration on OSX, *NIX, and Windows, conversion to any timezone in the Olson timezone database, and full support for daylight savings time transitions.

Timezone support is also exposed via the `Timezone`, `Timezone.Local`, and `Timezone.Dst` modules. Their functionality is exposed via the `Date` module's API, and most common use cases shouldn't need to access the `Timezone` namespace directly, but it's there if needed.

## License

This software is licensed under [the MIT license](LICENSE.md).
