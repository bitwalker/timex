# Working with Time

A breakdown of the Timex.Time API.

For any functions which take units, the following units are considered valid:

* `:timestamp`
* `:usecs`
* `:msecs`
* `:secs`
* `:mins`
* `:hours`
* `:days`
* `:weeks`

## Basics

### Get a timestamp representing an interval of zero

```elixir
> Time.zero
{0, 0, 0}
```

### Get a value representing the elapsed time since the Epoch

```elixir
# As a timestamp
> Time.epoch
{62167, 219200, 0}

# Or to a specific unit
> Time.epoch(:secs)
62167219200.0
```

### Get a value representing the current moment in time

```elixir
# As a timestamp
> Time.now
{1435, 168544, 494334}

# As a specific unit
> Time.now(:secs)
1435168549.08621
```

## Conversions

### Convert a timestamp to a different unit

```elixir
> Time.now |> Time.to_secs
1435168862.47121

# Other options are:
- to_usecs
- to_msecs
- to_mins
- to_hours
- to_days
- to_weeks
```


### Convert to a timestamp from a different unit

```elixir
> Time.to_timestamp(1000, :secs)
{0, 1000, 0}
```

### Convert a 24 hour clock value to a 12 hour clock value

```elixir
> Time.to_12hour_clock(24)
{12, :am}
> Time.to_12hour_clock(12)
{12, :pm}
```

### Convert a 12 hour clock value to a 24 hour clock value

```elixir
> Time.to_24hour_clock(12, :pm)
12
> Time.to_24hour_clock(12, :am)
24
```

## Arithmetic

### Add two timestamps together

```elixir
> Time.add(Time.from(1000, :secs), Time.from(10, :days))
{0, 865000, 0}
```

### Subtract two timestamps

```elixir
>  Time.sub(Time.epoch, Time.now)
{60732, 49915, -805553}
```

### Scale a timestamp by a coeffecient

```elixir
> Time.scale(Time.epoch, 2)
{124334, 438400, 0}
```

### Invert a timestamp

```elixir
> Time.invert(Time.epoch)
{-62167, -219200, 0}
```

### Get the absolute value of a timestamp

```elixir
> Time.abs {0, -100, 0}
{0, 100, 0}
```

## Measure

### Measure the elapsed time of some operation and return the timestamp + value

```elixir
> Time.measure(fn -> 2 * 2 end)
{{0, 0, 10}, 4}
> Time.measure(&Enum.reverse/1, [1..3])
{{0, 0, 25}, [3, 2, 1]}
> Time.measure(Enum, :reverse, [1..3])
{{0, 0, 19}, [3, 2, 1]}
```
