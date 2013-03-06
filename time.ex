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
end
