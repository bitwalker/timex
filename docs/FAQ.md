# Frequently Asked Questions

These are questions asked at one point or another.

**How is Timex licensed?**

Timex is made available under the MIT license. See the GitHub repo for details.

**Which functions provide microsecond precision?**

If you need to work with time intervals down to microsecond precision, you should take a look at the functions in the `Time` module. The `Date` module is designed for things like handling different time zones and working with dates separated by large intervals, so the minimum time unit it uses is milliseconds.

**So how do I work with time intervals defined with microsecond precision?**

Use functions from the `Time` module for time interval arithmetic.

**How do I find the time interval between two dates?**

Use `Timex.diff` to obtain the number of milliseconds, seconds, minutes, hours, days, months, weeks, or years between two dates.

**What is the support for timezones?**

Full support for retrieving local timezone configuration on OSX, *NIX, and Windows, conversion to any timezone in the Olson timezone database, and full support for timezone transitions.

Timezone support is also exposed via the `Timezone`, and `Timezone.Local` modules. Their functionality is also exposed via the `Date` module's API, and most common use cases shouldn't need to access the `Timezone` namespace directly, but it's there if needed.
