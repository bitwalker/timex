# Basic Usage

**Some common scenarios with examples**

## Getting the date/time

### Getting the current datetime in UTC

```elixir
iex> Timex.now
#<DateTime(2016-07-12T22:26:43Z Etc/UTC)>

iex> Timex.today
~D[2016-07-12]
```

### Getting the current datetime in the local timezone

```elixir
iex> Timex.local
#<DateTime(2016-07-12T17:27:09-05:00 America/Chicago)>
```

### Getting the current datetime in an arbitrary timezone

```elixir
iex> Timex.now("Europe/Copenhagen")
#<DateTime(2016-07-12T22:27:37+02:00 Europe/Copenhagen)>
```

## Construction

```elixir
iex> Timex.to_date({2015, 6, 24})
~D[2015-06-24]

iex> Timex.to_datetime({{2015, 6, 24}, {4, 50, 34}}, "America/Chicago")
#<DateTime(2015-06-24T04:50:34-05:00 America/Chicago)>

iex> Timex.to_datetime({{2015, 6, 24}, {4, 50, 34}}, :local)
#<DateTime(2015-06-24T04:50:34-05:00 America/Chicago)>
```

## Parsing date/time strings

### Parsing an ISO 8601-formatted DateTime string

```elixir
# With timezone offset
iex> Timex.parse!("2015-06-24T04:50:34-05:00", "{ISO:Extended}")
#<DateTime(2015-06-24T04:50:34-05:00 Etc/GMT+05)>

# Without timezone offset
iex> Timex.parse!("2015-06-24T04:50:34Z", "{ISO:Extended:Z}")
#<DateTime(2015-06-24T04:50:34Z Etc/UTC)>
```

## Formatting DateTimes

### Formatting a DateTime as an ISO 8601 string

```elixir
iex> Timex.format!(Timex.to_datetime(~N[2015-06-24T00:04:09.293], "America/Chicago"), "{ISO:Extended}")
"2015-06-24T00:04:09.293-05:00"
iex> Timex.format!(Timex.to_datetime(~N[2015-06-24T00:04:09.293], "America/Chicago"), "{ISO:Extended:Z}")
"2015-06-24T05:04:13.293Z"
```

## Testing if one event occurs in an interval

```elixir
iex> use Timex
...> event = Timex.to_datetime({{2016, 6, 24}, {0, 0, 0}})
...> other_event = Timex.to_datetime({{2010, 1, 1}, {0, 0, 0}})
...> from = Timex.to_datetime({{2015, 1, 1}, {0, 0, 0}})
...> until = Timex.to_datetime({{2018, 1, 1}, {0, 0, 0}})
...> interval = Timex.Interval.new(from: from, until: until)
...> event in interval
true
...> other_event in interval
false
```
