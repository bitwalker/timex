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
  @type units :: :microseconds | :milliseconds |
                 :seconds | :minutes | :hours |
                 :days | :weeks
  @type measurement_units :: :microseconds | :milliseconds |
                 :seconds | :minutes | :hours
  @type to_options :: [truncate: boolean]

  @doc """
  Converts a Duration to an Erlang timestamp
  """
  @spec to_erl(__MODULE__.t) :: Types.timestamp
  def to_erl(%__MODULE__{} = d),
    do: {d.megaseconds, d.seconds, d.microseconds}

  @doc """
  Converts an Erlang timestamp to a Duration
  """
  @spec from_erl(Types.timestamp) :: __MODULE__.t
  def from_erl({mega, sec, micro}),
    do: %__MODULE__{megaseconds: mega, seconds: sec, microseconds: micro}

  @doc """
  Converts a Duration to a Time, if the duration fits within a 24-hour clock,
  if it does not, an error will be returned.
  """
  @spec to_time(__MODULE__.t) :: {:ok, Time.t} | {:error, atom}
  def to_time(%__MODULE__{} = d) do
    {h,m,s,us} = to_clock(d)
    Time.from_erl({h,m,s}, Timex.DateTime.Helpers.construct_microseconds(us))
  end

  @doc """
  Same as to_time/1, but returns the Time directly, and raises on error
  """
  @spec to_time!(__MODULE__.t) :: Time.t | no_return
  def to_time!(%__MODULE__{} = d) do
    {h,m,s,us} = to_clock(d)
    Time.from_erl!({h,m,s}, Timex.DateTime.Helpers.construct_microseconds(us))
  end

  @doc """
  Converts a Time to a Duration
  """
  @spec from_time(Time.t) :: __MODULE__.t
  def from_time(%Time{} = t) do
    {us, _} = t.microsecond
    from_clock({t.hour, t.minute, t.second, us})
  end

  @doc """
  Converts a Duration to a string, using the ISO standard for formatting durations.
  """
  @spec to_string(__MODULE__.t) :: String.t
  def to_string(%__MODULE__{} = duration) do
    Timex.Format.Duration.Formatter.format(duration)
  end

  @doc """
  Converts a Duration to a clock tuple, i.e. `{hour,minute,second,microsecond}`
  Helpful for if you want to convert a duration to a clock and vice versa
  """
  def to_clock(%__MODULE__{megaseconds: mega, seconds: sec, microseconds: micro}) do
    ss = (mega * 1_000_000)+sec
    ss = cond do
      micro > 1_000_000 -> ss+div(micro,1_000_000)
      :else -> ss
    end
    hour = div(ss, 60*60)
    min  = div(rem(ss, 60*60),60)
    secs = rem(rem(ss, 60*60),60)
    {hour,min,secs,rem(micro,1_000_000)}
  end

  @doc """
  Convers a clock tuple, i.e. `{hour,minute,second,microsecond}` to a Duration
  Helpful for if you want to convert a duration to a clock and vice vera
  """
  def from_clock({hour,minute,second,usec}) do
    total_seconds = (hour*60*60)+(minute*60)+second
    mega = div(total_seconds,1_000_000)
    ss = rem(total_seconds,1_000_000)
    from_erl({mega,ss,usec})
  end

  @doc """
  Converts a Duration to its value in microseconds

  ## Example

      iex> Duration.to_microseconds(Duration.from_milliseconds(10.5))
      10_500
  """
  @spec to_microseconds(__MODULE__.t) :: integer
  @spec to_microseconds(__MODULE__.t, to_options) :: integer
  def to_microseconds(%Duration{megaseconds: mega, seconds: sec, microseconds: micro}) do
    total_seconds = (mega * @million) + sec
    total_microseconds = (total_seconds * 1_000 * 1_000) + micro
    total_microseconds
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
  @spec to_milliseconds(__MODULE__.t) :: float
  @spec to_milliseconds(__MODULE__.t, to_options) :: float | integer
  def to_milliseconds(%__MODULE__{} = d),   do: to_microseconds(d) / 1_000
  def to_milliseconds(%__MODULE__{} = d, [truncate: true]), do: trunc(to_milliseconds(d))
  def to_milliseconds(%__MODULE__{} = d, _opts),            do: to_milliseconds(d)

  @doc """
  Converts a Duration to its value in seconds

  ## Example

      iex> Duration.to_seconds(Duration.from_milliseconds(1500))
      1.5
      iex> Duration.to_seconds(Duration.from_milliseconds(1500), truncate: true)
      1
  """
  @spec to_seconds(__MODULE__.t) :: float
  @spec to_seconds(__MODULE__.t, to_options) :: float | integer
  def to_seconds(%__MODULE__{} = d),   do: to_microseconds(d) / (1_000*1_000)
  def to_seconds(%__MODULE__{} = d, [truncate: true]), do: trunc(to_seconds(d))
  def to_seconds(%__MODULE__{} = d, _opts),            do: to_seconds(d)

  @doc """
  Converts a Duration to its value in minutes

  ## Example

      iex> Duration.to_minutes(Duration.from_seconds(90))
      1.5
      iex> Duration.to_minutes(Duration.from_seconds(65), truncate: true)
      1
  """
  @spec to_minutes(__MODULE__.t) :: float
  @spec to_minutes(__MODULE__.t, to_options) :: float | integer
  def to_minutes(%__MODULE__{} = d),   do: to_microseconds(d) / (1_000*1_000*60)
  def to_minutes(%__MODULE__{} = d, [truncate: true]), do: trunc(to_minutes(d))
  def to_minutes(%__MODULE__{} = d, _opts),            do: to_minutes(d)

  @doc """
  Converts a Duration to its value in hours

  ## Example

      iex> Duration.to_hours(Duration.from_minutes(105))
      1.75
      iex> Duration.to_hours(Duration.from_minutes(105), truncate: true)
      1
  """
  @spec to_hours(__MODULE__.t) :: float
  def to_hours(%__MODULE__{} = d),   do: to_microseconds(d) / (1_000*1_000*60*60)
  def to_hours(%__MODULE__{} = d, [truncate: true]), do: trunc(to_hours(d))
  def to_hours(%__MODULE__{} = d, _opts),            do: to_hours(d)

  @doc """
  Converts a Duration to its value in days

  ## Example

      iex> Duration.to_days(Duration.from_hours(6))
      0.25
      iex> Duration.to_days(Duration.from_hours(25), truncate: true)
      1
  """
  @spec to_days(__MODULE__.t) :: float
  def to_days(%__MODULE__{} = d),   do: to_microseconds(d) / (1_000*1_000*60*60*24)
  def to_days(%__MODULE__{} = d, [truncate: true]), do: trunc(to_days(d))
  def to_days(%__MODULE__{} = d, _opts),            do: to_days(d)

  @doc """
  Converts a Duration to its value in weeks

  ## Example

      iex> Duration.to_weeks(Duration.from_days(14))
      2.0
      iex> Duration.to_weeks(Duration.from_days(13), truncate: true)
      1
  """
  @spec to_weeks(__MODULE__.t) :: float
  def to_weeks(%__MODULE__{} = d),   do: to_microseconds(d) / (1_000*1_000*60*60*24*7)
  def to_weeks(%__MODULE__{} = d, [truncate: true]), do: trunc(to_weeks(d))
  def to_weeks(%__MODULE__{} = d, _opts),            do: to_weeks(d)

  Enum.each [{:microseconds, 1 / @usecs_in_sec},
             {:milliseconds, 1 / @msecs_in_sec},
             {:seconds, 1},
             {:minutes, @secs_in_min},
             {:hours, @secs_in_hour},
             {:days, @secs_in_day},
             {:weeks, @secs_in_week}], fn {type, coef} ->
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

  @doc """
  Converts an integer value representing microseconds to a Duration
  """
  @spec from_microseconds(integer) :: __MODULE__.t
  def from_microseconds(us) do
    us = round(us)
    { sec, micro } = mdivmod(us)
    { mega, sec }  = mdivmod(sec)
    %Duration{megaseconds: mega, seconds: sec, microseconds: micro}
  end

  @doc """
  Converts an integer value representing milliseconds to a Duration
  """
  @spec from_milliseconds(integer) :: __MODULE__.t
  def from_milliseconds(ms), do: from_microseconds(ms * @usecs_in_msec)

  @doc """
  Converts an integer value representing seconds to a Duration
  """
  @spec from_seconds(integer) :: __MODULE__.t
  def from_seconds(s), do: from_microseconds(s * @usecs_in_sec)

  @doc """
  Converts an integer value representing minutes to a Duration
  """
  @spec from_minutes(integer) :: __MODULE__.t
  def from_minutes(m), do: from_seconds(m * @secs_in_min)

  @doc """
  Converts an integer value representing hours to a Duration
  """
  @spec from_hours(integer) :: __MODULE__.t
  def from_hours(h), do: from_seconds(h * @secs_in_hour)

  @doc """
  Converts an integer value representing days to a Duration
  """
  @spec from_days(integer) :: __MODULE__.t
  def from_days(d), do: from_seconds(d * @secs_in_day)

  @doc """
  Converts an integer value representing weeks to a Duration
  """
  @spec from_weeks(integer) :: __MODULE__.t
  def from_weeks(w), do: from_seconds(w * @secs_in_week)

  @doc """
  Add one Duration to another.
  """
  @spec add(__MODULE__.t, __MODULE__.t) :: __MODULE__.t
  def add(%Duration{megaseconds: mega1, seconds: sec1, microseconds: micro1},
          %Duration{megaseconds: mega2, seconds: sec2, microseconds: micro2}) do
    normalize(%Duration{megaseconds: mega1+mega2,
                        seconds: sec1+sec2,
                        microseconds: micro1+micro2 })
  end

  @doc """
  Subtract one Duration from another.
  """
  @spec sub(__MODULE__.t, __MODULE__.t) :: __MODULE__.t
  def sub(%Duration{megaseconds: mega1, seconds: sec1, microseconds: micro1},
          %Duration{megaseconds: mega2, seconds: sec2, microseconds: micro2}) do
    normalize(%Duration{megaseconds: mega1-mega2,
                        seconds: sec1-sec2,
                        microseconds: micro1-micro2 })
  end

  @doc """
  Scale a Duration by some coefficient value, i.e. a scale of 2 is twice is long.
  """
  @spec scale(__MODULE__.t, coefficient :: integer) :: __MODULE__.t
  def scale(%Duration{megaseconds: mega, seconds: secs, microseconds: micro}, coef) do
    normalize(%Duration{megaseconds: mega*coef,
                        seconds: secs*coef,
                        microseconds: micro*coef })
  end

  @doc """
  Invert a Duration, i.e. a positive duration becomes a negative one, and vice versa
  """
  @spec invert(__MODULE__.t) :: __MODULE__.t
  def invert(%Duration{megaseconds: mega, seconds: sec, microseconds: micro}) do
    %Duration{megaseconds: -mega, seconds: -sec, microseconds: -micro }
  end

  @doc """
  Returns the absolute value of the provided Duration.
  """
  @spec abs(__MODULE__.t) :: __MODULE__.t
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
  @spec zero() :: __MODULE__.t
  def zero, do: %Duration{megaseconds: 0, seconds: 0, microseconds: 0}

  @doc """
  Return time interval since the first day of year 0 to Epoch.
  """
  @spec epoch() :: __MODULE__.t
  @spec epoch(units) :: __MODULE__.t
  def epoch() do
    from_seconds(epoch(:seconds))
  end
  def epoch(type) do
    seconds = :calendar.datetime_to_gregorian_seconds({{1970,1,1}, {0,0,0}})
    case type do
      nil ->
        from_seconds(seconds)
      :microseconds -> seconds |> from_seconds |> to_microseconds
      :milliseconds -> seconds |> from_seconds |> to_milliseconds
      :seconds      -> seconds
      :minutes      -> seconds |> from_seconds |> to_minutes
      :hours        -> seconds |> from_seconds |> to_hours
      :days         -> seconds |> from_seconds |> to_days
      :weeks        -> seconds |> from_seconds |> to_weeks
    end
  end

  @doc """
  Time interval since Epoch.

  The argument is an atom indicating the type of time units to return (see
  convert/2 for supported values).

  When the argument is omitted, the return value's format is { megasecs, seconds, microsecs }.
  """
  @spec now() :: __MODULE__.t
  @spec now(units) :: non_neg_integer
  def now(type \\ nil)

  def now(nil),           do: :os.system_time(:micro_seconds) |> from_microseconds
  def now(:microseconds), do: :os.system_time(:micro_seconds)
  def now(:milliseconds), do: :os.system_time(:milli_seconds)
  def now(:seconds),      do: :os.system_time(:seconds)
  def now(:minutes),      do: :os.system_time(:seconds) |> from_seconds |> to_minutes
  def now(:hours),        do: :os.system_time(:seconds) |> from_seconds |> to_hours
  def now(:days),         do: :os.system_time(:seconds) |> from_seconds |> to_days
  def now(:weeks),        do: :os.system_time(:seconds) |> from_seconds |> to_weeks

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

      :microseconds, :milliseconds, :seconds, :minutes, :hours, or :weeks

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
      :seconds      -> to_seconds(delta, truncate: true)
      :minutes      -> to_minutes(delta, truncate: true)
      :hours        -> to_hours(delta, truncate: true)
      :days         -> to_days(delta, truncate: true)
      :weeks        -> to_weeks(delta, truncate: true)
    end
  end

  defp do_diff(%Duration{} = t1, %Duration{} = t2) do
    microsecs = :timer.now_diff(to_erl(t1), to_erl(t2))
    mega  = div(microsecs, 1_000_000_000_000)
    secs  = div(microsecs - mega*1_000_000_000_000, 1_000_000)
    micro = rem(microsecs, 1_000_000)
    %Duration{megaseconds: mega, seconds: secs, microseconds: micro}
  end

  @doc """
  Evaluates fun() and measures the elapsed time.

  Returns `{Duration.t, result}`.

  ## Example

      iex> {_timestamp, result} = Duration.measure(fn -> 2 * 2 end)
      ...> result == 4
      true
  """
  @spec measure((() -> any)) :: {__MODULE__.t, any}
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
  @spec measure(fun, [any]) :: {__MODULE__.t, any}
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
  @spec measure(module, atom, [any]) :: {__MODULE__.t, any}
  def measure(module, fun, args)
    when is_atom(module) and is_atom(fun) and is_list(args) do
    {time, result} = :timer.tc(module, fun, args)
    {Duration.from_microseconds(time), result}
  end

  defp normalize(%Duration{megaseconds: mega, seconds: sec, microseconds: micro}) do
    # TODO: check for negative values
    { sec, micro } = mdivmod(sec, micro)
    { mega, sec }  = mdivmod(mega, sec)
    %Duration{megaseconds: mega, seconds: sec, microseconds: micro}
  end

  defp divmod(a, b),          do: {div(a, b), rem(a, b)}
  defp divmod(initial, a, b), do: {initial + div(a, b), rem(a, b)}

  defp mdivmod(a),          do: divmod(a, 1_000_000)
  defp mdivmod(initial, a), do: divmod(initial, a, 1_000_000)

  defp do_round(value) when is_integer(value), do: value
  defp do_round(value) when is_float(value),   do: Float.round(value, 6)

end
