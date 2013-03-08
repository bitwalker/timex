Date & Time modules for Elixir
==============================

## Overview ##

This is a draft implementation of two modules for Elixir that are going to deal with all aspects of working with dates and time intervals. I'm also planning to add another module for parsing dates from strings and formatting dates to strings later on.

Basically, the `Date` module is for dealing with dates. It will support getting current date in any time zone, calculating time intervals between two dates, shifting a date by some amount of seconds/hours/days/years towards past and future. As Erlang provides support only for the Gregorian calendar, that's what I'm going to stick for the moment.

The `Time` module supports a finer grain level of calculations over time intervals. It is going to be used for timestamps in logs, measuring code executions times, converting time units, and so forth.

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
