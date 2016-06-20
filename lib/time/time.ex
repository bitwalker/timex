defmodule Timex.Time do
  @moduledoc """
  This module provides a friendly API for working with Erlang
  timestamps, i.e. `{megasecs, secs, microsecs}`. In addition,
  it provides an easy way to wrap the measurement of function
  execution time (via `measure`).
  """
  alias Timex.Types
  use Timex.Constants
  import Timex.Macros

  @type units :: :microseconds | :milliseconds | :seconds | :minutes | :hours | :days | :weeks | :hms

  @doc """
  Converts a timestamp to its value in microseconds
  """
  @spec to_microseconds(Types.timestamp) :: integer
  def to_microseconds({mega, sec, micro}) do
    total_seconds = (mega * @million) + sec
    total_microseconds = (total_seconds * 1_000 * 1_000) + micro
    total_microseconds
  end
  defdeprecated to_usecs(timestamp), "use to_microseconds/1 instead", do: to_microseconds(timestamp)
  @doc """
  Converts a timestamp to its value in milliseconds
  """
  @spec to_milliseconds(Types.timestamp) :: float
  def to_milliseconds({_, _, _} = ts), do: to_microseconds(ts) / 1_000
  defdeprecated to_msecs(timestamp), "use to_milliseconds/1 instead", do: to_milliseconds(timestamp)
  @doc """
  Converts a timestamp to its value in seconds
  """
  @spec to_seconds(Types.timestamp) :: float
  def to_seconds({_, _, _} = ts), do: to_milliseconds(ts) / 1_000
  defdeprecated to_secs(timestamp), "use to_seconds/1 instead", do: to_seconds(timestamp)
  @doc """
  Converts a timestamp to its value in minutes
  """
  @spec to_minutes(Types.timestamp) :: float
  def to_minutes(timestamp), do: to_seconds(timestamp) / 60
  defdeprecated to_mins(timestamp), "use to_minutes/1 instead", do: to_minutes(timestamp)
  @doc """
  Converts a timestamp to its value in hours
  """
  @spec to_hours(Types.timestamp) :: float
  def to_hours(timestamp), do: to_minutes(timestamp) / 60
  @doc """
  Converts a timestamp to its value in days
  """
  @spec to_days(Types.timestamp) :: float
  def to_days(timestamp), do: to_hours(timestamp) / 24
  @doc """
  Converts a timestamp to its value in weeks
  """
  @spec to_weeks(Types.timestamp) :: float
  def to_weeks(timestamp), do: (to_days(timestamp) / 365) * 52

  Enum.each [{:microseconds, 1 / @usecs_in_sec, :usecs},
             {:milliseconds, 1 / @msecs_in_sec, :msecs},
             {:seconds, 1, :secs},
             {:minutes, @secs_in_min, :mins},
             {:hours, @secs_in_hour, :hours},
             {:days, @secs_in_day, :days},
             {:weeks, @secs_in_week, :weeks}], fn {type, coef, type_alias} ->
    @spec to_microseconds(integer | float, unquote(type)) :: float
    def to_microseconds(value, unquote(type)), do: do_round(value * unquote(coef) * @usecs_in_sec)
    if not type in [:hours, :days, :weeks] do
      def to_microseconds(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_microseconds(value, unquote(type))
      end
    end

    @spec to_milliseconds(integer | float, unquote(type)) :: float
    def to_milliseconds(value, unquote(type)), do: do_round(value * unquote(coef) * @msecs_in_sec)
    if not type in [:hours, :days, :weeks] do
      def to_milliseconds(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_milliseconds(value, unquote(type))
      end
    end

    @spec to_seconds(integer | float, unquote(type)) :: float
    def to_seconds(value, unquote(type)),  do: do_round(value * unquote(coef))
    if not type in [:hours, :days, :weeks] do
      def to_seconds(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_seconds(value, unquote(type))
      end
    end

    @spec to_minutes(integer | float, unquote(type)) :: float
    def to_minutes(value, unquote(type)),  do: do_round(value * unquote(coef) / @secs_in_min)
    if not type in [:hours, :days, :weeks] do
      def to_minutes(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_minutes(value, unquote(type))
      end
    end

    @spec to_hours(integer | float, unquote(type)) :: float
    def to_hours(value, unquote(type)), do: do_round(value * unquote(coef) / @secs_in_hour)
    if not type in [:hours, :days, :weeks] do
      def to_hours(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_hours(value, unquote(type))
      end
    end

    @spec to_days(integer | float, unquote(type)) :: float
    def to_days(value, unquote(type)),  do: do_round(value * unquote(coef) / @secs_in_day)
    if not type in [:hours, :days, :weeks] do
      def to_days(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_days(value, unquote(type))
      end
    end

    @spec to_weeks(integer | float, unquote(type)) :: float
    def to_weeks(value, unquote(type)), do: do_round(value * unquote(coef) / @secs_in_week)
    if not type in [:hours, :days, :weeks] do
      def to_weeks(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        to_weeks(value, unquote(type))
      end
    end
  end

  Enum.each [:to_microseconds, :to_milliseconds, :to_seconds, :to_minutes, :to_hours, :to_days, :to_weeks], fn name ->
    @spec unquote(name)({integer | float, integer | float, integer | float}, :hms) :: float
    def unquote(name)({hours, minutes, seconds}, :hms), do: unquote(name)(hours * @secs_in_hour + minutes * @secs_in_min + seconds, :seconds)
  end

  defdeprecated to_usecs(value, type), "use to_microseconds/2 instead", do: to_microseconds(value, type)
  defdeprecated to_msecs(value, type), "use to_milliseconds/2 instead", do: to_milliseconds(value, type)
  defdeprecated to_secs(value, type), "use to_seconds/2 instead", do: to_seconds(value, type)
  defdeprecated to_mins(value, type), "use to_minutes/2 intead", do: to_minutes(value, type)

  @doc """
  Converts an hour between 0..24 to {1..12, :am/:pm}

  ## Examples

      iex> Timex.Time.to_12hour_clock(23)
      {11, :pm}

  """
  def to_12hour_clock(hour) when hour in 0..24 do
    case hour do
      hour when hour in [0, 24] -> {12, :am}
      hour when hour < 12       -> {hour, :am}
      hour when hour === 12     -> {12, :pm}
      hour when hour > 12       -> {hour - 12, :pm}
    end
  end

  @doc """
  Converts an hour between 1..12 in either am or pm, to value between 0..24

  ## Examples

      iex> Timex.Time.to_24hour_clock(7, :pm)
      19

  """
  def to_24hour_clock(hour, am_or_pm) when hour in 1..12 and am_or_pm in [:am, :pm] do
    case am_or_pm do
      :am when hour === 12 -> 0
      :am                  -> hour
      :pm when hour === 12 -> hour
      :pm                  -> hour + 12
    end
  end

  @doc """
  Converts the given input value and unit to an Erlang timestamp.

  ## Example

      iex> Timex.Time.from(1500, :seconds)
      {0, 1500, 0}

  """
  @spec from(integer | Types.time, units) :: Types.timestamp
  def from(value, :usecs) do
    IO.write :stderr, "warning: :usecs is a deprecated unit name, use :microseconds instead\n"
    from(value, :microseconds)
  end
  def from(value, :msecs) do
    IO.write :stderr, "warning: :msecs is a deprecated unit name, use :milliseconds instead\n"
    from(value, :milliseconds)
  end
  def from(value, :secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    from(value, :seconds)
  end
  def from(value, :mins) do
    IO.write :stderr, "warning: :mins is a deprecated unit name, use :minutes instead\n"
    from(value, :minutes)
  end
  def from(value, :microseconds) do
    value = round(value)
    { sec, micro } = mdivmod(value)
    { mega, sec }  = mdivmod(sec)
    { mega, sec, micro }
  end
  def from(value, :milliseconds), do: from(value * @usecs_in_msec, :microseconds)
  def from(value, :seconds),      do: from(value * @usecs_in_sec, :microseconds)
  def from(value, :minutes),      do: from(value * @secs_in_min, :seconds)
  def from(value, :hours),        do: from(value * @secs_in_hour, :seconds)
  def from(value, :days),         do: from(value * @secs_in_day, :seconds)
  def from(value, :weeks),        do: from(value * @secs_in_week, :seconds)
  def from(value, :hms),          do: from(to_seconds(value, :hms), :seconds)

  Enum.each [{:microseconds, :usecs},
             {:milliseconds, :msecs},
             {:seconds, :secs},
             {:minutes, :mins},
             :hours, :days, :weeks, :hms], fn
    {type, type_alias} ->
      def to_timestamp(value, unquote(type)), do: from(value, unquote(type))
      def to_timestamp(value, unquote(type_alias)) do
        IO.write :stderr, "warning: #{unquote(type_alias)} is a deprecated unit name, use #{unquote(type)} instead\n"
        from(value, unquote(type))
      end
    type ->
      def to_timestamp(value, unquote(type)), do: from(value, unquote(type))
  end

  def add({mega1,sec1,micro1}, {mega2,sec2,micro2}) do
    normalize({ mega1+mega2, sec1+sec2, micro1+micro2 })
  end

  def sub({mega1,sec1,micro1}, {mega2,sec2,micro2}) do
    normalize({ mega1-mega2, sec1-sec2, micro1-micro2 })
  end

  def scale({mega, secs, micro}, coef) do
    normalize({ mega*coef, secs*coef, micro*coef })
  end

  def invert({mega, sec, micro}) do
    { -mega, -sec, -micro }
  end

  def abs(timestamp={mega, sec, micro}) do
    value = cond do
      mega != 0 -> mega
      sec != 0  -> sec
      true      -> micro
    end

    if value < 0 do
      invert(timestamp)
    else
      timestamp
    end
  end

  @doc """
  Return a timestamp representing a time lapse of length 0.

      Time.convert(Time.zero, :seconds)
      #=> 0

  Can be useful for operations on collections of timestamps. For instance,

      Enum.reduce(timestamps, Time.zero, Time.add(&1, &2))

  Can also be used to represent the timestamp of the start of the UNIX epoch,
  as all Erlang timestamps are relative to this point.

  """
  def zero, do: {0, 0, 0}

  @doc """
  Convert timestamp in the form { megasecs, seconds, microsecs } to the
  specified time units.

  ## Supported units

  - :microseconds
  - :milliseconds
  - :seconds
  - :minutes
  - :hours
  - :days
  - :weeks
  """
  def convert(timestamp, type \\ :timestamp)
  def convert(timestamp, :timestamp),    do: timestamp
  def convert(timestamp, :microseconds), do: to_microseconds(timestamp)
  def convert(timestamp, :milliseconds), do: to_milliseconds(timestamp)
  def convert(timestamp, :seconds),      do: to_seconds(timestamp)
  def convert(timestamp, :minutes),      do: to_minutes(timestamp)
  def convert(timestamp, :hours),        do: to_hours(timestamp)
  def convert(timestamp, :days),         do: to_days(timestamp)
  def convert(timestamp, :weeks),        do: to_weeks(timestamp)

  def convert(timestamp, :usecs) do
    IO.write :stderr, "warning: :usecs is a deprecated unit name, use :microseconds instead\n"
    to_microseconds(timestamp)
  end
  def convert(timestamp, :msecs) do
    IO.write :stderr, "warning: :msecs is a deprecated unit name, use :milliseconds instead\n"
    to_milliseconds(timestamp)
  end
  def convert(timestamp, :secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    to_seconds(timestamp)
  end
  def convert(timestamp, :mins) do
    IO.write :stderr, "warning: :mins is a deprecated unit name, use :minutes instead\n"
    to_minutes(timestamp)
  end

  @doc """
  Return time interval since the first day of year 0 to Epoch.
  """
  def epoch(type \\ :timestamp)

  def epoch(:timestamp) do
    seconds = :calendar.datetime_to_gregorian_seconds({ {1970,1,1}, {0,0,0} })
    { mega, sec } = mdivmod(seconds)
    { mega, sec, 0 }
  end
  def epoch(type), do: convert(epoch(), type)

  @doc """
  Time interval since Epoch.

  The argument is an atom indicating the type of time units to return (see
  convert/2 for supported values).

  When the argument is omitted, the return value's format is { megasecs, seconds, microsecs }.
  """
  def now(type \\ :timestamp)

  def now(:usecs) do
    IO.write :stderr, "warning: :usecs is a deprecated unit name, use :microseconds instead\n"
    now(:microseconds)
  end
  def now(:msecs) do
    IO.write :stderr, "warning: :msecs is a deprecated unit name, use :milliseconds instead\n"
    now(:milliseconds)
  end
  def now(:secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    now(:seconds)
  end
  def now(:mins) do
    IO.write :stderr, "warning: :mins is a deprecated unit name, use :mins instead\n"
    now(:minutes)
  end
  case Timex.Utils.get_otp_release do
    ver when ver >= 18 ->
      def now(:timestamp),    do: :os.system_time(:micro_seconds) |> from(:microseconds)
      def now(:microseconds), do: :os.system_time(:micro_seconds)
      def now(:milliseconds), do: :os.system_time(:milli_seconds)
      def now(:seconds),      do: :os.system_time(:seconds)
      def now(type),          do: now(:timestamp) |> convert(type)
    _ ->
      def now(:timestamp), do: :os.timestamp
      def now(type),       do: :os.timestamp |> convert(type)
  end

  @doc """
  Time interval between timestamp and now. If timestamp is after now in time, the
  return value will be negative. Timestamp must be in format:

      { megasecs, seconds, microseconds }.

  The second argument is an atom indicating the type of time units to return:

      :microseconds, :milliseconds, :seconds, :minutes, or hours (:hours).

  When the second argument is omitted, the return value's format is

      { megasecs, seconds, microsecs }.
  """
  def elapsed(timestamp, type \\ :timestamp)

  def elapsed(timestamp = {_,_,_}, type) do
    elapsed(timestamp, now(), type)
  end

  def elapsed(timestamp = {_,_,_}, reference_time = {_,_,_}, type) do
    diff(reference_time, timestamp) |> convert(type)
  end

  @doc """
  Time interval between two timestamps. If the first timestamp comes before the
  second one in time, the return value will be negative. Timestamp must be in format:

      { megasecs, seconds, microseconds }.

  The third argument is an atom indicating the type of time units to return:

      :microseconds, :milliseconds, :seconds, :minutes, or :hours

  When the third argument is omitted, the return value's format is:

      { megasecs, seconds, microsecs }.


  ## Examples

      iex> use Timex
      ...> Time.diff({1457, 136000, 785000}, Time.zero, :days)
      16865
  """
  def diff(t1, t2, type \\ :timestamp)

  def diff({_,_,_} = t1, {_,_,_} = t2, :timestamp) do
    microsecs = :timer.now_diff(t1, t2)
    mega  = div(microsecs, 1_000_000_000_000)
    secs  = div(microsecs - mega*1_000_000_000_000, 1_000_000)
    micro = rem(microsecs, 1_000_000)
    {mega, secs, micro}
  end

  def diff(t1 = {_,_,_}, t2 = {_,_,_}, type) do
    trunc(convert(diff(t1, t2), type))
  end

  @doc """
  Evaluates fun() and measures the elapsed time.

  Returns {timestamp, result}, timestamp is the usual `{ megasecs, seconds, microsecs }`.

  ## Example

      iex> {_timestamp, result} = Time.measure(fn -> 2 * 2 end)
      ...> result == 4
      true

  """
  @spec measure((() -> any)) :: { Types.timestamp, any }
  def measure(fun), do: do_measure(fun)

  @doc """
  Evaluates apply(fun, args). Otherwise works like measure/1
  """
  @spec measure(fun, [any]) :: { Types.timestamp, any }
  def measure(fun, args), do: do_measure(fun, args)

  @doc """
  Evaluates apply(module, fun, args). Otherwise works like measure/1
  """
  @spec measure(module, atom, [any]) :: { Types.timestamp, any }
  def measure(module, fun, args), do: do_measure(module, fun, args)

  case Timex.Utils.get_otp_release do
    ver when ver >= 18 ->
      defp do_measure(m, f \\ nil, a \\ []) do
        start_time = :erlang.monotonic_time(:micro_seconds)
        result = cond do
          is_function(m) && f == nil             -> apply(m, [])
          is_function(m) && is_list(f)           -> apply(m, f)
          is_atom(m) && is_atom(f) && is_list(a) -> apply(m, f, a)
          true -> {:error, "Invalid arguments for do_measure!"}
        end
        end_time   = :erlang.monotonic_time(:micro_seconds)
        {(end_time - start_time) |> to_timestamp(:microseconds), result}
      end
    _ ->
      defp do_measure(m, f \\ nil, a \\ []) do
        {time, result} = cond do
          is_function(m) && f == nil             -> :timer.tc(m)
          is_function(m) && is_list(f)           -> :timer.tc(m, f)
          is_atom(m) && is_atom(f) && is_list(a) -> :timer.tc(m, f, a)
          true -> {:error, "Invalid arguments for do_measure!"}
        end
        {to_timestamp(time, :microseconds), result}
      end
  end

  defp normalize({mega, sec, micro}) do
    # TODO: check for negative values
    { sec, micro } = mdivmod(sec, micro)

    { mega, sec } = mdivmod(mega, sec)

    { mega, sec, micro }
  end

  defp divmod(a, b) do
    { div(a, b), rem(a, b) }
  end

  defp divmod(initial, a, b) do
    { initial + div(a, b), rem(a, b) }
  end

  defp mdivmod(a) do
    divmod(a, 1_000_000)
  end

  defp mdivmod(initial, a) do
    divmod(initial, a, 1_000_000)
  end

  defp do_round(value) when is_integer(value), do: value
  defp do_round(value) when is_float(value),   do: Float.round(value, 6)

end
