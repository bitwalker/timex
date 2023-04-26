# Change Log

All notable changes to this project will be documented in this file (at least to the extent possible, I am not infallible sadly).
This project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### Added/Changed

- Changed `Timex.Duration.Parse` to be 2x faster
- Fixed compilation warning from gettext
- Added `cycled` option for `Timex.between?/4` to support time-range checks that pass through midnight
- Add Croatian translation

### Fixed

- Updated `Timex.now/1` typespec to remove the `AmbiguousDateTime`
- Corrected pluralization rules for bg/cs/he/id/ro/ru
- Fixed `Timex.shift/2` to preserve the precision of the provided datetime

---

## 3.7.8

### Added/Changed

- Add Thai translations
- Add Estonian translation
- Added `TimezoneInfo.format_offset/1`

### Fixed

- Fix incorrect `Timex.weekday/2` typespecs
- Added timezone field to set_options type
- Corrected type definition for Types.week_of_month to include possiblity of 6th week (see #703)
- Added specs to parse function to account for AmbiguousDateTime return type

---

## 3.7.6

### Changed

- The documentation on weekday formatting via `%w` and `%u` strftime directives and `WDmon` and `WDsun`
default directives did not match, and worse, the behaviour had regressed as well and did not match the
docs for either. The behaviour now matches between the two formatters, as does the documentation, and
aligns with the C strftime specification (i.e. Monday is 1..7, Sunday is 0..6)

### Fixed

- Clarify docs on comparison granularity for days/weeks
- Fix incorrect weekday formatting (see #668)
- Handled edge case where no locally-defined timezone is present (see #670)
- Invalid validation of ambiguous date/times during parsing (see #674)

---

## 3.7.5

### Added/Changed

- Added `Timex.Timezone.get/3` to allow requesting timezones using utc or wall clock as desired

### Fixed

- Addressed issues #652, #658, #659, #656, #654, #653

## 3.7.4

### Fixed

- Addressed issues #647, #648, #649, #650

## 3.7.3

**NOTE:** The config of the Timex default locale is changed to:
```ex
config :your_app, Timex.Gettext, default_locale: "en"
```
This follows the standard set by Gettext, see: [the Gettext docs](https://hexdocs.pm/gettext/Gettext.html#module-default-locale)

Now when the Gettext locale is being changed on runtime with:
```ex
Gettext.put_locale("nl")
```
The Gettext backend for Timex will follow suit. If for some reason you want Timex, and just Timex, to change its locale to something else you should target the Timex.Gettext backend with:
```ex
Timex.Gettext.put_locale("de")
```

### Potentially Breaking

- Fixed handling of `Etc/GMT` vs `GMT` timezones. The former must be POSIX compatible, which inverts the meaning of the sign, whereas the latter have no such restriction and are equivalent to `UTC(+/-)HH:MM`,
while this is fixing incorrect behavior, it could potentially break users relying on the incorrect behavior.

### Fixed

- #494, incorrect handling of parsing week numbers
- Improve parsing of timezones
- Incorrect stringification of error values returned in some circumstances
- Let Timex follow the locale set by the global Gettext. See #501

### Added/Changed

- Removed `Timex.Timezone.diff`, as it is no longer used in Timex
- Added support for obtaining the Julian day of year via `Calendar.Julian.date_for_day_of_year/3`

### Fixed

## 3.7.1

### Fixed

- `local/0` and `local/1` were incorrectly returning TimezoneInfo structs due to a bad match

## 3.7.0

### Potentially Breaking

- Elixir 1.8+ is now required
- Tzdata 1.0+ is now required
- If you were previously relying on `?` suffixed functions to return
`{:error, reason}` if given invalid date/time inputs (other than
`is_valid?`), these functions now always return booleans and raise if an
error with the input is encountered

### Added/Changed

- Refactored much of the library to delegate to the Calendar API where
appropriate, we now make more of an effort to avoid duplication of the
standard library functionality
- Functions with the `?` suffix now correctly raise on invalid inputs,
and always return booleans. This was implicitly broken before, we need
to follow convention here.
- Local timezone handling no longer requires parsing the zoneinfo files,
instead we attempt to observe the timezone name that is active and feed
that into the timezone database directly. We were just using the
abbreviations before, but that wasn't correct behavior at all. In the
future we may want to support the system timezone database as a proper
implementation of `Calendar.TimeZoneDatabase`, but for now we've just
removed the unnecessary parsing work that was going on here.
- `Timex.today/1` which returns today's date in the provided timezone

### Fixed

- Handling of timezones across DST. More generally we now handle gaps/ambiguity
much more consistently
- ZoneInfo parser was refactored, now properly supports version 2/3
files, addresses some small bugs in previous code
- Some incorrect/redundant typespecs were removed/fixed
- We now support alternative timezone databases for API operations that
do not need to interact with the `Timex.Timezone` module directly. That
module is still tied to tzdata for now, but in the future may be
modified to remove the direct dependency.

## 3.6.4

### Potentially Breaking

- `Timex.set/2` now sets microseconds when setting `:time` from a `%Time{}` struct
- `Timex.Duration.to_string/1` now returns `PT0S` instead of `P` for zero-length durations with the default formatter

### Added
- `Timex.set/2` now also accepts setting the `:date` from a `%Date{}` and `:time` from a `%Time{}` struct for NaiveDateTime

### Fixes
- Loosen `tzdata` dependency to allow `1.x` releases

## 3.6.3

### Added

- Switched to GitHub Actions for CI
- Finnish translations
- Enumerable implementation for Timex.Interval

### Fixed

- Czech translation fixes
- #616
- #615

## 3.6.2

### Added

- Updated tzdata to 1.0.1
- Vietnamese/Czech/Hebrew/Bosnian translations
- Formatter settings, and ran the formatter on the codebase

### Fixed

- Romanian translation fixes
- Various documentation/typespec fixes
- Parser for ISOweek
- #559
- #577

## 3.6.1

### Potentially Breaking

- Require Elixir v1.6+

### Added

- Setup property based test framework and add sample tests (#480)
- Turkish translation (#534)
- Add details to parsing documentation (#540)
- Support time units in singular (#509)
- #538 documentation of default formatting directives
- Support for tzdata 1.0.0 (#536)

### Fixed

- Address handling of ambiguity in timezone conversions by using UTC clock time, where possible. See #488
- #491 gracefully handle errors resolving a timezone using wall clock time
- #514 gracefully handle converting date to datetime on tz boundary
- #531 address some issues with shifting over timezone boundaries
- #507 unnecessary tz conversion during logical shifts results in erroneous results
- #532 shift priority incorrectly inverted
- #537 precision not preserved in some situations
- Elixir 1.8 deprecations
- `Timex.diff/2` spec
- `Timex.Timezone.convert/2` when using custom time zones
- Letter encoding on PT translation
- Swedish translation id for March

## 3.5.0

### Added

- `Timex.set/2` now also accepts setting the `:date` from a `%Date{}` struct.
- `Interval.difference/2` removes one interval from another

## 3.4.1

### Added
- Afrikaans translations (Julian Dicks)
- The :inclusive option for Timex.between?/4 :start and :end in addition to true

### Fixed
- strftime_iso_kitchen no longer discards dates


## 3.4.0

**NOTE:** There are breaking changes in this release. This is not going to result in a major
version bump, as the old behavior did not match the docs, and was incorrect to boot. In other words, the
breaking changes only affect you if you relied on the incorrect behavior, if you were expecting the
documented behavior, then these are _not_ breaking changes.

### Added

- Interval.contains?/2 to test if one interval contains another

### Fixed

- Interval overlap was being improperly calculated
- Interval behavior with respect to open/closed bounds was incorrect (open bounds were being treated as closed and vice versa)
- Intervals could be created with invalid from/until (i.e. creating an interval with an until before the from)
- Interval documentation improvements for clarity


## 3.1.13

### Added

- Romanian translations (Cezar Halmagean)

### Fixed

- #280 - formatting of non-ISO week numbers

## 3.1.6-12

Sorry I didn't keep this up to date, please review the commits in git for these versions.

## 3.1.6

### Added

- Translations for zh_CN (Chinese)
- Translations for pl (Polish)
- #244 - Support for fractional offsets

### Fixed

- Various documentation fixes
- Fix #262 - Day of week calculation in Julian calendar - Mark Meeus
- Fix #260 - Duration formatting edge case - Slava Kisel
- Fix #257 - Fix from_iso_triplet logic - Mathew Bramson
- Fix #252 - Formatting/parsing of fractional seconds was not round-trippable
- Fix #248 - Make fractional second formatting consistent with standard library
- Add application callback so we can provide better errors if :tzdata isn't started
- Enable fallback_to_any in Timex.Protocol

## 3.1.5

### Fixed

- Fix #218 - Bug with `Timex.from_iso_triplet`
- Zone abbreviations produced by parsing did not always match those in tzdata

## 3.1

### Fixed

- Fix #214 - Permit any valid datetime type in formatting API
- Fix #215 - Properly validate 2-digit years

## 3.0.8

### Changed

- Duration.scale/2 now works with float coefficients

## 3.0.7

### Added

- Implementation of Timex.Protocol for Map. This is primarily useful (and intended)
  for dealing with deserialized date/time structs.

### Fixed

- Precision calculation for microseconds was sometimes incorrect.

## 3.0.6

### Added

- Added parsing for ISO-8601 durations to the Duration API

### Fixed

- #206 - Bug in shifting DateTimes

## 3.0.5

### Fixed

- #199 - Handling of timezone names with `-` was broken.

## 3.0.3

### Added

- Add Duration.to_time/1, to_time!/1, from_time/1 for conversions to/from Time

## 3.0.2

### Fixed

- Converting a NaiveDateTime with to_datetime did not include microseconds
- now/0, now/1, local/0 were not microsecond precise

## 3.0.1

### Added

- `Duration.to_clock/1` - convert a Duration to a `{hour,min,sec,usec}` tuple
- `Duration.from_clock/1` - convert a `{hour,min,sec,usec}` tuple to a Duration

## 3.0.0

**IMPORTANT**: This release is a significant rewrite of Timex's internals as well as API. Many things have remained unchanged,
but there are many things that have as well. Mostly the removal of prior deprecations, and the removal (without deprecation) of
things incompatible with, or now redundant due to, the introduction of calendar types in Elixir 1.3 and their impact on Timex.
The list of these changes will be comprehensively spelled out below, along with recommendations for alternatives in the cases
of removals.

### Fixed
- [#185](https://github.com/bitwalker/timex/issues/185)
- [#137](https://github.com/bitwalker/timex/issues/137)

### Added
- `Timex.Protocol` (defines the API all calendar types must implement to be used with Timex)
- `compare/3`, `diff/3` `shift/2`, now allow the use of `:milliseconds` and `:microseconds`
- `set/2` now allow the use of `:microsecond`
- `Timex.Duration`
- `to_gregorian_microseconds/1`, converts a date/time value to microseconds since year zero

### Changed
- Timex's old Date/DateTime types are replaced by Elixir 1.3's new calendar types,
  NaiveDateTime is now used where appropriate, and AmbiguousDateTime remains in order to
  handle timezone ambiguities.
- `Timex.diff/3` now returns to it's old behaviour of returning a signed integer for values, so
  that diffing/comparing can be done on a single value.
- Renamed `Timex.Time` to `Timex.Duration` to better reflect it's purpose and prevent conflicts with
  Elixir's built-in `Time` type.
- Renamed `Timex.Format.Time.*` to `Timex.Format.Duration.*`
- Renamed `:timestamp` options to `:duration`
- Renamed `*_timestamp` functions to `*_duration`
- Changed `Timex.Duration` to operate on and return `Duration` structs rather than Erlang timestamp tuples
- Changed `Duration.from/2`, to `Duration.from_*/1`, moving the unit into the name.
- Renamed `to_erlang_datetime` to `to_erl`

### Removed
- Timex.Date (use `Timex` now)
- Timex.DateTime (use `Timex` now)
- Timex.Convertable (no longer makes sense in the face of differentiating NaiveDateTime/DateTime)
- `set/2` no longer allow the use of `:millisecond`
- Removed `Timex.date`
- Deprecated `Timex.datetime`
- Removed `from_timestamp` functions
- Removed `to_gregorian`
- Removed `to_seconds/2` in favor of `to_gregorian_seconds/1` and `to_unix/1`
- Removed `normalize/1`, it no longer is necessary. `normalize/2` still exists however

## 2.1.3

### Fixed
- Some behaviour around shifting across DST boundaries was behaving incorrectly (#142)

## 2.1.2

This release adds the base for locale-awareness in Timex, including one locale ("ru"), support for formatting datetimes
in another locale, and functions which return names of things will now use the default locale. To configure Timex's default
locale, put the following in config.exs:

```elixir
config :timex, default_locale: "ru" # or whatever locale you want
```

### Added
- The ability to configure a default locale (the default is "en" if no config is provided) for formatting/translation of strings
- The ability to format a string using a given locale, otherwise the default locale is used
- Translations for the "ru" locale, more to come
- Locale awareness throughout the core API, so functions such as `day_name` will return the day name in the configured locale,
  if translations for that locale were provided
- `Timex.lformat`, and `Timex.lformat!` variants of the formatting functions, which take a locale to use in formatting
- Added a relative time formatter, which functions very similarly to Moment.js's relative time formatting
  You can use it with `Timex.format!` or `Timex.format`, by providing :relative as the formatter, and using the `{relative}` token in your
  format string. NOTE: The relative formatter does not support other tokens, only `{relative}` for now, if it seems like there
  is a use case where `{relative}` should support other tokens, I'll consider adding that.
- Added `Timex.from_now`, which takes:
  - A single Convertable, which returns the relative time between that date/time value and now
  - Two Convertables, which returns the relative time between the first date/time value, and the reference date (provided as the 2nd)
  - Two variants of the above which also take a locale as the last argument, and results in the string being translated to that locale
- Added ASN.1 parsing/formatting support
### Changed
- All functions which return strings, and all formatting functions, will use the default locale for translation, which is "en" unless another was configured, or one was provided if the function takes a locale as an argument.
### Fixed
- Milliseconds should be able to be fractional - the is_millisecond guard was only allowing integers

## 2.1.1

### Added
- Implementations of the Inspect protocol for Date, DateTime, AmbiguousDateTime, TimezoneInfo, and AmbiguousTimezoneInfo
### Changed
- When inspecting any Timex types, the compact view will be used, pass structs: false to view the raw data structures if needed.

## 2.1.0

### Added
- Two new protocols, `Timex.Comparable` and `Timex.Convertable`, implementing these two for your own date/time types
  will allow you to use the Timex API with your own types, just be aware that only Dates, DateTimes, or AmbiguousDateTimes
  will be returned as date/time representations, but it should be trivial to add a function in your implementation to
  convert back.
- Basic Julian calendar implementation, which allows you to get the Julian date for a given Convertable, see
  `Timex.to_julian/1`, you can also get the day of the week number for a Julian date, via `Timex.Calendar.Julian`
- `to_julian` function to the `Timex.Convertable` protocol
- `Timex.timezones` to get a list of all valid timezones
### Changed
- **POTENTIALLY BREAKING** The `{Zname}` format token was formatting with the abbreviation, which is incorrect. It
  has been changed to format with the full name, use `{Zabbr}` if you want the abbreviation.
- Moved comparison and diffing behaviour into a new protocol, `Timex.Comparable`, which allows you to now
  provide your own implementations for comparing other date or datetime types against Timex ones. This
  makes the API more flexible, and also cleaned up the code quite a bit.
- Modified Timex API to accept Comparables for just about all functions
- Added implementations of `Timex.Comparable` for `Tuple`, `Date`, `DateTime`, `AmbiguousDateTime`
- Added implementations of `Timex.Convertable` for `Map` and `Atom`. The former will accept any map with either
  DateTime-like keys (i.e. year/month/day/hour/minute/etc.) as strings or atoms, or any Date-like keys (year/month/day),
  as strings or atoms. The latter will accept only two atoms which represent Dates/DateTimes right now, :epoch, and :zero.
- Modified `Timex.Comparable` to take any `Timex.Convertable`
## Fixed
- A number of performance enhancements due to refactoring for `Convertable` and `Comparable`, particularly with diffing
- The `%Z` strftime format token was formatting timezones as abbreviations, which is not round-trippable due to timezone
  ambiguity. This token now formats using the full timezone name, which is valid according to the strftime standard.
- The `{Zname}` token had the same problem as above, and has been fixed to use the full name

## 2.0.0

**READ THIS**: This release contains breaking changes from the previous API. The changes are easy to make,
and the compiler will catch almost all of them. See the Migrating section of the README for details on migrating
to 2.0

### Added
- New `Date` type, which is basically the same as `DateTime`, but without time/timezone, which works with
  most all API functions that work with DateTimes, except those which are specific to time or timezones.
  Functions which take a Date or DateTime and options which can manipulate both date and time properties,
  like `set` or `shift` will work as you'd expect with Date values and time-based properties (setting a time
  property will change nothing, shifting will work for values which represent at least a day, sub-day values will not
  change the Date).
- New `AmbiguousDateTime` type which is returned instead of `DateTime` when the datetime in question falls in
  an ambiguously defined timezone period. This type contains two fields, `:before` and `:after` which contain
  the `DateTime` values to choose from. This handles cases where previously an error would likely have been thrown,
  or the behaviour would've been undefined.
- Timex.date and Timex.datetime, which are the equivalent of the old Date.from, except produce a Date or DateTime respectively.
  The `from` API still exists in the Date and DateTime modules, and is present in the Timex API for easier migration, but will
  be deprecated in the future.
- New `from_erl`, `from_timestamp`, `from_microseconds`, `from_milliseconds`, `from_seconds`, `from_days` functions to
  replace the old `from` API, and to match the `Time` API more closely.
- to_date/to_datetime/to_unix/to_timestamp/to_gregorian_seconds conversions in Timex.Convertable (old Timex.Date.Convert protocol)
- before?/after?/between? functions to Timex module
- format/format!/format_time/format_time!/parse/parse! API to Timex module
- week_of_month/1 and /3 to get the week index of the month a date occurs in
- `Timex.diff(this, other, :calendar_weeks)` - get the diff between two dates in terms of weeks on the calendar,
  in other words, the diff is done based on the start of the earliest date's week, and the end of the latest date's week
### Changed
- **BREAKING** All non-bang functions in the API now return error tuples of the form `{:error, term}` instead of raising exceptions
- **BREAKING** All DateTime-related APIs can now return an `AmbiguousDateTime`, which must be handled by choosing which DateTime to use.
- **BREAKING** All Timezone lookups can now return an `AmbiguousTimezoneInfo` struct, which must be handled by choosing which TimezoneInfo to use.
- **BREAKING** DateTime.ms is now DateTime.millisecond
- **BREAKING** Date module API has moved to Timex module
- Date and DateTime modules now contain their respective implementations of the Timex API, all shared functions
  have moved to the Timex module. You can work with Date or DateTimes either through the Timex API, or through the
  API exposed in the Date and DateTime modules. It is recommended to use Timex though.
- **BREAKING** Renamed Timex.Date.Convert to Timex.Convertable
- **BREAKING** `diff/3` now returns the same value no matter which order the arguments are given. Use `compare/3` to get the ordering
### Deprecated
- `Timex.from` (old `Date.from`) variants. Use `Timex.date`, `Timex.datetime`, `Date.from_<type>`, or `DateTime.from_<type>` instead.
- `DateTime.from`. Use `Timex.datetime`, `DateTime.from_erl`, `DateTime.from_<type>`
- `to_usecs`, `to_msecs`, `to_secs`, and `to_mins` in favor of `to_microseconds`, `to_milliseconds`, `to_seconds`, and `to_minutes`
- Abbreviated unit names like `secs` or `mins`, `sec` or `min`, in favor of their full names (i.e. `seconds`, `minutes`, etc.)
### Removed
- DateConvert/DateFormat aliases
### Fixed
- Shifting datetimes is now far more accurate than it was previously, and handles timezone changes, ambiguous timezone periods, and non-existent time periods (such as those during a timezone change like DST).
- Diffing by weeks, months, and years is now much more precise
- Humanized Time formatter now pluralizes units correctly

## 1.0.2

**BREAKING**: If you previously depended on parsing of timezone abbreviations for non-POSIX zones,
for example, CEST, you will need to update your code to manually map that abbreviation to a valid zone
name. Timezone abbreviations are only supported if they are POSIX timezones in the Olson timezone database.

### Added
- Added CHANGELOG
- Add Date.from clause to handle Phoenix datetime_select changeset
### Changed
- Timezone abbreviation handling is now only valid for POSIX/Olson timezone names.
- Some small optimizations
### Deprecated
- N/A
### Removed
- Timezone abbreviation handling for non-POSIX/Olson timezone names
### Fixed
- Timezone abbreviation handling (was previously non-deterministic/incorrect)
- Disable tzdata's auto-update during compilation
- Usage of imperative if
