#Time:

 #* to_usec
 #* to_msec
 #* to_sec
 #* to_timestamp
 #* convert

 #* now
 #* elapsed
 #* diff

 #* add
 #* subtract
 #* cmp


defmodule Time.Helpers do
  @moduledoc false
  defmacro gen_conversions do
    lc {name, coef} inlist [{:to_usec, 1000000}, {:to_msec, 1000}, {:to_sec, 1}] do
      quote do
        def unquote(name)({mega, secs, micro}), do:
          (mega * 1000000 + secs) * unquote(coef) + micro * unquote(coef) / 1000000
        def unquote(name)(value, :usec), do: value * unquote(coef) / 1000000
        def unquote(name)(value, :msec), do: value * unquote(coef) / 1000
        def unquote(name)(value, :sec),  do: value * unquote(coef)
        def unquote(name)(value, :min),  do: value * unquote(coef) * 60
        def unquote(name)(value, :hour), do: value * unquote(coef) * 3600
        def unquote(name)({hours, minutes, seconds}, :hms), do:
          unquote(name)(hours, :hour) + unquote(name)(minutes, :min) + unquote(name)(seconds, :sec)
      end
    end
  end
end

defmodule Time do
  require Time.Helpers
  Time.Helpers.gen_conversions

  def to_timestamp(value, :usec) do
    secs = div(value, 1000000)
    microsecs = rem(value, 1000000)
    megasecs = div(secs, 1000000)
    secs = rem(secs, 1000000)
    {megasecs, secs, microsecs}
  end

  def to_timestamp(value, :msec) do
    secs = div(value, 1000)
    microsecs = rem(value, 1000)
    megasecs = div(secs, 1000000)
    secs = rem(secs, 1000000)
    {megasecs, secs, microsecs}
  end

  def to_timestamp(value, :sec) do
    secs = trunc(value)
    microsecs = trunc((value - secs) * 1000000)
    megasecs = div(secs, 1000000)
    secs = rem(secs, 1000000)
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

  def add(timestamps) when is_list(timestamps) do
    Enum.reduce timestamps, {0,0,0}, fn(a, b) ->
      add(a, b)
    end
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
  Convert the timestamp in the form { megasecs, seconds, microsecs } to the
  specified time units.
  """
  def convert(timestamp, type // nil)
  def convert(timestamp, nil),   do: timestamp
  def convert(timestamp, :usec), do: to_usec(timestamp)
  def convert(timestamp, :msec), do: to_msec(timestamp)
  def convert(timestamp, :sec),  do: to_sec(timestamp)
  def convert(timestamp, :min),  do: to_sec(timestamp) / 60
  def convert(timestamp, :hour), do: to_sec(timestamp) / 3600
  def convert(timestamp, :day),  do: to_sec(timestamp) / (3600 * 24)
  def convert(timestamp, :week), do: to_sec(timestamp) / (3600 * 24 * 7)

  @doc """
  Time interval since UNIX epoch (January 1, 1970).

  The argument is an atom indicating the type of time units to return:
  microseconds (:usec), milliseconds (:msec), seconds (:sec), minutes (:min),
  or hours (:hour).

  When the argument is omitted, the return value's format is { megasecs, seconds, microsecs }.
  """
  def now(type // nil)

  def now(nil) do
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
  def elapsed(timestamp, type // nil)

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
  def diff(t1, t2, type // nil)

  def diff({mega1,secs1,micro1}, {mega2,secs2,micro2}, nil) do
    # TODO: normalize the result
    {mega1 - mega2, secs1 - secs2, micro1 - micro2}
  end

  def diff(t1, t2, type) do
    convert(diff(t1, t2), type)
  end

  defp normalize({mega, sec, micro}) do
    # TODO: check for negative values
    if micro >= 1000000 do
      sec = sec + div(micro, 1000000)
      micro = rem(micro, 1000000)
    end

    if sec >= 1000000 do
      mega = mega + div(sec, 1000000)
      sec = rem(sec, 1000000)
    end

    { mega, sec, micro }
  end
end
