# Parsing

**NOTE:** While Timex is strict about handling user input in general, it makes no guarantees that you will be protected from malicious input, as there are some limitations when considering user-provided input to parsers. A few parsers in Timex accept unbounded input, such as `{s-epoch}`, because there is no defined limit on the number of seconds since UNIX epoch (you may want to represent a date far in the future for example). It's important that you do your own validation of user input before passing it to Timex for parsing as a second line of defense - for example, limiting the length of input strings to some reasonable max length. It's also highly recommended that you take care to be as restrictive with your format strings as possible.

### How to use Timex for parsing DateTimes from strings

Parsing a DateTime from an input string is very similar to formatting them, and is quite simple:

```elixir
# Simple date format, default parser
iex> Timex.parse("2013-03-05", "{YYYY}-{0M}-{0D}")

# Simple date format, strftime parser
iex> Timex.parse("2013-03-05", "%Y-%m-%d", :strftime)

# Parse a date using the default parser and the shortcut directive for RFC 1123
iex> Timex.parse!("Tue, 05 Mar 2013 23:25:19 Z", "{RFC1123z}")
#<DateTime(2013-03-05T23:25:19Z Etc/UTC)>

# Or you can use the :strftime parser (note how without timezone information, a NaiveDateTime is returned)
iex> Timex.parse!("2013-03-05", "%Y-%m-%d", :strftime)
~N[2013-03-05T00:00:00]

# Any preformatted directive ending in `z` will shift the date to UTC/Zulu
iex> Timex.parse("Tue, 06 Mar 2013 01:25:19 +0200", "{RFC1123}")
{:ok, #<DateTime(2013-03-05T23:25:19Z Etc/UTC)>}
```

,You can also use "bang" versions (i.e. `parse!`), which will raise on failure rather than returning an `{:error, reason}` tuple (`parse!/1` and `parse!/2` respectively).

### Supported Standards and Common Formats

#### RFC822
```elixir
# RFC822
iex> Timex.parse("Mon, 05 Jun 14 23:20:59 UTC", "{RFC822}")
{:ok, #DateTime<2014-06-05 23:20:59Z>}

# RFC822z
iex> Timex.parse("Mon, 05 Jun 14 23:20:59 +00:00", "{RFC822z}")
{:ok, #DateTime<2014-06-05 23:20:59Z>}
```
#### RFC3339
```elixir
# RFC3339
iex> Timex.parse("2013-03-05T23:25:19+02:00", "{RFC3339}")
{:ok, #DateTime<2013-03-05 23:25:19+02:00 +02 Etc/GMT-2>}

# RFC3339z
iex> Timex.parse("2013-03-05T23:25:19Z", "{RFC3339z}")
{:ok, #DateTime<2013-03-05 23:25:19Z>}
```
#### RFC1123
```elixir
# RFC1123
iex> Timex.parse("Tue, 05 Mar 2013 23:25:19 EST", "{RFC1123}")
{:ok, #DateTime<2013-03-05 23:25:19-05:00 EST EST>}

# RFC1123z
iex> Timex.parse("Tue, 06 Mar 2013 01:25:19 Z", "{RFC1123z}")
{:ok, #DateTime<2013-03-06 01:25:19Z>}
```
#### ASN1:GeneralizedTime
```elixir

# ASN1:GeneralizedTime
iex> Timex.parse("20090305232519", "{ASN1:GeneralizedTime}")
{:ok, ~N[2009-03-05 23:25:19]}

# ASN1:GeneralizedTime:Z
iex> Timex.parse("20090305232519.456Z", "{ASN1:GeneralizedTime:Z}")
{:ok, #DateTime<2009-03-05 23:25:19.456Z>}

# ASN1:GeneralizedTime:TZ
iex> Timex.parse("20090305232519.000-0700", "{ASN1:GeneralizedTime:TZ}")
{:ok, #DateTime<2009-03-05 23:25:19-07:00 -07 Etc/GMT+7>}
```

#### ASN1:UTCtime
```elixir

# ASN1: UTCtime
iex(26)> Timex.parse("130305232519Z", "{ASN1:UTCtime}")
{:ok, #DateTime<2013-03-05 23:25:19Z>}
```
#### ISO:Extended

```elixir
# ISO8601 (Extended)
iex> Timex.parse("2014-08-14T12:34:33+00:00", "{ISO:Extended}")
{:ok, #DateTime<2014-08-14 12:34:33Z>}

iex> Timex.parse("2014-08-14T12:34:33+0000", "{ISO:Extended}")
{:ok, #DateTime<2014-08-14 12:34:33Z>}

iex> Timex.parse("2014-08-14T12:34:33Z", "{ISO:Extended:Z}")
{:ok, #DateTime<2014-08-14 12:34:33Z>}

# ISO8601 (Basic)
iex> Timex.parse("20140814T123433-0000", "{ISO:Basic}")
{:ok, #DateTime<2014-08-14 12:34:33+00:00 GMT Etc/GMT+0>}

iex> Timex.parse("20140814T123433Z", "{ISO:Basic:Z}")
{:ok, #DateTime<2014-08-14 12:34:33Z>}

```

#### ISOdate
```elixir
iex> Timex.parse("2007-08-13", "{ISOdate}")
{:ok, ~N[2007-08-13 00:00:00]}
```

### Default Directive Format

This is a formatting language designed specifically alongside Timex, and its primary
purpose and advantage is that it is simple and easy to memorize and read in comparison
to the standard C stftime format.

The full documentation on the set of directives and formatting options can be found
[here](https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html).

### Strftime Directive Format

This is the standard C library formatting language used with the `stftime` function in C.
Timex supports this as a familiar alternative to its native "default" formatting language
as described above.

This implementation in Elixir is mostly compatible with `strftime`. The
exception is the absence of locale-depended results. All directives that imply
textual result will produce English names and abbreviations.

You can find the full documentation on this format and its options
[here](https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Strftime.html).

### Relative Format

This is a human readable relative date/time format that consists of a single
directive, `{relative}`, and produces values like "a few seconds ago", or
"2 days ago".

You can find the full chart of mappings from ranges to values [here](https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Relative.html).
