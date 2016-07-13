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
