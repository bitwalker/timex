# Frequently Asked Questions

These are questions asked at one point or another.

**How is Timex licensed?**

Timex is made available under the MIT license. See the GitHub repo for details.

**Why can't I compare dates and times with <, >, etc.?**

It is not possible to override the comparison operators to properly
compare arbitrary structs. Use `Timex.compare/2 or /3` to compare them instead.

**Which functions provide microsecond precision?**

All of them. Unless you convert to something with lower precision.

**How do I find the time interval between two dates?**

Use `Timex.diff` to obtain the number of microseconds, milliseconds, seconds, minutes, hours, days, months, weeks, or years between two dates.

**What is the support for timezones?**

Full support for retrieving local timezone configuration on OSX, *NIX, and Windows, conversion to any timezone in the Olson timezone database, and full support for timezone transitions.

Timezone support is also exposed via the `Timezone`, and `Timezone.Local` modules. Their functionality is also exposed via the `Date` module's API, and most common use cases shouldn't need to access the `Timezone` namespace directly, but it's there if needed.
