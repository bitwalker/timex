# Parsing

**NOTE:** As a rule, Timex validates dates/times are valid within certain constraints, but it makes no guarantees around user-provided input. Some functions in the Timex API have high complexity relative to the input values, and if you are not careful to sanitize input to these functions, an attacker can exploit this to lock processes calling these functions, and potentially DoS your system. The only general exception to this rule is with datetime parsing, which is very strict about what values are considered valid. Some format strings do allow unbounded values to be provided however, such as the {s-epoch} format token. As such, it is recommended that you take care to specify format strings which are as restrictive as possible.

### How to use Timex's DateFormat module for parsing DateTimes from strings

Parsing a DateTime from an input string is very similar to formatting them, and is quite simple:

```elixir
# Simple date format, default parser
> DateFormat.parse("2013-03-05", "{YYYY}-{0M}-{0D}")

# Simple date format, strftime parser
> DateFormat.parse("2013-03-05", "%Y-%m-%d", :strftime)

# Parse a date using the default parser and the shortcut directive for RFC 1123
> DateFormat.parse("Tue, 05 Mar 2013 23:25:19 GMT", "{RFC1123}")
{:ok,
 %DateTime{calendar: :gregorian, day: 5, hour: 23, minute: 25, month: 3,
  ms: 0, second: 19,
  timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2013}}

# Or you can use the :strftime parser
> DateFormat.parse("2013-03-05", "%Y-%m-%d", :strftime)
{:ok, %DateTime{..., day: 5, hour: 0, minute: 0, month: 3, year: 2013}}

# Any preformatted directive ending in `z` will shift the date to UTC/Zulu
> DateFormat.parse("Tue, 06 Mar 2013 01:25:19 +0200", "{RFC1123z}")
{:ok,
 %DateTime{calendar: :gregorian, day: 5, hour: 23, minute: 25, month: 3,
  ms: 0, second: 19,
  timezone: %TimezoneInfo{abbreviation: "UTC", from: :min,
   full_name: "UTC", offset_std: 0, offset_utc: 0, until: :max}, year: 2013}}
```

As with `DateFormat`, you can also use the "bang" versions, which will raise on failure rather than returning an `{:error, reason}` tuple (`parse!/1` and `parse!/2` respectively).
