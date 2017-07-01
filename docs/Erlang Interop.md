# Erlang Interop

## Erlang Dates and Times

### How to work with Erlang datetime and time representations

Without Timex, you've probably been working with Erlang's standard library `:calendar` module and/or `:os.timestamp` function, you may have code which already works on them, or need to consume them from another library, etc. The two most common representations of time in Erlang are the datetime and timestamp tuples, `{{year, month, day}, {hour, minute, second}}`, and `{megaseconds, seconds, microseconds}` respectively. The former is of course used for representing dates and times in a familiar format, the latter is used for representing precise moments in time, down to the microsecond.

### Converting from Erlang datetime tuples

```elixir
# To bring the aliases for Timex's modules into scope, we need to "use" Timex
iex> use Timex

# Our input datetime
iex> date = :calendar.universal_time
{{2015, 6, 24}, {3, 59, 5}}

# Conversions to various Elixir types
iex> Timex.to_datetime(date, "Etc/UTC")
...
iex> Timex.to_naive_datetime(date)
...
iex> Timex.to_date(date)
...
```

### Converting from Erlang timestamp tuples

```elixir
# The simplest case, converting from a timestamp to a DateTime, using the highest precision
iex> Duration.from_erl(:os.timestamp())
#<Duration(P46Y6M24DT23H44M56.846453S)>

# Alternatively if you want control over the precision (in this example, we only care about up-to-the-second precision):
iex> time |> Duration.to_seconds |> Timex.from_unix
#<DateTime(2015-06-24T04:18:33Z Etc/UTC)>
```

### Converting DateTimes to Erlang datetime tuples

`Timex.to_erl/1` converts any valid Timex date/datetime to an erlang date or
datetime tuple.

```elixir
iex> date = Timex.now
...> Timex.to_erl(date)
{{2015, 6, 24}, {4, 18, 33}}
```
