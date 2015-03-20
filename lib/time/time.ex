defmodule Timex.Time do

  @usecs_in_sec 1_000_000
  @usecs_in_msec 1_000

  @msecs_in_sec 1_000

  @secs_in_min 60
  @secs_in_hour @secs_in_min * 60
  @secs_in_day @secs_in_hour * 24
  @secs_in_week @secs_in_day * 7

  @million 1_000_000

  Enum.each [usecs: @usecs_in_sec, msecs: @msecs_in_sec], fn {type, coef} ->
    def to_usecs(value, unquote(type)), do: value * @usecs_in_sec / unquote(coef)
    def to_msecs(value, unquote(type)), do: value * @msecs_in_sec / unquote(coef)
    def to_secs(value, unquote(type)),  do: value / unquote(coef)
    def to_mins(value, unquote(type)),  do: value / unquote(coef) / @secs_in_min
    def to_hours(value, unquote(type)), do: value / unquote(coef) / @secs_in_hour
    def to_days(value, unquote(type)),  do: value / unquote(coef) / @secs_in_day
    def to_weeks(value, unquote(type)), do: value / unquote(coef) / @secs_in_week
  end

  Enum.each [secs: 1, mins: @secs_in_min, hours: @secs_in_hour, days: @secs_in_day, weeks: @secs_in_week], fn {type, coef} ->
    def unquote(type)(value), do: value * unquote(coef)
    def to_usecs(value, unquote(type)), do: value * unquote(coef) * @usecs_in_sec
    def to_msecs(value, unquote(type)), do: value * unquote(coef) * @msecs_in_sec
    def to_secs(value, unquote(type)),  do: value * unquote(coef)
    def to_mins(value, unquote(type)),  do: value * unquote(coef) / @secs_in_min
    def to_hours(value, unquote(type)), do: value * unquote(coef) / @secs_in_hour
    def to_days(value, unquote(type)),  do: value * unquote(coef) / @secs_in_day
    def to_weeks(value, unquote(type)), do: value * unquote(coef) / @secs_in_week
  end


  Enum.each [:to_usecs, :to_msecs, :to_secs, :to_mins, :to_hours, :to_days, :to_weeks], fn name ->
    def unquote(name)({hours, minutes, seconds}, :hms), do: unquote(name)(hours * @secs_in_hour + minutes * @secs_in_min + seconds, :secs)
  end

  @doc """
  Converts an hour between 0..24 to {1..12, :am/:pm}

  ## Examples

    iex> to_12hour_clock(23)
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

    iex> to_24hour_clock(7, :pm)
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

  def from(value, :usecs) do
    value = round(value)
    { sec, micro } = mdivmod(value)
    { mega, sec }  = mdivmod(sec)
    { mega, sec, micro }
  end

  def from(value, :msecs), do: from(value * @usecs_in_msec, :usecs)
  def from(value, :secs),  do: from(value * @usecs_in_sec, :usecs)
  def from(value, :mins),  do: from(value * @secs_in_min, :secs)
  def from(value, :hours), do: from(value * @secs_in_hour, :secs)
  def from(value, :days),  do: from(value * @secs_in_day, :secs)
  def from(value, :weeks), do: from(value * @secs_in_week, :secs)
  def from(value, :hms),   do: from(to_secs(value, :hms), :secs)

  def to_usecs({mega, sec, micro}), do: (mega * @million + sec) * @million + micro
  def to_msecs({_, _, _} = ts),     do: to_usecs(ts) / @usecs_in_msec
  def to_secs({_, _, _} = ts),      do: to_usecs(ts) / @usecs_in_sec
  def to_mins(timestamp),           do: to_secs(timestamp) / @secs_in_min
  def to_hours(timestamp),          do: to_secs(timestamp) / @secs_in_hour
  def to_days(timestamp),           do: to_secs(timestamp) / @secs_in_day
  def to_weeks(timestamp),          do: to_secs(timestamp) / @secs_in_week

  Enum.each [:usecs, :msecs, :secs, :mins, :hours, :days, :weeks, :hms], fn type ->
    def to_timestamp(value, unquote(type)), do: from(value, unquote(type))
  end

  def add({mega1,sec1,micro1}, {mega2,sec2,micro2}) do
    normalize { mega1+mega2, sec1+sec2, micro1+micro2 }
  end

  def sub({mega1,sec1,micro1}, {mega2,sec2,micro2}) do
    normalize { mega1-mega2, sec1-sec2, micro1-micro2 }
  end

  def scale({mega, secs, micro}, coef) do
    normalize { mega*coef, secs*coef, micro*coef }
  end

  def invert({mega, sec, micro}) do
    { -mega, -sec, -micro }
  end

  def abs(timestamp={mega, sec, micro}) do
    cond do
      mega != 0 -> value = mega
      sec != 0  -> value = sec
      true      -> value = micro
    end

    if value < 0 do
      invert(timestamp)
    else
      timestamp
    end
  end

  @doc """
  Return a timestamp representing a time lapse of length 0.

    Time.convert(Time.zero, :secs)
    #=> 0

  Can be useful for operations on collections of timestamps. For instance,

    Enum.reduce timestamps, Time.zero, Time.add(&1, &2)

  """
  def zero, do: {0, 0, 0}

  @doc """
  Convert timestamp in the form { megasecs, seconds, microsecs } to the
  specified time units.

  Supported units: microseconds (:usecs), milliseconds (:msecs), seconds (:secs),
  minutes (:mins), hours (:hours), days (:days), or weeks (:weeks).
  """
  def convert(timestamp, type \\ :timestamp)
  def convert(timestamp, :timestamp), do: timestamp
  def convert(timestamp, :usecs), do: to_usecs(timestamp)
  def convert(timestamp, :msecs), do: to_msecs(timestamp)
  def convert(timestamp, :secs),  do: to_secs(timestamp)
  def convert(timestamp, :mins),  do: to_mins(timestamp)
  def convert(timestamp, :hours), do: to_hours(timestamp)
  def convert(timestamp, :days),  do: to_days(timestamp)
  def convert(timestamp, :weeks), do: to_weeks(timestamp)

  @doc """
  Return time interval since the first day of year 0 to Epoch.
  """
  def epoch(type \\ :timestamp)

  def epoch(:timestamp) do
    seconds = :calendar.datetime_to_gregorian_seconds({ {1970,1,1}, {0,0,0} })
    { mega, sec } = mdivmod(seconds)
    { mega, sec, 0 }
  end

  def epoch(type) do
    convert(epoch, type)
  end

  @doc """
  Time interval since Epoch.

  The argument is an atom indicating the type of time units to return (see
  convert/2 for supported values).

  When the argument is omitted, the return value's format is { megasecs, seconds, microsecs }.
  """
  def now(type \\ :timestamp)

  def now(:timestamp) do
    :os.timestamp
  end

  def now(type) do
    convert(now, type)
  end

  @doc """
  Time interval between timestamp and now. If timestamp is after now in time, the
  return value will be negative. Timestamp must be in format { megasecs, seconds,
  microseconds }.

  The second argument is an atom indicating the type of time units to return:
  microseconds (:usecs), milliseconds (:msecs), seconds (:secs), minutes (:mins),
  or hours (:hours).

  When the second argument is omitted, the return value's format is { megasecs,
  seconds, microsecs }.
  """
  def elapsed(timestamp, type \\ :timestamp)

  def elapsed(timestamp = {_,_,_}, type) do
    elapsed(timestamp, now, type)
  end

  def elapsed(timestamp = {_,_,_}, reference_time = {_,_,_}, type) do
    diff(reference_time, timestamp) |> convert(type)
  end

  @doc """
  Time interval between two timestamps. If the first timestamp comes before the
  second one in time, the return value will be negative. Timestamp must be in format
  { megasecs, seconds, microseconds }.

  The third argument is an atom indicating the type of time units to return:
  microseconds (:usecs), milliseconds (:msecs), seconds (:secs), minutes (:mins),
  or hours (:hours).

  When the third argument is omitted, the return value's format is { megasecs,
  seconds, microsecs }.
  """
  def diff(t1, t2, type \\ :timestamp)

  def diff({mega1,secs1,micro1}, {mega2,secs2,micro2}, :timestamp) do
    # TODO: normalize the result
    {mega1 - mega2, secs1 - secs2, micro1 - micro2}
  end

  def diff(t1 = {_,_,_}, t2 = {_,_,_}, type) do
    convert(diff(t1, t2), type)
  end

  def measure(fun) do
    measure_result(:timer.tc(fun))
  end

  def measure(fun, args) do
    measure_result(:timer.tc(fun, args))
  end

  def measure(module, fun, args) do
    measure_result(:timer.tc(module, fun, args))
  end

  defp measure_result({micro, ret}) do
    { to_timestamp(micro, :usecs), ret }
  end

  defp normalize({mega, sec, micro}) do
    # TODO: check for negative values
    if micro >= @million do
      { sec, micro } = mdivmod(sec, micro)
    end

    if sec >= @million do
      { mega, sec } = mdivmod(mega, sec)
    end

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
end
