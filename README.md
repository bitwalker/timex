Date & Time modules for Elixir
==============================

A draft implementation of date and time functionality based on **Idea #6** from this [proposal page](https://github.com/beamcommunity/beamcommunity.github.com/wiki/Project:-Elixir).

## Status ##

[![wercker status](https://app.wercker.com/status/a77f83a04ae1006c9ee44f61a1a147a0/m/ "wercker status")](https://app.wercker.com/project/bykey/a77f83a04ae1006c9ee44f61a1a147a0)

The API for `Date` is relatively stable at this point.

The `Time` module is more prone to change, but likely won't change too drastically moving forward.

To add this library to your project, edit your mix.exs file so that it looks similar to this:

```elixir
defp deps do
  [{:timex, github: "bitwalker/timex"}]
end
```

After that, run `mix deps.get` and start using `Date` functions in your project's code.


## Overview ##

This is a draft implementation of two modules for Elixir that are going to deal with all aspects of working with dates and time intervals.

Basically, the `Date` module is for dealing with dates. It supports getting current date in any time zone, calculating time intervals between two dates, shifting a date by some amount of seconds/hours/days/years towards past and future. As Erlang provides support only for the Gregorian calendar, that's what I'm going to stick to for the time being.

Support for working with time zones is not finalized. Although there is no time zone database yet, you may create time zones by manually specifying offset and name and it'll work correctly, i.e. you'll be able to convert between time zones, format dates to strings, etc.

The `Time` module supports a finer grain level of calculations over time intervals. It is going to be used for timestamps in logs, measuring code executions times, converting time units, and so forth.

## Use cases ##

In all of the examples below, [DateFmt][elixir-datefmt] is used for formatting.

### Getting current date ###

Get current date in the local time zone.

```elixir
date = Date.now()
DateFmt.format!(date, "{ISO}")      #=> "2013-09-30T16:40:08+0300"
DateFmt.format!(date, "{RFC1123}")  #=> "Mon, 30 Sep 2013 16:40:08 EEST"
DateFmt.format!(date, "{kitchen}")  #=> "4:40PM"
```

The date value that `Date` produced encapsulates current date, time, and time zone information. This allows for great flexibility without any overhead on the user's part.

Since Erlang's native date format doesn't carry any time zone information, `Date` provides a bunch of constructors that take Erlang's date value and an optional time zone.

```elixir
datetime = {{2013,3,17},{21,22,23}}

date = Date.from(datetime)           # datetime is assumed to be in UTC by default
DateFmt.format!(date, "{RFC1123}")   #=> "Sun, 17 Mar 2013 21:22:23 GMT"

date = Date.from(datetime, :local)   # indicates that datetime is in local time zone
DateFmt.format!(date, "{RFC1123}")   #=> "Sun, 17 Mar 2013 21:22:23 EEST"

Date.local(date)  # convert date to local time zone
#=> {{2013,3,17},{21,22,23}}

# Let's see what happens if we switch the time zone
date = Date.set(date, tz: { -8, "PST" })
DateFmt.format!(date, "{RFC1123}")
#=> "Sun, 17 Mar 2013 10:22:23 PST"

Date.universal(date)  # convert date to UTC
#=> {{2013,3,17},{18,22,23}}
```

### Working with time zones ###

Currently, we need to build time zones by hand. The functions in `Date` are already respecting time zone offsets when doing calculations. Time zone names are used by `DateFmt` during formatting.

```elixir
date = Date.from({2013,1,1}, Date.timezone(5, "SomewhereInRussia"))
DateFmt.format!(date, "{ISO}")
#=> "2013-01-01T00:00:00+0500"
DateFmt.format!(date, "{ISOz}")
#=> "2012-12-31T19:00:00Z"

DateFmt.format!(date, "{RFC1123}")
#=> "Tue, 01 Jan 2013 00:00:00 SomewhereInRussia"

date = Date.now()
Date.universal(date)                        #=> {{2013,3,17},{19,37,39}}
Date.local(date)                            #=> {{2013,3,17},{21,37,39}}
Date.local(date, Date.timezone(-8, "PST"))  #=> {{2013,3,17},{11,37,39}}
```

### Extracting information about dates ###

Find out current weekday, week number, number of days in a given month, etc.

```elixir
date = Date.now()
DateFmt.format!(date, "{RFC1123}")
#=> "Mon, 30 Sep 2013 16:51:02 EEST"

Date.weekday(date)           #=> 1
Date.weeknum(date)           #=> {2013, 40}
Date.iso_triplet(date)       #=> {2013, 40, 1}

Date.days_in_month(date)     #=> 30
Date.days_in_month(2012, 2)  #=> 29

Date.is_leap(date)           #=> false
Date.is_leap(2012)           #=> true
```

### Date arithmetic ###

`Date` can convert dates to time intervals since UNIX epoch or year 0. Calculating time intervals between two dates is possible via the `diff()` function (not implemented yet).

```elixir
date = Date.now()
DateFmt.format!(date, "{RFC1123}")
#=> "Mon, 30 Sep 2013 16:55:02 EEST"

Date.convert(date, :sec)  # seconds since Epoch
#=> 1380549302

Date.to_sec(date, :zero)  # seconds since year 0
#=> 63547768502

DateFmt.format!(Date.epoch(), "{ISO}")
#=> "1970-01-01T00:00:00+0000"

Date.epoch(:sec)  # seconds since year 0 to Epoch
#=> 62167219200

date = Date.from(Date.epoch(:sec) + 144, :sec, :zero)  # :zero indicates year 0
DateFmt.format!(date, "{ISOz}")
#=> "1970-01-01T00:02:24Z"
```

### Shifting dates ###

Shifting refers to moving by some amount of time towards past or future. `Date` supports multiple ways of doing this.

```elixir
date = Date.now()
DateFmt.format!(date, "{RFC1123}")
#=> "Mon, 30 Sep 2013 16:58:13 EEST"

DateFmt.format!( Date.shift(date, sec: 78), "{RFC1123}" )
#=> "Mon, 30 Sep 2013 16:59:31 EEST"

DateFmt.format!( Date.shift(date, sec: -1078), "{RFC1123}" )
#=> "Mon, 30 Sep 2013 16:40:15 EEST"

DateFmt.format!( Date.shift(date, day: 1), "{RFC1123}" )
#=> "Tue, 01 Oct 2013 16:58:13 EEST"

DateFmt.format!( Date.shift(date, week: 3), "{RFC1123}" )
#=> "Mon, 21 Oct 2013 16:58:13 EEST"

DateFmt.format!( Date.shift(date, year: -13), "{RFC1123}" )
#=> "Sat, 30 Sep 2000 16:58:13 EEST"
```

## Working with Time module ##

The `Time` module already has some conversions and functionality for measuring time.

```elixir
## Time.now returns time since UNIX epoch ##

Time.now
#=> {1362,781057,813380}

Time.now(:sec)
#=> 1362781082.040016

Time.now(:msec)
#=> 1362781088623.741


## Converting units is easy ##

t = Time.now
#=> {1362,781097,857429}

Time.to_usec(t)
#=> 1362781097857429.0

Time.to_sec(t)
#=> 1362781097.857429

Time.to_sec(13, :hour)
#=> 46800

Time.to_sec(13, :msec)
#=> 0.013


## We can also convert from timestamps to other units using a single function ##

Time.convert(t, :sec)
#=> 1362781097.857429

Time.convert(t, :min)
#=> 22713018.297623817

Time.convert(t, :hour)
#=> 378550.30496039696


## elapsed() calculates time interval between now and t ##

Time.elapsed(t)
#=> {0,68,-51450}

Time.elapsed(t, :sec)
#=> 72.100247

t1 = Time.elapsed(t)
#=> {0,90,-339935}


## diff() calculates time interval between two timestamps ##

Time.diff(t1, t)
#=> {-1362,-781007,-1197364}

Time.diff(Time.now, t)
#=> {0,105,-300112}

Time.diff(Time.now, t, :hour)
#=> 0.03031450388888889
```

### Converting time units ###

```elixir
dt = Time.now
Time.convert(dt, :sec)
Time.convert(dt, :min)
Time.convert(dt, :hour)

Time.to_timestamp(13, :sec)
Time.to_timestamp([{13, :sec}, {1, :days}, {6, :hour}], :strict)
```

## FAQ ##

**Which functions provide microsecond precision?**

If you need to work with time intervals down to microsecond precision, you should take a look at the functions in the `Time` module. The `Date` module is designed for things like handling different time zones and working with dates separated by large intervals, so the minimum time unit it uses is seconds.

**So how do I work with time intervals defined with microsecond precision?**

Use functions from the `Time` module for time interval arithmetic.

**What is TimeDelta module for?**

***this will likely not make it far; I'm going to use timestamps instead***

`TimeDelta` provides functions for encapsulating a certain time interval in one value. This value can later be used to adjust multiple dates by the same amount. The delta values can be defined in terms of seconds, minutes, hours, days, weeks, months, and years.

**How do I find the time interval between two dates?**

Use `Date.seconds_diff()` to obtain the number of seconds between two given dates. If you'd like to know, how many days, months, weeks, and so on are between the given dates, take look at conversion functions defined in `TimeInterval` module.

**What kind of operations is this lib going to support eventually?**

I'd like to support most all common date and time operations. Some inspiration:

- Moment.js
- JodaTime

**What is support for time zones going to look like?**

Full support for retreiving local timezone configuration on OSX, *NIX, and Windows, conversion to any timezone in the Olson timezone database, shifting times based on timezone, etc. Coming soon.

## License

This software is licensed under [the MIT license](LICENSE.md).

  [elixir-datefmt]: https://github.com/bitwalker/elixir-datefmt
