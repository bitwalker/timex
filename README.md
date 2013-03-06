Date & Time modules for Elixir
==============================

## FAQ ##

**Which functions provide microsecond precision?**

If you need to work with time intervals down to microsecond precision, you should take a look at the functions in the `Time` module. The `Date` module is designed for things like handling different time zones and working with dates separated by large intervals, so the minimum time unit it uses is seconds.

**So how do I work with time intervals defined with microsecond precision?**

Use functions from the `Time` module for time interval arithmetic.

**What is TimeDelta module for?**

`TimeDelta` provides functions for encapsulating a certain time interval in one value. This value can later be used to adjust multiple dates by the same amount. The delta values can be defined in terms of seconds, minutes, hours, days, weeks, months, and years.

**How do I find the time interval between two dates?**

Use `Date.seconds_diff()` to obtain the number of seconds between two given dates. If you'd like to know, how many days, months, weeks, and so on are between the given dates, take look at conversion functions defined in `TimeInterval` module.
