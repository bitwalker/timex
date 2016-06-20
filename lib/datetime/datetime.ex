defmodule Timex.DateTime do
  @moduledoc """
  A type which represents a date and time with timezone information (optional, UTC will
  be assumed for date/times with no timezone information provided).

  Functions that produce time intervals use UNIX epoch (or simly Epoch) as the
  default reference date. Epoch is defined as UTC midnight of January 1, 1970.

  Time intervals in this module don't account for leap seconds.
  """
  require Record
  import Timex.Macros
  use Timex.Constants

  alias __MODULE__
  alias Timex.AmbiguousDateTime
  alias Timex.Date
  alias Timex.Time
  alias Timex.Timezone
  alias Timex.TimezoneInfo
  alias Timex.AmbiguousTimezoneInfo
  alias Timex.Types
  alias Timex.Helpers

  defstruct day:         1,
            month:       1,
            year:        0,
            hour:        0,
            minute:      0,
            second:      0,
            millisecond: 0,
            timezone:    nil,
            calendar:    :gregorian

  @type t :: %__MODULE__{}

  @doc """
  Creates a new DateTime struct for today's date, at the beginning of the day
  """
  @spec today() :: DateTime.t | {:error, term}
  @spec today(Timezone.t | String.t | :utc | :local) :: DateTime.t | {:error, term}
  def today,                               do: Timex.beginning_of_day(now())
  def today(%TimezoneInfo{} = tz),         do: Timex.beginning_of_day(now(tz))
  def today(tz) when is_binary(tz),        do: Timex.beginning_of_day(now(tz))
  def today(tz) when tz in [:utc, :local], do: Timex.beginning_of_day(now(tz))
  def today(_), do: {:error, :invalid_timezone}

  @doc """
  Get the current date and time.
  """
  @spec now() :: DateTime.t
  def now do
    construct(Helpers.calendar_universal_time(), %TimezoneInfo{})
  end

  @doc """
  Get the current date and time, in a specific timezone.
  """
  @spec now(TimezoneInfo.t | String.t | :utc | :local) :: DateTime.t
  def now(tz) when is_binary(tz), do: Timezone.convert(now(), tz)
  def now(%TimezoneInfo{} = tz),  do: Timezone.convert(now(), tz)
  def now(:utc),                  do: now()
  def now(:local),                do: local()

  @doc """
  Get representation of the current date and time in seconds or days since Epoch.
  """
  @spec now(:secs | :days) :: integer
  def now(:seconds), do: to_seconds(now())
  def now(:days), do: to_days(now())
  def now(:secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    now(:seconds)
  end
  def now(_), do: {:error, :invalid_unit}

  @doc """
  Get current date and time in the local timezone.

  See also `universal/0`.
  """
  @spec local() :: DateTime.t
  def local do
    date = construct(Helpers.calendar_local_time())
    tz   = Timezone.local(date)
    %{date | :timezone => tz}
  end

  @doc """
  Convert a DateTime to the local timezone.

  See also `universal/1`.
  """
  @spec local(date :: DateTime.t) :: DateTime.t
  def local(%DateTime{:timezone => tz} = date) do
    case Timezone.local(date) do
      ^tz      -> date
      new_zone -> Timezone.convert(date, new_zone)
    end
  end
  def local(_), do: {:error, :badarg}

  @doc """
  Get the current date and time in UTC.

  See also `local/0`. Delegates to `now/0`, since they are identical in behavior
  """
  @spec universal() :: DateTime.t
  defdelegate universal, to: __MODULE__, as: :now

  @doc """
  Convert a DateTime to UTC

  See also `local/1`.
  """
  @spec universal(DateTime.t) :: DateTime.t
  def universal(%DateTime{} = date), do: Timezone.convert(date, %TimezoneInfo{})
  def universal(_), do: {:error, :badarg}

  @doc """
  Get a DateTime representing the first moment of the first day of year zero (:calendar module's default reference date).

  See also `epoch/0`.

  ## Examples

      iex> use Timex
      ...> date = %DateTime{year: 0, month: 1, day: 1, timezone: %TimezoneInfo{}}
      ...> #{__MODULE__}.zero === date
      true

  """
  @spec zero() :: DateTime.t
  def zero, do: construct({0, 1, 1}, {0, 0, 0}, %TimezoneInfo{})

  @doc """
  Get a DateTime representing the first moment of the UNIX epoch (1970/1/1).

  Timex uses the UNIX epoch as it's default reference date, but this can be overridden on a per-function basis where applicable.

  See also `zero/0`.

  ## Examples

      iex> use Timex
      ...> date = %DateTime{year: 1970, month: 1, day: 1, timezone: %TimezoneInfo{}}
      ...> #{__MODULE__}.epoch === date
      true

  """
  @spec epoch() :: DateTime.t
  def epoch, do: construct({1970, 1, 1}, {0, 0, 0}, %TimezoneInfo{})

  @doc """
  Time interval since year 0 of Epoch expressed in the specified units.

  ## Examples

      iex> #{__MODULE__}.epoch(:timestamp)
      {0,0,0}
      iex> #{__MODULE__}.epoch(:seconds)
      62167219200

  """
  @spec epoch(:timestamp)   :: Types.timestamp
  @spec epoch(:seconds | :days)  :: integer

  def epoch(:timestamp), do: to_timestamp(epoch())
  def epoch(:seconds),   do: to_seconds(epoch(), :zero)
  def epoch(:secs) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    epoch(:seconds)
  end
  def epoch(_), do: {:error, :badarg}

  @doc """
  Construct a date from an Erlang date or datetime value.

  You may specify the date's time zone as the second argument. If the argument
  is omitted, UTC time zone is assumed.

  When passing {year, month, day} as the first argument, the resulting date
  will indicate midnight of that day in the specified timezone (UTC by
  default).

  NOTE: When using `from` the input value is normalized to prevent invalid
  dates from being accidentally introduced. Use `set` with `validate: false`,
  or create the %DateTime{} by hand if you do not want normalization.

  ## Examples

      > DateTime.from(:erlang.universaltime)             #=> %DateTime{...}
      > DateTime.from(:erlang.localtime)                 #=> %Datetime{...}
      > DateTime.from(:erlang.localtime, :local)         #=> %DateTime{...}
      > DateTime.from({2014,3,16}, "America/Chicago")    #=> %DateTime{...}
      > DateTime.from(phoenix_datetime_select_params)    #=> %DateTime{...}

  """
  @spec from(Types.valid_datetime | Types.phoenix_datetime_select_params) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def from(%DateTime{} = date),
    do: date
  def from(%Date{year: y, month: m, day: d}),
    do: from_erl({y, m, d}, :utc)
  def from({y,m,d} = date) when is_date(y,m,d),
    do: from_erl(date, :utc)
  def from({{y,m,d},{h,mm,s}} = datetime) when is_datetime(y,m,d,h,mm,s),
    do: from_erl(datetime, :utc)
  def from({{y,m,d},{h,mm,s,ms}} = datetime) when is_datetime(y,m,d,h,mm,s,ms),
    do: from_erl(datetime, :utc)
  def from({{y,m,d} = date, {h,mm,s} = time,{offset,tz}}) when is_gregorian(y,m,d,h,mm,s,offset,tz),
    do: from_erl({date,time}, offset)
  def from({{y,m,d} = date, {h,mm,s} = time, %TimezoneInfo{} = tz}) when is_datetime(y,m,d,h,mm,s),
    do: from_erl({date,time}, tz)
  def from({{y,m,d} = date, {h,mm,s} = time, tz}) when is_datetime(y,m,d,h,mm,s) and is_tz_value(tz),
    do: from_erl({date,time}, tz)
  def from({{y,m,d} = date, {h,mm,s,ms} = time, %TimezoneInfo{} = tz}) when is_datetime(y,m,d,h,mm,s,ms),
    do: from_erl({date,time}, tz)
  def from({{y,m,d} = date, {h,mm,s,ms} = time, tz}) when is_datetime(y,m,d,h,mm,s,ms) and is_tz_value(tz),
    do: from_erl({date,time}, tz)
  def from(map) when is_map(map),
    do: from_phoenix_datetime_select(map, :utc)
  def from(_),
    do: {:error, :invalid_datetime}

  @doc """
  Like from/1, but allows providing a timezone to assume/convert for the input date/time.
  """
  @spec from(Types.valid_datetime | Types.phoenix_datetime_select_params, Types.valid_timezone) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def from(_, nil),
    do: {:error, :invalid_timezone}
  # Timex types
  def from(%DateTime{:timezone => tz} = date, tz),
    do: date
  def from(%DateTime{} = date, %TimezoneInfo{} = tz),
    do: %{date | :timezone => tz}
  def from(%DateTime{} = date, tz) when is_tz_value(tz),
    do: %{date | :timezone => Timezone.get(tz, date)}
  def from(%Date{year: y, month: m, day: d}, %TimezoneInfo{} = tz),
    do: from_erl({y,m,d}, tz)
  def from(%Date{year: y, month: m, day: d}, tz) when is_tz_value(tz),
    do: from_erl({y,m,d}, tz)
  # Erlang date tuple
  def from({y,m,d} = date, tz) when is_date(y,m,d),
    do: from_erl(date, tz)
  # Legacy: :timestamp is deprecated
  def from({mega,sec,micro} = timestamp, :timestamp) when is_date_timestamp(mega,sec,micro) do
    IO.write :stderr, "warning: DateTime.from(_, :timestamp) is deprecated, use from_timestamp/1 or from_timestamp/2 instead\n"
    from_timestamp(timestamp, :epoch)
  end
  # Datetime tuples with timezone
  def from({{y,m,d} = date, {h,mm,s} = time, {offset,abbr}}, tz)
    when is_gregorian(y,m,d,h,mm,s,offset,abbr),
    do: from_erl({date, time}, offset) |> Timezone.convert(tz)
  def from({{y,m,d} = date, {h,mm,s} = time, %TimezoneInfo{} = tz}, %TimezoneInfo{} = tznew)
    when is_datetime(y,m,d,h,mm,s),
    do: from_erl({date, time}, tz) |> Timezone.convert(tznew)
  def from({{y,m,d} = date, {h,mm,s} = time, %TimezoneInfo{} = tz}, tznew)
    when is_datetime(y,m,d,h,mm,s) and is_tz_value(tznew),
    do: from_erl({date, time}, tz) |> Timezone.convert(tznew)
  # Erlang datetime tuples
  def from({y,m,d} = date, tz) when is_date(y,m,d),
    do: from_erl(date, tz)
  def from({{y,m,d}, {h,mm,s}} = datetime, tz) when is_datetime(y,m,d,h,mm,s),
    do: from_erl(datetime, tz)
  def from({{y,m,d}, {h,mm,s,ms}} = datetime, tz) when is_datetime(y,m,d,h,mm,s,ms),
    do: from_erl(datetime, tz)
  # Phoenix datetime select
  def from(%{"year" => _, "month" => _, "day" => _, "hour" => _, "min" => _} = dt, tz) do
    from_phoenix_datetime_select(dt, tz)
  end
  # Not a datetime, try deprecated from(value, unit, :epoch)
  def from(value, unit) when is_atom(unit), do: from(value, unit, :epoch)

  @doc """
  Converts from an Ecto DateTime tuple to a DateTime struct
  """
  @spec from_ecto(Types.date | Types.datetime) :: DateTime.t | {:error, term}
  def from_ecto(date, tz \\ %TimezoneInfo{}), do: from_erl(date, tz)

  @doc """
  Converts from an Erlang datetime tuple (including those with milliseconds) to a DateTime struct
  """
  @spec from_erl(Types.date | Types.datetime, Types.valid_timezone | nil) :: DateTime.t | {:error, term}
  def from_erl(date),
    do: from_erl(date, %TimezoneInfo{})
  def from_erl({y,m,d} = date, %TimezoneInfo{} = tz) when is_date(y,m,d),
    do: from_erl({date, {0,0,0}}, tz)
  def from_erl({y,m,d} = date, tz) when is_date(y,m,d) and is_tz_value(tz),
    do: from_erl({date, {0,0,0}}, Timezone.get(tz, {date,{0,0,0}}))
  def from_erl({_,_,_}, tz),
    do: {:error, {:invalid_timezone, tz}}
  def from_erl({{y,m,d} = date, {h,mm,s}}, %TimezoneInfo{} = tz) when is_datetime(y,m,d,h,mm,s),
    do: from_erl({date, {h,mm,s,0}}, tz)
  def from_erl({{y,m,d} = date, {h,mm,s}}, %AmbiguousTimezoneInfo{} = tz) when is_datetime(y,m,d,h,mm,s),
    do: from_erl({date, {h,mm,s,0}}, tz)
  def from_erl({{y,m,d} = date, {h,mm,s} = time}, tz) when is_datetime(y,m,d,h,mm,s) and is_tz_value(tz),
    do: from_erl({date, {h,mm,s,0}}, Timezone.get(tz, {date, time}))
  def from_erl({{_,_,_},{_,_,_}}, tz),
    do: {:error, {:invalid_timezone, tz}}
  def from_erl({{y,m,d}, {h,min,s,ms}}, %TimezoneInfo{} = tz) when is_datetime(y,m,d,h,min,s,ms) do
    case :calendar.valid_date({y,m,d}) do
      true ->
        Timezone.resolve(tz.full_name, {{y,m,d},{h,min,s,ms}})
      false ->
        {:error, :invalid_date}
    end
  end
  def from_erl({{y,m,d}, {h,min,s,ms}} = datetime, %AmbiguousTimezoneInfo{} = tz) when is_datetime(y,m,d,h,min,s,ms) do
    case :calendar.valid_date({y,m,d}) do
      true ->
        before_dt = %{construct(datetime) | :timezone => tz.before}
        after_dt  = %{construct(datetime) | :timezone => tz.after}
        %AmbiguousDateTime{:before => before_dt, :after => after_dt}
      false ->
        {:error, :invalid_date}
    end
  end
  def from_erl({{y,m,d} = date, {h,min,s,ms}}, tz) when is_datetime(y,m,d,h,min,s,ms) and is_tz_value(tz) do
    case :calendar.valid_date({y,m,d}) do
      true ->
        case Timezone.get(tz, {date, {h,min,s}}) do
          {:error, _} = err ->
            err
          %TimezoneInfo{} = timezone ->
            %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, millisecond: ms, timezone: timezone}
          %AmbiguousTimezoneInfo{:before => before_tz, :after => after_tz} ->
            before_dt = %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, millisecond: ms, timezone: before_tz}
            after_dt  = %DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, millisecond: ms, timezone: after_tz}
            %AmbiguousDateTime{:before => before_dt, :after => after_dt}
        end
      false ->
        {:error, :invalid_date}
    end
  end
  def from_erl(_, _) do
    {:error, :badarg}
  end

  @doc """
  Converts the value of a Phoenix date/time field to a DateTime struct.

  An optional timezone provided as a second parameter sets the timezone of the DateTime.
  """
  @spec from_phoenix_datetime_select(Map.t) :: DateTime.t | {:error, atom}
  @spec from_phoenix_datetime_select(Map.t, Types.valid_timezone) :: DateTime.t | {:error, atom}
  def from_phoenix_datetime_select(dt), do: from_phoenix_datetime_select(dt, :utc)
  def from_phoenix_datetime_select(%{"year" => _, "month" => _, "day" => _, "hour" => _, "min" => _} = dt, tz) do
    validated = Enum.reduce(dt, %{}, fn 
      _, :error -> :error
      {key, value}, acc ->
        case Integer.parse(value) do
          {v, _} -> Map.put(acc, key, v)
          :error -> :error
        end
    end)
    case {validated, tz} do
      {%{"year" => y, "month" => m, "day" => d, "hour" => h, "min" => mm}, tz} ->
        from_erl({{y,m,d},{h,mm,0}}, tz)
      {:error, _} ->
        {:error, :invalid}
    end
  end
  def from_phoenix_datetime_select(_, _) do
    {:error, :badarg}
  end


  @doc """
  Converts an Erlang timestamp to a DateTime struct representing that moment in time
  """
  @spec from_timestamp(Types.timestamp) :: DateTime.t
  @spec from_timestamp(Types.timestamp, :epoch | :zero) :: DateTime.t | {:error, atom}
  def from_timestamp(timestamp, ref \\ :epoch)
  def from_timestamp({mega, sec, micro}, ref)
    when is_date_timestamp(mega,sec,micro) and ref in [:epoch, :zero],
    do: from_microseconds((mega * @million + sec) * @million + micro, ref)
  def from_timestamp(_, _) do
    {:error, :badarg}
  end

  @doc """
  Converts an integer value representing days since the reference date (:epoch or :zero)
  to a DateTime struct representing that moment in time
  """
  @spec from_days(non_neg_integer) :: DateTime.t | {:error, atom}
  @spec from_days(non_neg_integer, :epoch | :zero) :: DateTime.t | {:error, atom}
  def from_days(days, ref \\ :epoch)
  def from_days(days, :epoch) when is_positive_number(days) do
    construct(:calendar.gregorian_days_to_date(trunc(days) + to_days(epoch(), :zero)), {0,0,0}, %TimezoneInfo{})
  end
  def from_days(days, :zero) when is_positive_number(days) do
    construct(:calendar.gregorian_days_to_date(trunc(days)), {0,0,0}, %TimezoneInfo{})
  end
  def from_days(_, _) do
    {:error, :badarg}
  end

  @doc """
  Converts an integer value representing seconds since the reference date (:epoch or :zero)
  to a DateTime struct representing that moment in time
  """
  @spec from_seconds(non_neg_integer) :: DateTime.t :: {:error, atom}
  @spec from_seconds(non_neg_integer, :epoch | :zero) :: DateTime.t :: {:error, atom}
  def from_seconds(s, ref \\ :epoch)
  def from_seconds(s, :epoch) when is_positive_number(s) do
    construct(:calendar.gregorian_seconds_to_datetime(trunc(s) + epoch(:seconds)), %TimezoneInfo{})
  end
  def from_seconds(s, :zero) when is_positive_number(s) do
    construct(:calendar.gregorian_seconds_to_datetime(trunc(s)), %TimezoneInfo{})
  end
  def from_seconds(_, _) do
    {:error, :badarg}
  end

  @doc """
  Converts an integer representing milliseconds since the reference date
  (:epoch or :zero) to a DateTime struct representing that moment in time
  """
  @spec from_milliseconds(non_neg_integer) :: DateTime.t :: {:error, atom}
  @spec from_milliseconds(non_neg_integer, :epoch | :zero) :: DateTime.t :: {:error, atom}
  def from_milliseconds(ms, type \\ :epoch)
  def from_milliseconds(ms, type) when is_positive_number(ms) and type in [:epoch, :zero],
    do: from_timestamp(Time.from(ms, :milliseconds), type)
  def from_milliseconds(_, _) do
    {:error, :badarg}
  end

  @doc """
  Converts an integer representing microseconds since the reference date
  (:epoch or :zero) to a DateTime struct representing that moment in time
  """
  @spec from_microseconds(non_neg_integer) :: DateTime.t :: {:error, atom}
  @spec from_microseconds(non_neg_integer, :epoch | :zero) :: DateTime.t :: {:error, atom}
  def from_microseconds(us, type \\ :epoch)
  def from_microseconds(us, :epoch) when is_positive_number(us) do
    construct(Helpers.calendar_gregorian_microseconds_to_datetime(trunc(us), epoch(:seconds)), %TimezoneInfo{})
  end
  def from_microseconds(us, :zero) when is_positive_number(us) do
    construct(Helpers.calendar_gregorian_microseconds_to_datetime(trunc(us), 0), %TimezoneInfo{})
  end
  def from_microseconds(_, _) do
    {:error, :badarg}
  end

  @doc """
  Construct a date from a time interval since Epoch or year 0.

  UTC time zone is assumed. This assumption can be modified by setting desired
  time zone using set/3 after the date is constructed.

  ## Examples

      > DateTime.from(13, :seconds)
      > DateTime.from(13, :days, :zero)
      > DateTime.from(Time.now, :timestamp)

  """
  defdeprecated from(timestamp, :timestamp, ref) when is_atom(ref), "use from_timestamp/1 or from_timestamp/2 instead",
    do: from_timestamp(timestamp, ref)
  defdeprecated from(us, :us, ref) when is_atom(ref), "use from_microseconds/1 or from_microseconds/2 instead",
    do: from_microseconds(us, ref)
  defdeprecated from(ms, :msecs, ref) when is_atom(ref), "use from_milliseconds/1 or from_milliseconds/2 instead",
    do: from_milliseconds(ms, ref)
  defdeprecated from(s, :secs, ref) when is_atom(ref), "use from_seconds/1 or from_seconds/2 instead",
    do: from_seconds(s, ref)
  defdeprecated from(days, :days, ref) when is_atom(ref), "use from_days/1 or from_days/2 instead",
    do: from_days(days, ref)

  @doc """
  Convert a date to a timestamp value consumable by the Time module.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.to_timestamp
      {0,0,0}

  """
  @spec to_timestamp(DateTime.t) :: Types.timestamp | {:error, atom}
  @spec to_timestamp(DateTime.t, :epoch | :zero) :: Types.timestamp | {:error, atom}
  def to_timestamp(date, reference \\ :epoch)

  def to_timestamp(%DateTime{:millisecond => ms} = date, :epoch) do
    case ok!(to_seconds(date)) do
      {:error, _} = err -> err
      {:ok, seconds} ->
        { div(seconds, @million), rem(seconds, @million), ms * 1_000}
    end
  end
  def to_timestamp(%DateTime{:millisecond => ms} = date, :zero) do
    case ok!(to_seconds(date, :zero)) do
      {:error, _} = err -> err
      {:ok, seconds} ->
        { div(seconds, @million), rem(seconds, @million), ms * 1_000}
    end
  end
  def to_timestamp(_, _), do: {:error, :badarg}

  defdelegate to_secs(date), to: __MODULE__,               as: :to_seconds
  defdelegate to_secs(date, ref), to: __MODULE__,          as: :to_seconds
  defdelegate to_secs(date, ref, options), to: __MODULE__, as: :to_seconds

  @doc """
  Convert a date to an integer number of seconds since Epoch or year 0.

  With `to_seconds/3`, you can also specify an option `utc: false | true`,
  which controls whether the DateTime is converted to UTC prior to calculating
  the number of seconds from the reference date. By default, UTC conversion is
  enabled.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      iex> Timex.datetime({{1999, 1, 2}, {12,13,14}}) |> #{__MODULE__}.to_seconds
      915279194

  """
  @spec to_seconds(DateTime.t) :: integer | {:error, atom}
  @spec to_seconds(DateTime.t, :epoch | :zero) :: integer | {:error, atom}
  @spec to_seconds(DateTime.t, :epoch | :zero, [utc: false | true]) :: integer | {:error, atom}
  def to_seconds(date, reference \\ :epoch, options \\ [utc: true])

  def to_seconds(%DateTime{} = date, :epoch, utc: true) do
    case to_seconds(date, :zero, utc: true) do
      {:error, _} = err -> err
      secs -> secs - epoch(:seconds)
    end
  end
  def to_seconds(%DateTime{} = date, :zero, utc: true) do
    converted = Timezone.convert(date, :utc)
    utc_to_secs(converted)
    #offset = Timex.Timezone.diff(date, %TimezoneInfo{})
    #secs = utc_to_secs(date)
    #case secs do
      #{:error, _} = err -> err
      #_ ->
        #secs + (60 * offset)
    #end
  end
  def to_seconds(%DateTime{} = date, :epoch, utc: false) do
    case to_seconds(date, :zero, utc: false) do
      {:error, _} = err -> err
      secs -> secs - epoch(:seconds)
    end
  end
  def to_seconds(%DateTime{} = date, :zero, utc: false),
    do: utc_to_secs(date)
  def to_seconds(_, _, _), do: {:error, :badarg}

  defp utc_to_secs(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => s}) do
    case :calendar.valid_date({y,m,d}) do
      false -> {:error, :invalid_date}
      true  ->
        :calendar.datetime_to_gregorian_seconds({{y, m, d}, {h, min, s}})
    end
  end


  @doc """
  Convert the date to an integer number of days since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitray reference date.

  ## Examples

      iex> Timex.datetime({1970, 1, 15}) |> #{__MODULE__}.to_days
      14

  """
  @spec to_days(DateTime.t) :: integer | {:error, atom}
  @spec to_days(DateTime.t, :epoch | :zero) :: integer | {:error, atom}
  def to_days(date, reference \\ :epoch)

  def to_days(date, :epoch) do
    case to_days(date, :zero) do
      {:error, _} = err -> err
      days -> days - to_days(epoch(), :zero)
    end
  end
  def to_days(%DateTime{:year => y, :month => m, :day => d}, :zero) do
    case :calendar.valid_date({y, m, d}) do
      false -> {:error, :invalid_date}
      true  -> :calendar.date_to_gregorian_days({y, m, d})
    end
  end
  def to_days(_, _), do: {:error, :badarg}

  @doc """
  Return a new DateTime with the specified fields replaced by new values.

  Values are automatically validated and clamped to good values by default. If
  you wish to skip validation, perhaps for performance reasons, pass `validate: false`.

  Values are applied in order, so if you pass `[datetime: dt, date: d]`, the date value
  from `date` will override `datetime`'s date value.
  """
  @spec set(DateTime.t, list({atom(), term})) :: DateTime.t | {:error, term}
  def set(%DateTime{} = date, options) do
    validate? = case options |> List.keyfind(:validate, 0, true) do
      {:validate, bool} -> bool
      _                 -> true
    end
    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err
      option, result ->
        case option do
          {:validate, _} -> result
          {:datetime, {{y, m, d}, {h, min, sec}}} ->
            if validate? do
              %{result |
                :year =>   Timex.normalize(:year,   y),
                :month =>  Timex.normalize(:month,  m),
                :day =>    Timex.normalize(:day,    {y,m,d}),
                :hour =>   Timex.normalize(:hour,   h),
                :minute => Timex.normalize(:minute, min),
                :second => Timex.normalize(:second, sec)
              }
            else
              %{result | :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}
            end
          {:date, {y, m, d}} ->
            if validate? do
              {yn,mn,dn} = Timex.normalize(:date, {y,m,d})
              %{result | :year => yn, :month => mn, :day => dn}
            else
              %{result | :year => y, :month => m, :day => d}
            end
          {:time, {h, m, s}} ->
            if validate? do
              %{result | :hour => Timex.normalize(:hour, h), :minute => Timex.normalize(:minute, m), :second => Timex.normalize(:second, s)}
            else
              %{result | :hour => h, :minute => m, :second => s}
            end
          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end
          {:timezone, tz} ->
            tz = case tz do
              %TimezoneInfo{} -> tz
              _ -> Timezone.get(tz, result)
            end
            if validate? do
              %{result | :timezone => Timex.normalize(:timezone, tz)}
            else
              %{result | :timezone => tz}
            end
          {name, val} when name in [:year, :month, :hour, :minute, :second, :millisecond] ->
            if validate? do
              Map.put(result, name, Timex.normalize(name, val))
            else
              Map.put(result, name, val)
            end
          {option_name, _} ->
            {:error, {:bad_option, option_name}}
        end
      end)
  end

  @doc """
  See docs for `Timex.Comparable.compare/2` or `Timex.Comparable.compare/3`
  """
  defdelegate compare(a, b), to: Timex.Comparable
  defdelegate compare(a, b, granularity), to: Timex.Comparable

  @doc """
  See docs for `Timex.Comparable.diff/2` or `Timex.Comparable.diff/3`
  """
  defdelegate diff(a, b), to: Timex.Comparable
  defdelegate diff(a, b, granularity), to: Timex.Comparable

  @doc """
  Shifts the given DateTime based on a series of options.

  See docs for Timex.shift/2 for details.
  """
  @spec shift(DateTime.t, list({atom(), term})) :: DateTime.t | {:error, term}
  def shift(%DateTime{} = datetime, shifts) when is_list(shifts) do
    apply_shifts(datetime, shifts)
  end
  defp apply_shifts(datetime, []),
    do: datetime
  defp apply_shifts(datetime, [{:timestamp, {0,0,0}} | rest]),
    do: apply_shifts(datetime, rest)
  defp apply_shifts(datetime, [{:timestamp, {_,_,_} = timestamp} | rest]) do
    total_milliseconds = Time.to_milliseconds(timestamp)
    seconds = div(total_milliseconds, 1_000)
    milliseconds = rem(total_milliseconds, 1_000)
    datetime
    |> shift_by(seconds, :seconds)
    |> shift_by(milliseconds, :milliseconds)
    |> apply_shifts(rest)
  end
  defp apply_shifts(datetime, [{unit, 0} | rest]) when is_atom(unit),
    do: apply_shifts(datetime, rest)
  defp apply_shifts(datetime, [{:secs, value} | rest]) do
    IO.write :stderr, "warning: :secs is a deprecated unit name, use :seconds instead\n"
    apply_shifts(datetime, [{:seconds, value} | rest])
  end
  defp apply_shifts(datetime, [{:mins, value} | rest]) do
    IO.write :stderr, "warning: :mins is a deprecated unit name, use :minutes instead\n"
    apply_shifts(datetime, [{:minutes, value} | rest])
  end
  defp apply_shifts(datetime, [{unit, value} | rest]) when is_atom(unit) and is_integer(value) do
    shifted = shift_by(datetime, value, unit)
    apply_shifts(shifted, rest)
  end
  defp apply_shifts({:error, _} = err, _),
    do: err

  # Primary constructor for DateTime objects
  defp construct({{_, _, _} = date, {_, _, _} = time}),      do: construct(date, time, %TimezoneInfo{})
  defp construct({{_, _, _} = date, {_, _, _, _} = time}),   do: construct(date, time, %TimezoneInfo{})
  defp construct({_,_,_} = date, {_,_,_} = time, nil),       do: construct(date, time, %TimezoneInfo{})
  defp construct({_,_,_} = date, {_,_,_,_} = time, nil),     do: construct(date, time, %TimezoneInfo{})
  defp construct(date, {h, min, sec}, %TimezoneInfo{} = tz), do: construct(date, {h, min, sec, 0}, tz)
  defp construct({_,_,_}=date, {_,_,_,_}=time, %TimezoneInfo{} = tz) do
    {y,m,d}        = Timex.normalize(:date, date)
    {h,min,sec,ms} = Timex.normalize(:time, time)
    %DateTime{
      year: y, month: m, day: d,
      hour: h, minute: min, second: sec,
      millisecond: ms,
      timezone: tz
    }
  end
  defp construct({_,_,_}=date, {_,_,_,_}=time, {_, name}) do
    {y,m,d}        = Timex.normalize(:date, date)
    {h,min,sec,ms} = Timex.normalize(:time, time)
    dt = %DateTime{
      year: y, month: m, day: d,
      hour: h, minute: min, second: sec,
      millisecond: ms
    }
    %{dt | :timezone => Timezone.get(name, dt)}
  end
  defp construct(date, {h, min, sec}, tz), do: construct(date, {h, min, sec, 0}, tz)
  defp construct({date, time}, tz), do: construct(date, time, tz)

  defp shift_by(%AmbiguousDateTime{:before => before_dt, :after => after_dt}, value, unit) do
    # Since we're presumably in the middle of a shifting operation, rather than failing because
    # we're crossing an ambiguous time period, process both the before and after DateTime individually,
    # and if both return AmbiguousDateTimes, choose the AmbiguousDateTime from :after to return,
    # if one returns a valid DateTime, return that instead, since the shift has resolved the ambiguity.
    # if one returns an error, but the other does not, return the non-errored one.
    case {shift_by(before_dt, value, unit), shift_by(after_dt, value, unit)} do
      # other could be an error too, but that's fine
      {{:error, _}, other} ->
        other
      {other, {:error, _}} ->
        other
      # We'll always use :after when choosing between two ambiguous datetimes
      {%AmbiguousDateTime{}, %AmbiguousDateTime{} = new_after} ->
        new_after
      # The shift resolved the ambiguity!
      {%AmbiguousDateTime{}, %DateTime{} = resolved} ->
        resolved
      {%DateTime{}, %AmbiguousDateTime{} = resolved} ->
        resolved
    end
  end
  defp shift_by(%DateTime{:year => y} = datetime, value, :years) do
    shifted = %{datetime | :year => y + value}
    # If a plain shift of the year fails, then it likely falls on a leap day,
    # so set the day to the last day of that month
    case :calendar.valid_date({shifted.year,shifted.month,shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        shifted = cond do
          shifted.day <= last_day ->
            shifted
          :else ->
            %{shifted | :day => last_day}
        end
        resolve_timezone_info(shifted)
      true ->
        resolve_timezone_info(shifted)
    end
  end
  defp shift_by(%DateTime{:year => year, :month => month} = datetime, value, :months) do
    m = month + value
    shifted = cond do
      value == 12  -> %{datetime | :year => year + 1}
      value == -12 -> %{datetime | :year => year - 1}
      m == 0 -> %{datetime | :year => year - 1, :month => 12}
      m > 12 -> %{datetime | :year => year + div(m, 12), :month => rem(m, 12)}
      m < 0  -> %{datetime | :year => year + min(div(m, 12), -1), :month => 12 + rem(m, 12)}
      :else  -> %{datetime | :month => m}
    end

    # setting months to remainders may result in invalid :month => 0
    shifted = case shifted.month do
      0 -> %{ shifted | :year => shifted.year - 1, :month => 12 }
      _ -> shifted
    end

    # If the shift fails, it's because it's a high day number, and the month
    # shifted to does not have that many days. This will be handled by always
    # shifting to the last day of the month shifted to.
    case :calendar.valid_date({shifted.year,shifted.month,shifted.day}) do
      false ->
        last_day = :calendar.last_day_of_the_month(shifted.year, shifted.month)
        shifted = cond do
          shifted.day <= last_day ->
            shifted
          :else ->
            %{shifted | :day => last_day}
        end
        resolve_timezone_info(shifted)
      true ->
        resolve_timezone_info(shifted)
    end
  end
  defp shift_by(%DateTime{millisecond: current_msecs} = datetime, value, :milliseconds) do
    millisecs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    }) * 1_000 + current_msecs + value

    secs_from_zero = div(millisecs_from_zero, 1_000)
    ms = rem(millisecs_from_zero, 1_000)

    {{_y,_m,_d}=date,{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(secs_from_zero)
    Timezone.resolve(datetime.timezone.full_name, {date, {h,mm,s,ms}})
    |> Map.merge(%{millisecond: ms})
  end
  defp shift_by(%DateTime{millisecond: ms} = datetime, value, units) do
    secs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    })
    shift_by = case units do
      :milliseconds -> div(value + ms, 1_000)
      :seconds      -> value
      :minutes      -> value * 60
      :hours        -> value * 60 * 60
      :days         -> value * 60 * 60 * 24
      :weeks        -> value * 60 * 60 * 24 * 7
      _ ->
        {:error, {:unknown_shift_unit, units}}
    end
    case shift_by do
      {:error, _} = err -> err
      0 when units in [:milliseconds] ->
        total_ms = rem(value + ms, 1_000)
        %{datetime | :millisecond => total_ms}
      0 ->
        datetime
      _ ->
        new_secs_from_zero = secs_from_zero + shift_by
        cond do
          new_secs_from_zero <= 0 ->
            {:error, :shift_to_invalid_date}
          :else ->
            {{y,m,d}=date,{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(new_secs_from_zero)
            Timezone.resolve(datetime.timezone.full_name, {date, {h,mm,s,ms}})
        end
    end
  end

  defp resolve_timezone_info(%DateTime{:timezone => %TimezoneInfo{:full_name => tzname}} = datetime) do
    Timezone.resolve(tzname, {
      {datetime.year, datetime.month, datetime.day},
      {datetime.hour, datetime.minute, datetime.second, datetime.millisecond}})
  end

end
