# Formatting

How to format DateTimes as strings with Timex's DateFormat module, and time intervals with TimeFormatter

### Formatting DateTimes

Formatting DateTimes in Timex is done via the `Timex` module. There are two built in formatters, :default and :strftime. The details of how to construct format strings can be found in the docs for **[Timex.Format.DateTime.Formatters.Default](http://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html)** and **[Timex.Format.DateTime.Formatters.Strftime](http://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.StrftimeFormatter.html)**, so this document will be a brief overview of the DateFormat API and how you use it typically.

```elixir
# By default the :default formatter is used
iex> Timex.format({2013,8,18}, "{YYYY}-{M}-{D}")
{:ok, "2013-8-18"}

# But you can use the :strftime formatter very easily
iex> Timex.format({2013,8,18}, "%Y-%m-%d", :strftime)
{:ok, "2013-08-18"}

# If you create your own formatter, you can use it easily as well
iex> Timex.format({2013,8,18}, format_str, MyApp.MyDateFormatter)

# If formatting fails for some reason you will get an `{:error, reason}` tuple, so it's
# recommended to use `format/1` or `format/2`; however you can use the "bang"
# versions of these two, `format!/1` or `format!/2` which will return the result directly,
# or raise on failure
iex> Timex.format!({2013,8,18}, "%Y-%m-%d", :strftime)
"2013-08-18"
```

### Formatting durations

Formatting durations (or timestamps really) is done via the `Timex.Format.Duration.Formatter` module, or more commonly via `Timex.format_duration`. It is extensible like date/time formatting as well.

```elixir
# Time since the epoch
iex> Duration.now |> Timex.format_duration
"P45Y7M25DT18H13M10.966072S"
iex> Duration.now |> Timex.format_duration(:humanized)
"45 years, 7 months, 3 weeks, 4 days, 18 hours, 13 minutes, 16 seconds, 141.422 milliseconds"

# Time it took to execute some code
iex> {interval, _} = Duration.measure(fn -> 1..10000 |> Enum.reverse end)
#<Duration(PT0.002614S)>
iex> interval |> Timex.format_duration
"PT0.002614S"
iex> interval |> Timex.format_duration(:humanized)
"2.614 milliseconds"
```
