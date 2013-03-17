Date & Time modules for Elixir
==============================

[![Build Status](https://travis-ci.org/alco/elixir-datetime.png?branch=master)](https://travis-ci.org/alco/elixir-datetime)

A draft implementation of date and time functionality based on **Idea #6** from this [proposal page](https://github.com/beamcommunity/beamcommunity.github.com/wiki/Project:-Elixir).

## Overview ##

This is a draft implementation of two modules for Elixir that are going to deal with all aspects of working with dates and time intervals. I'm also planning to add another module for parsing dates from strings and formatting dates to strings later on.

Basically, the `Date` module is for dealing with dates. It will support getting current date in any time zone, calculating time intervals between two dates, shifting a date by some amount of seconds/hours/days/years towards past and future. As Erlang provides support only for the Gregorian calendar, that's what I'm going to stick for the moment.

The `Time` module supports a finer grain level of calculations over time intervals. It is going to be used for timestamps in logs, measuring code executions times, converting time units, and so forth.

## Use cases ##

### Getting current date and time ###

Get current local date and format it to string.

```elixir
dt = Date.local()
Date.rfc_format(dt)
Date.iso_format(dt)

# Use Time module for microsecond precision
t = Time.now()
Time.rfc_format(t)
Time.iso_format(t)
```

### Extracting information about date ###

Find out current weekday, week number, number of days in a given month, etc.

```elixir
dt = Date.local()     #=> {{2013,3,10},{0,0,30}}
Date.weekday(dt)      #=> 7  # Sunday
Date.week_number(dt)  #=> {2013,10}
Date.iso_triplet(dt)  #=> {2013,10,7}  # { year, week number, weekday }
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

## What already works ##

There is no support for different time zones yet, but you can already shift dates and format them to standard string representations.

```elixir
local = Date.local
#=> {{2013,3,9},{0,13,51}}

Date.universal(local)
#=> [{{2013,3,8},{22,13,51}}]

Date.seconds_diff(Date.local, local)
#=> 51


## Moving in time ##

Date.shift(local, 1, :days)
#=> {{2013,3,10},{0,13,51}}

Date.shift(local, 3, :weeks)
#=> {{2013,3,30},{0,13,51}}

Date.shift(local, -13, :years)
#=> {{2000,3,9},{0,13,51}}


## Basic formatting ##

Date.iso8601(local)
#=> "2013-03-09 00:13:51"

Date.rfc1123(local)
#=> "Fri, 08 Mar 2013 22:13:51 GMT"
```

Now, the `Time` module already has some conversions and functionality for measuring time.

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

Can't say for sure yet. My goal is to make it easy to work with dates and time intervals so that you won't ever need to resort to Erlang's `calendar`, `time`, some functions from `erlang` and a bunch of other one.

Some inspirations may be drawn from these: https://github.com/dweldon/edate/blob/master/src/edate.erl, http://www.kodejava.org/browse/73.html

**What is support for time zones going to look like?**

Not sure yet. Erlang does not support working time zones, so we can either use OS-specific functions and implement this feature for each platform separately or package a time zone database with this library and write the implementation in Elixir itself.

References: https://github.com/drfloob/ezic
