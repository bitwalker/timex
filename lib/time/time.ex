defmodule Timex.Time do

  @million 1_000_000

  @type units :: :usecs | :msecs | :secs | :mins | :hours | :days | :weeks | :hms
  @type quantity :: float


  Enum.each [usecs: @million, msecs: 1_000], fn {type, coef} ->
    @spec to_usecs(quantity, unquote(type)) :: quantity
    def to_usecs(value, unquote(type)), do: value * @million / unquote(coef)

    @spec to_msecs(quantity, unquote(type)) :: quantity
    def to_msecs(value, unquote(type)), do: value * 1000 / unquote(coef)

    @spec to_secs(quantity, unquote(type)) :: quantity
    def to_secs(value, unquote(type)),  do: value / unquote(coef)

    @spec to_mins(quantity, unquote(type)) :: quantity
    def to_mins(value, unquote(type)),  do: value / unquote(coef) / 60

    @spec to_hours(quantity, unquote(type)) :: quantity
    def to_hours(value, unquote(type)), do: value / unquote(coef) / 3600

    @spec to_days(quantity, unquote(type)) :: quantity
    def to_days(value, unquote(type)),  do: value / unquote(coef) / (3600 * 24)

    @spec to_weeks(quantity, unquote(type)) :: quantity
    def to_weeks(value, unquote(type)), do: value / unquote(coef) / (3600 * 24 * 7)
  end

  Enum.each [secs: 1, mins: 60, hours: 3600, days: 3600 * 24, weeks: 3600 * 24 * 7], fn {type, coef} ->
    @spec unquote(type)(quantity) :: quantity
    def unquote(type)(value), do: value * unquote(coef)

    @spec to_usecs(quantity, unquote(type)) :: quantity
    def to_usecs(value, unquote(type)), do: value * unquote(coef) * @million

    @spec to_msecs(quantity, unquote(type)) :: quantity
    def to_msecs(value, unquote(type)), do: value * unquote(coef) * 1000

    @spec to_secs(quantity, unquote(type)) :: quantity
    def to_secs(value, unquote(type)),  do: value * unquote(coef)

    @spec to_mins(quantity, unquote(type)) :: quantity
    def to_mins(value, unquote(type)),  do: value * unquote(coef) / 60

    @spec to_hours(quantity, unquote(type)) :: quantity
    def to_hours(value, unquote(type)), do: value * unquote(coef) / 3600

    @spec to_days(quantity, unquote(type)) :: quantity
    def to_days(value, unquote(type)),  do: value * unquote(coef) / (3600 * 24)

    @spec to_weeks(quantity, unquote(type)) :: quantity
    def to_weeks(value, unquote(type)), do: value * unquote(coef) / (3600 * 24 * 7)
  end

  Enum.each [:to_usecs, :to_msecs, :to_secs, :to_mins, :to_hours, :to_days, :to_weeks], fn name ->
    @spec unquote(name)({quantity, quantity, quantity}, :hms) :: quantity
    def unquote(name)({hours, minutes, seconds}, :hms), do: unquote(name)(hours * 3600 + minutes * 60 + seconds, :secs)
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
    { sec, micro } = mdivmod(value)
    { mega, sec }  = mdivmod(sec)
    { mega, sec, micro }
  end

  def from(value, :msecs) do
    #micro = value * 1000
    { sec, micro } = divmod(value, 1000)
    { mega, sec }  = mdivmod(sec)
    { mega, sec, micro }
  end

  def from(value, :secs) do
    # trunc ...
    { sec, micro } = mdivmod(value)
    { mega, sec }  = mdivmod(sec)
    { mega, sec, micro }
  end

  @spec to_usecs({quantity, quantity, quantity}) :: quantity
  def to_usecs({mega, sec, micro}), do: (mega * @million + sec) * @million + micro

  @spec to_msecs({quantity, quantity, quantity}) :: quantity
  def to_msecs({mega, sec, micro}), do: (mega * @million + sec) * 1000 + micro / 1000

  @spec to_secs({quantity, quantity, quantity}) :: quantity
  def to_secs({mega, sec, micro}),  do: mega * @million + sec + micro / @million

  @spec to_mins({quantity, quantity, quantity}) :: quantity
  def to_mins(timestamp),           do: to_secs(timestamp) / 60

  @spec to_hours({quantity, quantity, quantity}) :: quantity
  def to_hours(timestamp),          do: to_secs(timestamp) / 3600

  @spec to_days({quantity, quantity, quantity}) :: quantity
  def to_days(timestamp),           do: to_secs(timestamp) / (3600 * 24)

  @spec to_weeks({quantity, quantity, quantity}) :: quantity
  def to_weeks(timestamp),          do: to_secs(timestamp) / (3600 * 24 * 7)

  def to_timestamp(value, :usecs) do
    { secs, microsecs } = mdivmod(value)
    { megasecs, secs }  = mdivmod(secs)
    {megasecs, secs, microsecs}
  end
  def to_timestamp(value, :msecs) do
    { secs, microsecs } = divmod(value, 1000)
    { megasecs, secs }  = mdivmod(secs)
    {megasecs, secs, microsecs}
  end
  def to_timestamp(value, :secs) do
    secs      = trunc(value)
    microsecs = trunc((value - secs) * @million)
    { megasecs, secs } = mdivmod(secs)
    {megasecs, secs, microsecs}
  end
  def to_timestamp(value, :mins),  do: to_timestamp(value * 60, :secs)
  def to_timestamp(value, :hours), do: to_timestamp(value * 3600, :secs)
  def to_timestamp(value, :days),  do: to_timestamp(value * 3600 * 24, :secs)
  def to_timestamp(value, :weeks), do: to_timestamp(value * 3600 * 24 * 7, :secs)
  def to_timestamp(value, :hms),   do: to_timestamp(to_secs(value, :hms), :secs)

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
  def zero, do: {0, 0, 0}

  @doc """
  Convert timestamp in the form { megasecs, seconds, microsecs } to the
  specified time units.

  Supported units: microseconds (:usec), milliseconds (:msec), seconds (:sec),
  minutes (:min), hours (:hour), days (:day), or weeks (:week).
  """
  def convert(timestamp, type \\ :timestamp)
  def convert(timestamp, :timestamp), do: timestamp
  def convert(timestamp, :usecs), do: to_secs(timestamp) * 1000000
  def convert(timestamp, :msecs), do: to_secs(timestamp) * 1000
  def convert(timestamp, :secs),  do: to_secs(timestamp)
  def convert(timestamp, :mins),  do: to_secs(timestamp) / 60
  def convert(timestamp, :hours), do: to_secs(timestamp) / 3600
  def convert(timestamp, :days),  do: to_secs(timestamp) / (3600 * 24)
  def convert(timestamp, :weeks), do: to_secs(timestamp) / (3600 * 24 * 7)

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
  microseconds (:usec), milliseconds (:msec), seconds (:sec), minutes (:min),
  or hours (:hour).

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
  microseconds (:usec), milliseconds (:msec), seconds (:sec), minutes (:min),
  or hours (:hour).

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

  @doc """
  Evaluates fun() and measures the elapsed time as reported by :os.timestamp/0. Returns {time, value}, where time is { megasecs, seconds, microsecs } and value is what is returned from the function evaluation.

  ## Example

    iex> Time.measure(fn -> 2 * 2 end)
    {{0, 0, 10}, 4}

  """
  @spec measure((() -> any)) :: { Date.timestamp, any }
  def measure(fun) do
    measure_result(:timer.tc(fun))
  end

  @doc """
  Evaluates apply(fun, args). Otherwise works like measure/1
  """
  @spec measure(fun, [any]) :: { Date.timestamp, any }
  def measure(fun, args) do
    measure_result(:timer.tc(fun, args))
  end

  @doc """
  Evaluates apply(module, fun, args). Otherwise works like measure/1
  """
  @spec measure(module, atom, [any]) :: { Date.timestamp, any }
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
