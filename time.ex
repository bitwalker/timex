defmodule Time.Helpers do
  @moduledoc false

  defmacro gen_conversions_alt do
    lc {type, coef} inlist [{:usec, 1 / 1000000}, {:msec, 1 / 1000}, {:sec, 1}, {:min, 60}, {:hour, 3600}] do
      quote do
        def to_usec(value, unquote(type)), do: value * unquote(coef) * 1000000
        def to_msec(value, unquote(type)), do: value * unquote(coef) * 1000
        def to_sec(value, unquote(type)),  do: value * unquote(coef)
        def to_min(value, unquote(type)),  do: value * unquote(coef) / 60
        def to_hour(value, unquote(type)), do: value * unquote(coef) / 3600
        def to_day(value, unquote(type)),  do: value * unquote(coef) / (3600 * 24)
        def to_week(value, unquote(type)), do: value * unquote(coef) / (3600 * 24 * 7)
      end
    end
  end

  defmacro gen_conversions_hms do
    lc name inlist [:to_usec, :to_msec, :to_sec, :to_min, :to_hour, :to_dat, :to_week] do
      quote do
        def unquote(name)({hours, minutes, seconds}, :hms), do: unquote(name)(hours * 3600 + minutes * 60 + seconds, :sec)
      end
    end
  end
end

defmodule Time do
  require Time.Helpers
  Time.Helpers.gen_conversions_alt
  Time.Helpers.gen_conversions_hms

  def to_timestamp(value, :usec) do
    { secs, microsecs } = mdivmod(value)
    { megasecs, secs } = mdivmod(secs)
    {megasecs, secs, microsecs}
  end

  def to_timestamp(value, :msec) do
    { secs, microsecs } = divmod(value, 1000)
    { megasecs, secs } = mdivmod(secs)
    {megasecs, secs, microsecs}
  end

  def to_timestamp(value, :sec) do
    secs = trunc(value)
    microsecs = trunc((value - secs) * _million)
    { megasecs, secs } = mdivmod(secs)
    {megasecs, secs, microsecs}
  end

  def to_timestamp(value, :min) do
    to_timestamp(value * 60, :sec)
  end

  def to_timestamp(value, :hour) do
    to_timestamp(value * 3600, :sec)
  end

  def to_timestamp(value, :hms) do
    to_timestamp(to_sec(value, :hms), :sec)
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

    Time.convert(Time.zero, :sec)
    #=> 0

  Can be useful for operations on collections of timestamps. For instance,

    Enum.reduce timestamps, Time.zero, Time.add(&1, &2)

  """
  def zero do
    {0, 0, 0}
  end

  @doc """
  The main conversion function for timestamps. Return number of seconds
  represented by timestamp.
  """
  def to_sec({mega, sec, micro}) do
    (mega * 1000000 + sec) + micro / 1000000
  end

  @doc """
  Convert timestamp in the form { megasecs, seconds, microsecs } to the
  specified time units.

  Supported units: microseconds (:usec), milliseconds (:msec), seconds (:sec),
  minutes (:min), hours (:hour), days (:day), or weeks (:week).
  """
  def convert(timestamp, type // :timestamp)
  def convert(timestamp, :timestamp), do: timestamp
  def convert(timestamp, :usec), do: to_sec(timestamp) * 1000000
  def convert(timestamp, :msec), do: to_sec(timestamp) * 1000
  def convert(timestamp, :sec),  do: to_sec(timestamp)
  def convert(timestamp, :min),  do: to_sec(timestamp) / 60
  def convert(timestamp, :hour), do: to_sec(timestamp) / 3600
  def convert(timestamp, :day),  do: to_sec(timestamp) / (3600 * 24)
  def convert(timestamp, :week), do: to_sec(timestamp) / (3600 * 24 * 7)

  @doc """
  Return time interval since the first day of year 0 to Epoch.
  """
  def epoch(type // :timestamp)

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
  def now(type // :timestamp)

  def now(:timestamp) do
    :os.timestamp
  end

  def now(type) do
    convert(now, type)
  end

  @doc """
  Time interval between timestamp and now. If timestamp is after now in time, the
  return value will be negative.

  The second argument is an atom indicating the type of time units to return:
  microseconds (:usec), milliseconds (:msec), seconds (:sec), minutes (:min),
  or hours (:hour).

  When the second argument is omitted, the return value's format is { megasecs,
  seconds, microsecs }.
  """
  def elapsed(timestamp, type // :timestamp)

  def elapsed(timestamp, type) do
    diff(now, timestamp, type)
  end

  @doc """
  Time interval between two timestamps. If the first timestamp comes before the
  second one in time, the return value will be negative.

  The third argument is an atom indicating the type of time units to return:
  microseconds (:usec), milliseconds (:msec), seconds (:sec), minutes (:min),
  or hours (:hour).

  When the third argument is omitted, the return value's format is { megasecs,
  seconds, microsecs }.
  """
  def diff(t1, t2, type // :timestamp)

  def diff({mega1,secs1,micro1}, {mega2,secs2,micro2}, :timestamp) do
    # TODO: normalize the result
    {mega1 - mega2, secs1 - secs2, micro1 - micro2}
  end

  def diff(t1, t2, type) do
    convert(diff(t1, t2), type)
  end

  defp normalize({mega, sec, micro}) do
    # TODO: check for negative values
    if micro >= _million do
      { sec, micro } = mdivmod(sec, micro)
    end

    if sec >= _million do
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
    divmod(a, _million)
  end

  defp mdivmod(initial, a) do
    divmod(initial, a, _million)
  end

  defp _million, do: 1000000
end
