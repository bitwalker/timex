Date & Time modules for Elixir
==============================

## Overview ##

This is a draft implementation of two modules for Elixir that are going to deal with all aspects of working with dates and time intervals. I'm also planning to add another module for parsing dates from strings and formatting dates to strings later on.

Basically, the `Date` module is for dealing with dates. It will support getting current date in any time zone, calculating time intervals between two dates, shifting a date by some amount of seconds/hours/days/years towards past and future. As Erlang provides support only for the Gregorian calendar, that's what I'm going to stick for the moment.

## FAQ ##

**Which functions provide microsecond precision?**

If you need to work with time intervals down to microsecond precision, you should take a look at the functions in the `Time` module. The `Date` module is designed for things like handling different time zones and working with dates separated by large intervals, so the minimum time unit it uses is seconds.

**So how do I work with time intervals defined with microsecond precision?**

Use functions from the `Time` module for time interval arithmetic.

**What is TimeDelta module for?**

`TimeDelta` provides functions for encapsulating a certain time interval in one value. This value can later be used to adjust multiple dates by the same amount. The delta values can be defined in terms of seconds, minutes, hours, days, weeks, months, and years.

**How do I find the time interval between two dates?**

Use `Date.seconds_diff()` to obtain the number of seconds between two given dates. If you'd like to know, how many days, months, weeks, and so on are between the given dates, take look at conversion functions defined in `TimeInterval` module.
