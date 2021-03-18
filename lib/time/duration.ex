defmodule Timex.Duration do
  @moduledoc """
  This module provides a friendly API for working with Erlang
  timestamps, i.e. `{megasecs, secs, microsecs}`. In addition,
  it provides an easy way to wrap the measurement of function
  execution time (via `measure`).
  """
  alias __MODULE__
  alias Timex.Types
  use Timex.Constants

  @enforce_keys [:megaseconds, :seconds, :microseconds]
  defstruct megaseconds: 0, seconds: 0, microseconds: 0

  @type t :: %__MODULE__{
          megaseconds: integer,
          seconds: integer,
          microseconds: integer
        }
  @type units ::
          :microsecond
          | :microseconds
          | :millisecond
          | :milliseconds
          | :second
          | :seconds
          | :minutes
          | :hours
          | :days
          | :weeks
  @type measurement_units :: :microseconds | :milliseconds | :seconds | :minutes | :hours
  @type to_options :: [truncate: boolean]

  @doc """
  Converts a Duration to an Erlang timestamp

  ## Example

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 2, microseconds: 3}
      ...> Timex.Duration.to_erl(d)
      {1, 2, 3}
  """
  @spec to_erl(__MODULE__.t()) :: Types.timestamp()
  def to_erl(%__MODULE__{} = d),
    do: {d.megaseconds, d.seconds, d.microseconds}

  @doc """
  Converts an Erlang timestamp to a Duration

  ## Example

      iex> Timex.Duration.from_erl({1, 2, 3})
      %Timex.Duration{megaseconds: 1, seconds: 2, microseconds: 3}
  """
  @spec from_erl(Types.timestamp()) :: __MODULE__.t()
  def from_erl({mega, sec, micro}),
    do: %__MODULE__{megaseconds: mega, seconds: sec, microseconds: micro}

  @doc """
  Converts a Duration to a Time if the duration fits within a 24-hour clock.
  If it does not, an error tuple is returned.

  ## Examples

      iex> d = %Timex.Duration{megaseconds: 0, seconds: 4000, microseconds: 0}
      ...> Timex.Duration.to_time(d)
      {:ok, ~T[01:06:40]}

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 0, microseconds: 0}
      ...> Timex.Duration.to_time(d)
      {:error, :invalid_time}
  """
  @spec to_time(__MODULE__.t()) :: {:ok, Time.t()} | {:error, atom}
  def to_time(%__MODULE__{} = d) do
    {h, m, s, us} = to_clock(d)
    Time.from_erl({h, m, s}, Timex.DateTime.Helpers.construct_microseconds(us, -1))
  end

  @doc """
  Same as to_time/1, but returns the Time directly. Raises an error if the
  duration does not fit within a 24-hour clock.

  ## Examples

      iex> d = %Timex.Duration{megaseconds: 0, seconds: 4000, microseconds: 0}
      ...> Timex.Duration.to_time!(d)
      ~T[01:06:40]

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 0, microseconds: 0}
      ...> Timex.Duration.to_time!(d)
      ** (ArgumentError) cannot convert {277, 46, 40} to time, reason: :invalid_time
  """
  @spec to_time!(__MODULE__.t()) :: Time.t() | no_return
  def to_time!(%__MODULE__{} = d) do
    {h, m, s, us} = to_clock(d)
    Time.from_erl!({h, m, s}, Timex.DateTime.Helpers.construct_microseconds(us, -1))
  end

  @doc """
  Converts a Time to a Duration

  ## Example

      iex> Timex.Duration.from_time(~T[01:01:30])
      %Timex.Duration{megaseconds: 0, seconds: 3690, microseconds: 0}
  """
  @spec from_time(Time.t()) :: __MODULE__.t()
  def from_time(%Time{} = t) do
    {us, _} = t.microsecond
    from_clock({t.hour, t.minute, t.second, us})
  end

  @doc """
  Converts a Duration to a string, using the ISO standard for formatting durations.

  ## Examples

      iex> d = %Timex.Duration{megaseconds: 0, seconds: 3661, microseconds: 0}
      ...> Timex.Duration.to_string(d)
      "PT1H1M1S"

      iex> d = %Timex.Duration{megaseconds: 102, seconds: 656013, microseconds: 33}
      ...> Timex.Duration.to_string(d)
      "P3Y3M3DT3H33M33.000033S"
  """
  @spec to_string(__MODULE__.t()) :: String.t()
  def to_string(%__MODULE__{} = duration) do
    Timex.Format.Duration.Formatter.format(duration)
  end

  @doc """
  Parses a duration string (in ISO-8601 format) into a Duration struct.
  """
  @spec parse(String.t()) :: {:ok, __MODULE__.t()} | {:error, term}
  defdelegate parse(str), to: Timex.Parse.Duration.Parser

  @doc """
  Parses a duration string into a Duration struct, using the provided parser module.
  """
  @spec parse(String.t(), module()) :: {:ok, __MODULE__.t()} | {:error, term}
  defdelegate parse(str, module), to: Timex.Parse.Duration.Parser

  @doc """
  Same as parse/1, but returns the Duration unwrapped, and raises on error
  """
  @spec parse!(String.t()) :: __MODULE__.t() | no_return
  defdelegate parse!(str), to: Timex.Parse.Duration.Parser

  @doc """
  Same as parse/2, but returns the Duration unwrapped, and raises on error
  """
  @spec parse!(String.t(), module()) :: __MODULE__.t() | no_return
  defdelegate parse!(str, module), to: Timex.Parse.Duration.Parser

  @microseconds_per_hour 3600 * 1_000_000

  @doc """
  Converts a Duration to a clock tuple, i.e. `{hour,minute,second,microsecond}`.

  ## Example

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 1, microseconds: 50}
      ...> Timex.Duration.to_clock(d)
      {277, 46, 41, 50}
  """
  def to_clock(%__MODULE__{} = duration) do
    us = to_microseconds(duration)

    hours = div(us, @microseconds_per_hour)
    total_secs = div(rem(us, @microseconds_per_hour), 1_000_000)
    mins = div(total_secs, 60)
    secs = rem(total_secs, 60)
    micros = rem(rem(us, @microseconds_per_hour), 1_000_000)

    {hours, mins, secs, micros}
  end

  @doc """
  Converts a clock tuple, i.e. `{hour, minute, second, microsecond}` to a Duration.

  ## Example

      iex> Timex.Duration.from_clock({1, 2, 3, 4})
      %Timex.Duration{megaseconds: 0, seconds: 3723, microseconds: 4}
  """
  def from_clock({hours, mins, secs, us}) do
    us = us + (secs + mins * 60) * 1_000_000 + hours * @microseconds_per_hour
    from_microseconds(us)
  end

  @doc """
  Converts a Duration to its value in microseconds

  ## Example

      iex> Duration.to_microseconds(Duration.from_milliseconds(10.5))
      10_500
  """
  @spec to_microseconds(__MODULE__.t()) :: integer
  @spec to_microseconds(__MODULE__.t(), to_options) :: integer
  def to_microseconds(%Duration{megaseconds: mega, seconds: sec, microseconds: micro}) do
    mega * 1_000_000_000_000 + sec * 1_000_000 + micro
  end

  def to_microseconds(%Duration{} = duration, _opts), do: to_microseconds(duration)

  @doc """
  Converts a Duration to its value in milliseconds

  ## Example

      iex> Duration.to_milliseconds(Duration.from_seconds(1))
      1000.0
      iex> Duration.to_milliseconds(Duration.from_seconds(1.543))
      1543.0
      iex> Duration.to_milliseconds(Duration.from_seconds(1.543), truncate: true)
      1543
  """
  @spec to_milliseconds(__MODULE__.t()) :: float
  @spec to_milliseconds(__MODULE__.t(), to_options) :: float | integer
  def to_milliseconds(%__MODULE__{} = d), do: to_microseconds(d) / 1_000
  def to_milliseconds(%__MODULE__{} = d, truncate: true), do: trunc(to_milliseconds(d))
  def to_milliseconds(%__MODULE__{} = d, _opts), do: to_milliseconds(d)

  @doc """
  Converts a Duration to its value in seconds

  ## Example

      iex> Duration.to_seconds(Duration.from_milliseconds(1500))
      1.5
      iex> Duration.to_seconds(Duration.from_milliseconds(1500), truncate: true)
      1
  """
  @spec to_seconds(__MODULE__.t()) :: float
  @spec to_seconds(__MODULE__.t(), to_options) :: float | integer
  def to_seconds(%__MODULE__{} = d), do: to_microseconds(d) / (1_000 * 1_000)
  def to_seconds(%__MODULE__{} = d, truncate: true), do: trunc(to_seconds(d))
  def to_seconds(%__MODULE__{} = d, _opts), do: to_seconds(d)

  @doc """
  Converts a Duration to its value in minutes

  ## Example

      iex> Duration.to_minutes(Duration.from_seconds(90))
      1.5
      iex> Duration.to_minutes(Duration.from_seconds(65), truncate: true)
      1
  """
  @spec to_minutes(__MODULE__.t()) :: float
  @spec to_minutes(__MODULE__.t(), to_options) :: float | integer
  def to_minutes(%__MODULE__{} = d), do: to_microseconds(d) / (1_000 * 1_000 * 60)
  def to_minutes(%__MODULE__{} = d, truncate: true), do: trunc(to_minutes(d))
  def to_minutes(%__MODULE__{} = d, _opts), do: to_minutes(d)

  @doc """
  Converts a Duration to its value in hours

  ## Example

      iex> Duration.to_hours(Duration.from_minutes(105))
      1.75
      iex> Duration.to_hours(Duration.from_minutes(105), truncate: true)
      1
  """
  @spec to_hours(__MODULE__.t()) :: float
  @spec to_hours(__MODULE__.t(), to_options) :: float | integer
  def to_hours(%__MODULE__{} = d), do: to_microseconds(d) / (1_000 * 1_000 * 60 * 60)
  def to_hours(%__MODULE__{} = d, truncate: true), do: trunc(to_hours(d))
  def to_hours(%__MODULE__{} = d, _opts), do: to_hours(d)

  @doc """
  Converts a Duration to its value in days

  ## Example

      iex> Duration.to_days(Duration.from_hours(6))
      0.25
      iex> Duration.to_days(Duration.from_hours(25), truncate: true)
      1
  """
  @spec to_days(__MODULE__.t()) :: float
  @spec to_days(__MODULE__.t(), to_options) :: float | integer
  def to_days(%__MODULE__{} = d), do: to_microseconds(d) / (1_000 * 1_000 * 60 * 60 * 24)
  def to_days(%__MODULE__{} = d, truncate: true), do: trunc(to_days(d))
  def to_days(%__MODULE__{} = d, _opts), do: to_days(d)

  @doc """
  Converts a Duration to its value in weeks

  ## Example

      iex> Duration.to_weeks(Duration.from_days(14))
      2.0
      iex> Duration.to_weeks(Duration.from_days(13), truncate: true)
      1
  """
  @spec to_weeks(__MODULE__.t()) :: float
  @spec to_weeks(__MODULE__.t(), to_options) :: float | integer
  def to_weeks(%__MODULE__{} = d), do: to_microseconds(d) / (1_000 * 1_000 * 60 * 60 * 24 * 7)
  def to_weeks(%__MODULE__{} = d, truncate: true), do: trunc(to_weeks(d))
  def to_weeks(%__MODULE__{} = d, _opts), do: to_weeks(d)

  Enum.each(
    [
      {:microseconds, 1 / @usecs_in_sec},
      {:milliseconds, 1 / @msecs_in_sec},
      {:seconds, 1},
      {:minutes, @secs_in_min},
      {:hours, @secs_in_hour},
      {:days, @secs_in_day},
      {:weeks, @secs_in_week}
    ],
    fn {type, coef} ->
      @spec to_microseconds(integer | float, unquote(type)) :: float
      def to_microseconds(value, unquote(type)),
        do: do_round(value * unquote(coef) * @usecs_in_sec)

      @spec to_milliseconds(integer | float, unquote(type)) :: float
      def to_milliseconds(value, unquote(type)),
        do: do_round(value * unquote(coef) * @msecs_in_sec)

      @spec to_seconds(integer | float, unquote(type)) :: float
      def to_seconds(value, unquote(type)),
        do: do_round(value * unquote(coef))

      @spec to_minutes(integer | float, unquote(type)) :: float
      def to_minutes(value, unquote(type)),
        do: do_round(value * unquote(coef) / @secs_in_min)

      @spec to_hours(integer | float, unquote(type)) :: float
      def to_hours(value, unquote(type)),
        do: do_round(value * unquote(coef) / @secs_in_hour)

      @spec to_days(integer | float, unquote(type)) :: float
      def to_days(value, unquote(type)),
        do: do_round(value * unquote(coef) / @secs_in_day)

      @spec to_weeks(integer | float, unquote(type)) :: float
      def to_weeks(value, unquote(type)),
        do: do_round(value * unquote(coef) / @secs_in_week)
    end
  )

  @doc """
  Converts an integer value representing microseconds to a Duration
  """
  @spec from_microseconds(integer) :: __MODULE__.t()
  def from_microseconds(us) when is_integer(us) do
    mega = div(us, 1_000_000_000_000)
    sec = div(rem(us, 1_000_000_000_000), 1_000_000)
    micro = rem(us, 1_000_000)
    %Duration{megaseconds: mega, seconds: sec, microseconds: micro}
  end

  def from_microseconds(us) when is_float(us) do
    from_microseconds(trunc(us))
  end

  @doc """
  Converts an integer value representing milliseconds to a Duration
  """
  @spec from_milliseconds(integer | float) :: __MODULE__.t()
  def from_milliseconds(ms), do: from_microseconds(ms * @usecs_in_msec)

  @doc """
  Converts an integer value representing seconds to a Duration
  """
  @spec from_seconds(integer | float) :: __MODULE__.t()
  def from_seconds(s), do: from_microseconds(s * @usecs_in_sec)

  @doc """
  Converts an integer value representing minutes to a Duration
  """
  @spec from_minutes(integer | float) :: __MODULE__.t()
  def from_minutes(m), do: from_seconds(m * @secs_in_min)

  @doc """
  Converts an integer value representing hours to a Duration
  """
  @spec from_hours(integer | float) :: __MODULE__.t()
  def from_hours(h), do: from_seconds(h * @secs_in_hour)

  @doc """
  Converts an integer value representing days to a Duration
  """
  @spec from_days(integer | float) :: __MODULE__.t()
  def from_days(d), do: from_seconds(d * @secs_in_day)

  @doc """
  Converts an integer value representing weeks to a Duration
  """
  @spec from_weeks(integer | float) :: __MODULE__.t()
  def from_weeks(w), do: from_seconds(w * @secs_in_week)

  @doc """
  Add one Duration to another.

  ## Examples

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 1, microseconds: 1}
      ...> Timex.Duration.add(d, d)
      %Timex.Duration{megaseconds: 2, seconds: 2, microseconds: 2}

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 750000, microseconds: 750000}
      ...> Timex.Duration.add(d, d)
      %Timex.Duration{megaseconds: 3, seconds: 500001, microseconds: 500000}
  """
  @spec add(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def add(
        %Duration{megaseconds: mega1, seconds: sec1, microseconds: micro1},
        %Duration{megaseconds: mega2, seconds: sec2, microseconds: micro2}
      ) do
    normalize(%Duration{
      megaseconds: mega1 + mega2,
      seconds: sec1 + sec2,
      microseconds: micro1 + micro2
    })
  end

  @doc """
  Subtract one Duration from another.

  ## Example

      iex> d1 = %Timex.Duration{megaseconds: 3, seconds: 3, microseconds: 3}
      ...> d2 = %Timex.Duration{megaseconds: 2, seconds: 2, microseconds: 2}
      ...> Timex.Duration.sub(d1, d2)
      %Timex.Duration{megaseconds: 1, seconds: 1, microseconds: 1}
  """
  @spec sub(__MODULE__.t(), __MODULE__.t()) :: __MODULE__.t()
  def sub(
        %Duration{megaseconds: mega1, seconds: sec1, microseconds: micro1},
        %Duration{megaseconds: mega2, seconds: sec2, microseconds: micro2}
      ) do
    normalize(%Duration{
      megaseconds: mega1 - mega2,
      seconds: sec1 - sec2,
      microseconds: micro1 - micro2
    })
  end

  @doc """
  Scale a Duration by some coefficient value, i.e. a scale of 2 is twice is long.

  ## Example

      iex> d = %Timex.Duration{megaseconds: 1, seconds: 1, microseconds: 1}
      ...> Timex.Duration.scale(d, 2)
      %Timex.Duration{megaseconds: 2, seconds: 2, microseconds: 2}
  """
  @spec scale(__MODULE__.t(), coefficient :: integer | float) :: __MODULE__.t()
  def scale(%Duration{megaseconds: mega, seconds: secs, microseconds: micro}, coef) do
    mega_s = mega * coef
    s_diff = mega_s * 1_000_000 - trunc(mega_s) * 1_000_000
    secs_s = s_diff + secs * coef
    us_diff = secs_s * 1_000_000 - trunc(secs_s) * 1_000_000
    us_s = us_diff + micro * coef
    extra_mega = div(trunc(secs_s), 1_000_000)
    mega_final = trunc(mega_s) + extra_mega
    extra_secs = div(trunc(us_s), 1_000_000)
    secs_final = trunc(secs_s) - extra_mega * 1_000_000 + extra_secs
    us_final = trunc(us_s) - extra_secs * 1_000_000
    normalize(%Duration{megaseconds: mega_final, seconds: secs_final, microseconds: us_final})
  end

  @doc """
  Invert a Duration, i.e. a positive duration becomes a negative one, and vice versa

  ## Example

      iex> d = %Timex.Duration{megaseconds: -1, seconds: -2, microseconds: -3}
      ...> Timex.Duration.invert(d)
      %Timex.Duration{megaseconds: 1, seconds: 2, microseconds: 3}
  """
  @spec invert(__MODULE__.t()) :: __MODULE__.t()
  def invert(%Duration{megaseconds: mega, seconds: sec, microseconds: micro}) do
    %Duration{megaseconds: -mega, seconds: -sec, microseconds: -micro}
  end

  @doc """
  Returns the absolute value of the provided Duration.

  ## Example

      iex> d = %Timex.Duration{megaseconds: -1, seconds: -2, microseconds: -3}
      ...> Timex.Duration.abs(d)
      %Timex.Duration{megaseconds: 1, seconds: 2, microseconds: 3}
  """
  @spec abs(__MODULE__.t()) :: __MODULE__.t()
  def abs(%Duration{} = duration) do
    us = to_microseconds(duration)

    if us < 0 do
      from_microseconds(-us)
    else
      duration
    end
  end

  @doc """
  Return a timestamp representing a time lapse of length 0.

      iex> Timex.Duration.zero |> Timex.Duration.to_seconds
      0.0

  Can be useful for operations on collections of durations. For instance,

      Enum.reduce(durations, Duration.zero, Duration.add(&1, &2))

  Can also be used to represent the timestamp of the start of the UNIX epoch,
  as all Erlang timestamps are relative to this point.
  """
  @spec zero() :: __MODULE__.t()
  def zero, do: %Duration{megaseconds: 0, seconds: 0, microseconds: 0}

  @doc """
  Returns the duration since the first day of year 0 to Epoch.

  ## Example

      iex> Timex.Duration.epoch()
      %Timex.Duration{megaseconds: 62_167, seconds: 219_200, microseconds: 0}
  """
  @spec epoch() :: __MODULE__.t()
  def epoch() do
    epoch(nil)
  end

  @doc """
  Returns the amount of time since the first day of year 0 to Epoch.

  The argument is an atom indicating the type of time units to return.

  The allowed unit type atoms are:
  - :microseconds
  - :milliseconds
  - :seconds
  - :minutes
  - :hours
  - :days
  - :weeks

  ## Examples

      iex> Timex.Duration.epoch(:seconds)
      62_167_219_200

  If the specified type is nil, a duration since the first day of year 0 to Epoch
  is returned.

      iex> Timex.Duration.epoch(nil)
      %Timex.Duration{megaseconds: 62_167, seconds: 219_200, microseconds: 0}
  """
  @spec epoch(nil) :: __MODULE__.t()
  @spec epoch(units) :: non_neg_integer
  def epoch(type) do
    seconds = :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

    case type do
      nil ->
        from_seconds(seconds)

      :microseconds ->
        seconds |> from_seconds |> to_microseconds

      :milliseconds ->
        seconds |> from_seconds |> to_milliseconds

      :seconds ->
        seconds

      :minutes ->
        seconds |> from_seconds |> to_minutes

      :hours ->
        seconds |> from_seconds |> to_hours

      :days ->
        seconds |> from_seconds |> to_days

      :weeks ->
        seconds |> from_seconds |> to_weeks
    end
  end

  @doc """
  Returns the amount of time since Epoch.

  The argument is an atom indicating the type of time units to return.

  The allowed unit type atoms are:
  - :microsecond(s)
  - :millisecond(s)
  - :second(s)
  - :minutes
  - :hours
  - :days
  - :weeks

  ## Examples

      iex> Timex.Duration.now(:seconds)
      1483141644

  When the argument is omitted or nil, a Duration is returned.

      iex> Timex.Duration.now
      %Timex.Duration{megaseconds: 1483, seconds: 141562, microseconds: 536938}
  """
  @spec now() :: __MODULE__.t()
  @spec now(nil) :: __MODULE__.t()
  @spec now(units) :: non_neg_integer
  def now(type \\ nil)

  @from_micros_units [:native, :nanosecond, :nanoseconds, :microsecond, :microseconds]

  def now(nil), do: from_microseconds(now(:microsecond))

  def now(unit) when unit in @from_micros_units,
    do: System.system_time(:microsecond)

  def now(ms) when ms in [:millisecond, :milliseconds],
    do: System.system_time(:millisecond)

  def now(s) when s in [:second, :seconds], do: System.system_time(:second)
  def now(:minutes), do: to_minutes(now(:microsecond))
  def now(:hours), do: to_hours(now(:microsecond))
  def now(:days), do: to_days(now(:microsecond))
  def now(:weeks), do: to_weeks(now(:microsecond))

  @doc """
  An alias for `Duration.diff/3`
  """
  defdelegate elapsed(duration, ref \\ nil, type \\ nil), to: __MODULE__, as: :diff

  @doc """
  This function determines the difference in time between two timestamps
  (represented by Duration structs). If the second timestamp is omitted,
  `Duration.now` will be used as the reference timestamp. If the first
  timestamp argument occurs before the second, the resulting measurement will
  be a negative value.

  The type argument is an atom indicating the units the measurement should be
  returned in. If no type argument is provided, a Duration will be returned.

  Valid measurement units for this function are:

      :microseconds, :milliseconds, :seconds, :minutes, :hours, :days, or :weeks

  ## Examples

      iex> alias Timex.Duration
      ...> d = Duration.from_erl({1457, 136000, 785000})
      ...> Duration.diff(d, Duration.zero, :days)
      16865
  """
  def diff(t1, t2, type \\ nil)

  def diff(%Duration{} = t1, nil, type), do: diff(t1, now(), type)

  def diff(%Duration{} = t1, %Duration{} = t2, type) do
    delta = do_diff(t1, t2)

    case type do
      nil -> delta
      :microseconds -> to_microseconds(delta, truncate: true)
      :milliseconds -> to_milliseconds(delta, truncate: true)
      :seconds -> to_seconds(delta, truncate: true)
      :minutes -> to_minutes(delta, truncate: true)
      :hours -> to_hours(delta, truncate: true)
      :days -> to_days(delta, truncate: true)
      :weeks -> to_weeks(delta, truncate: true)
    end
  end

  defp do_diff(%Duration{} = t1, %Duration{} = t2) do
    microsecs = :timer.now_diff(to_erl(t1), to_erl(t2))
    from_microseconds(microsecs)
  end

  @doc """
  Evaluates fun() and measures the elapsed time.

  Returns `{Duration.t, result}`.

  ## Example

      iex> {_timestamp, result} = Duration.measure(fn -> 2 * 2 end)
      ...> result == 4
      true
  """
  @spec measure((() -> any)) :: {__MODULE__.t(), any}
  def measure(fun) when is_function(fun) do
    {time, result} = :timer.tc(fun, [])
    {Duration.from_microseconds(time), result}
  end

  @doc """
  Evaluates `apply(fun, args)`, and measures execution time.

  Returns `{Duration.t, result}`.

  ## Example

      iex> {_timestamp, result} = Duration.measure(fn x, y -> x * y end, [2, 4])
      ...> result == 8
      true
  """
  @spec measure(fun, [any]) :: {__MODULE__.t(), any}
  def measure(fun, args) when is_function(fun) and is_list(args) do
    {time, result} = :timer.tc(fun, args)
    {Duration.from_microseconds(time), result}
  end

  @doc """
  Evaluates `apply(module, fun, args)`, and measures execution time.

  Returns `{Duration.t, result}`.

  ## Example

      iex> {_timestamp, result} = Duration.measure(Enum, :map, [[1,2], &(&1*2)])
      ...> result == [2, 4]
      true
  """
  @spec measure(module, atom, [any]) :: {__MODULE__.t(), any}
  def measure(module, fun, args)
      when is_atom(module) and is_atom(fun) and is_list(args) do
    {time, result} = :timer.tc(module, fun, args)
    {Duration.from_microseconds(time), result}
  end

  def normalize(%Duration{megaseconds: mega, seconds: sec, microseconds: micro}) do
    normalized = mega * 1_000_000_000_000 + sec * 1_000_000 + micro
    mega = div(normalized, 1_000_000_000_000)
    sec = div(rem(normalized, 1_000_000_000_000), 1_000_000)
    micro = rem(normalized, 1_000_000)
    %Duration{megaseconds: mega, seconds: sec, microseconds: micro}
  end

  defp do_round(value) when is_integer(value), do: value
  defp do_round(value) when is_float(value), do: Float.round(value, 6)
end
