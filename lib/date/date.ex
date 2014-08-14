defmodule Timex.Date do
  @moduledoc """
  Module for working with dates.

  Functions that produce time intervals use UNIX epoch (or simly Epoch) as the
  default reference date. Epoch is defined as UTC midnight of January 1, 1970.

  Time intervals in this module don't account for leap seconds.

  Supported tasks:

    * get current date in the desired time zone
    * convert dates between time zones and time units
    * introspect dates to find out weekday, week number, number of days in a given month, etc.
    * parse dates from string
    * compare dates
    * date arithmetic
  """
  require Record
  alias Timex.DateTime,     as: DateTime
  alias Timex.Timezone,     as: Timezone
  alias Timex.TimezoneInfo, as: TimezoneInfo

  # Date types
  @type dtz :: { datetime, TimezoneInfo.t }
  @type datetime :: { date, time }
  @type date :: { year, month, day }
  @type iso_triplet :: { year, weeknum, weekday }
  @type year :: non_neg_integer
  @type month :: 1..12
  @type day :: 1..31
  @type daynum :: 1..366
  @type weekday :: 1..7
  @type weeknum :: 1..53
  @type num_of_days :: 28..31
  # Time types
  @type time :: { hour, minute, second }
  @type hour :: 0..23
  @type minute :: 0..59
  @type second :: 0..59
  @type timestamp :: {megaseconds, seconds, microseconds }
  @type megaseconds :: non_neg_integer
  @type seconds :: non_neg_integer
  @type microseconds :: non_neg_integer

  # Constants
  @million 1_000_000
  @weekdays [ 
    {"Monday", 1}, {"Tuesday", 2}, {"Wednesday", 3}, {"Thursday", 4},
    {"Friday", 5}, {"Saturday", 6}, {"Sunday", 7}
  ]
  @months [ 
    {"January", 1},  {"February", 2},  {"March", 3},
    {"April", 4},    {"May", 5},       {"June", 6},
    {"July", 7},     {"August", 8},    {"September", 9},
    {"October", 10}, {"November", 11}, {"December", 12}
  ]

  @doc """
  Get a TimezoneInfo object for the specified offset or name.

  When offset or name is invalid, exception is raised.

  ## Examples

      timezone()       #=> <local time zone>
      timezone(:utc)   #=> { 0.0, "UTC" }
      timezone(2)      #=> { 2.0, "EET" }
      timezone("+2")   #=> { 2.0, "EET" }
      timezone("EET")  #=> { 2.0, "EET" }

  """
  @spec timezone() :: TimezoneInfo.t
  @spec timezone(:local, DateTime.t | nil) :: TimezoneInfo.t
  @spec timezone(:utc | number | binary) :: TimezoneInfo.t

  def timezone(),             do: Timezone.local()
  def timezone(:local),       do: Timezone.local()
  def timezone(name),         do: Timezone.get(name)
  def timezone(:local, date), do: Timezone.local(date)

  @doc """
  Get current date.

  ## Examples

      Date.now #=> %DateTime{year: 2013, month: 3, day: 16, hour: 11, minute: 1, second: 12, timezone: %TimezoneInfo{...}}

  """
  @spec now() :: DateTime.t
  def now do
    construct(:calendar.universal_time(), timezone(:utc))
  end

  @doc """
  Get the current date, in a specific timezone.

  ## Examples

    > Date.now("America/Chicago")
    %DateTime{
      year: 2013, month: 3, day: 16, ..,
      timezone: %TimezoneInfo{standard_abbreviation: "CST", ...}
    }
  """
  @spec now(binary) :: DateTime.t
  def now(tz) when is_binary(tz) do
    case timezone(tz) do
      %TimezoneInfo{} = tzinfo ->
        construct(:calendar.universal_time(), timezone(:utc))
        |> set(timezone: tzinfo)
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Get representation of the current date in seconds or days since Epoch.

  See convert/2 for converting arbitrary dates to various time units.

  ## Examples

      now(:secs)   #=> 1363439013
      now(:days)   #=> 15780

  """
  @spec now(:secs | :days) :: integer

  def now(:secs), do: to_secs(now())
  def now(:days), do: to_days(now())

  @doc """
  Get current local date.

  See also `universal/0`.

  ## Examples

      Date.local #=> %DateTime{year: 2013, month: 3, day: 16, hour: 11, minute: 1, second: 12, timezone: %TimezoneInfo{...}}

  """
  @spec local() :: DateTime.t
  def local, do: construct(:calendar.local_time(), timezone(:local))

  @doc """
  Convert a date to your local timezone.

  See also `universal/1`.

  ## Examples

      Date.now |> Date.local

  """
  @spec local(date :: DateTime.t) :: DateTime.t
  def local(%DateTime{} = date), do: local(date, timezone(:local))

  @doc """
  Convert a date to a local date, using the provided timezone

  ## Examples

      Date.now |> Date.local(timezone(:utc))

  """
  @spec local(date :: DateTime.t, tz :: TimezoneInfo.t) :: DateTime.t
  def local(%DateTime{:timezone => tz} = date, localtz) do
    if tz !== localtz do
      Timezone.convert(date, localtz)
      %{date | :timezone => localtz}
    else
      date
    end
  end

  @doc """
  Get current the current datetime in UTC.

  See also `local/0`.
  """
  @spec universal() :: DateTime.t
  def universal, do: construct(:calendar.universal_time(), timezone(:utc))

  @doc """
  Convert a date to UTC

  See also `local/1`.

  ## Examples

      Date.now |> Date.universal

  """
  @spec universal(DateTime.t) :: DateTime.t
  def universal(date), do: Timezone.convert(date, timezone(:utc))

  @doc """
  The first day of year zero (calendar module's default reference date).

  See also `epoch/0`.

  ## Examples

      Date.zero |> Date.to_secs #=> 0

  """
  @spec zero() :: DateTime.t
  def zero, do: construct({0, 1, 1}, {0, 0, 0}, timezone(:utc))

  @doc """
  The date of Epoch, used as default reference date by this module
  and also by the Time module.

  See also `zero/0`.

  ## Examples

      Date.epoch |> Date.to_secs #=> 0

  """
  @spec epoch() :: DateTime.t
  def epoch, do: construct({1970, 1, 1}, {0, 0, 0}, timezone(:utc))

  @doc """
  Time interval since year 0 of Epoch expressed in the specified units.

  ## Examples

      epoch()        #=> %DateTime{year: 1970, month: 1 ...}
      epoch(:secs)   #=> 62167219200
      epoch(:days)   #=> 719528

  """
  @spec epoch(:timestamp)   :: timestamp
  @spec epoch(:secs | :days)  :: integer

  def epoch(:timestamp), do: to_timestamp(epoch())
  def epoch(:secs),      do: to_secs(epoch(), :zero)
  def epoch(:days),      do: to_days(epoch(), :zero)

  @doc """
  Construct a date from Erlang's date or datetime value.

  You may specify the date's time zone as the second argument. If the argument
  is omitted, UTC time zone is assumed.

  When passing {year, month, day} as the first argument, the resulting date
  will indicate midnight of that day in the specified timezone (UTC by
  default).

  ## Examples

      Date.from(:erlang.universaltime)             #=> %DateTime{...}
      Date.from(:erlang.localtime)                 #=> %Datetime{...}
      Date.from(:erlang.localtime, :local)         #=> %DateTime{...}
      Date.from({2014,3,16}, Date.timezone("PST")) #=> %DateTime{...}
      Date.from({2014,3,16}, "PST")                #=> %DateTime{...}

  """
  @spec from(date | datetime) :: dtz
  @spec from(date | datetime, :utc | :local | TimezoneInfo.t | binary) :: dtz

  def from({_,_,_} = date),                        do: from(date, :utc)
  def from({{_,_,_},{_,_,_}} = datetime),          do: from(datetime, :utc)
  def from({_,_,_} = date, :utc),                  do: construct({date, {0,0,0}}, timezone(:utc))
  def from({{_,_,_},{_,_,_}} = datetime, :utc),    do: construct(datetime, timezone(:utc))
  def from({_,_,_} = date, :local),                do: from({date, {0,0,0}}, timezone(:local))
  def from({{_,_,_},{_,_,_}} = datetime, :local),  do: from(datetime, timezone(:local))
  def from({_,_,_} = date, %TimezoneInfo{} = tz),  do: from({date, {0,0,0}}, tz)
  def from({{_,_,_},{_,_,_}} = datetime, %TimezoneInfo{} = tz), do: construct(datetime, tz)
  def from({_,_,_} = date, tz) when is_binary(tz), do: from({date, {0, 0, 0}}, tz)
  def from({{_,_,_},{_,_,_}} = datetime, tz) when is_binary(tz) do
    case timezone(tz) do
      %TimezoneInfo{} = tzinfo ->
        construct(datetime, tzinfo)
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Construct a date from a time interval since Epoch or year 0.

  UTC time zone is assumed. This assumption can be modified by setting desired
  time zone using set/3 after the date is constructed.

  ## Examples

      Date.from(13, :secs)          #=> %DateTime{...}
      Date.from(13, :days, :zero)   #=> %DateTime{...}

      date = Date.from(Time.now, :timestamp) 
      |> Date.set(:timezone, timezone(:local))      #=> yields the same value as Date.now would

  """
  @spec from(timestamp, :timestamp) :: DateTime.t
  @spec from(number, :secs | :days)  :: DateTime.t
  @spec from(timestamp, :timestamp, :epoch | :zero) :: DateTime.t
  @spec from(number, :secs | :days, :epoch | :zero)  :: DateTime.t
  def from(value, type, reference \\ :epoch)

  def from({mega, sec, _}, :timestamp, :epoch), do: from(mega * @million + sec, :secs)
  def from({mega, sec, _}, :timestamp, :zero),  do: from(mega * @million + sec, :secs, :zero)
  def from(sec, :secs, :epoch) do
    construct(:calendar.gregorian_seconds_to_datetime(trunc(sec) + epoch(:secs)), timezone(:utc))
  end
  def from(sec, :secs, :zero) do
    construct(:calendar.gregorian_seconds_to_datetime(trunc(sec)), timezone(:utc))
  end
  def from(days, :days, :epoch) do
    construct(:calendar.gregorian_days_to_date(trunc(days) + epoch(:days)), {0,0,0}, timezone(:utc))
  end
  def from(days, :days, :zero) do
    construct(:calendar.gregorian_days_to_date(trunc(days)), {0,0,0}, timezone(:utc))
  end

  @doc """
  Multi-purpose conversion function. Converts a date to the specified time
  interval since Epoch. If you'd like to specify year 0 as a reference date,
  use one of the to_* functions.

  ## Examples

      date = Date.now
      Date.convert(date, :secs) + Date.epoch(:secs) == Date.to_secs(date, :zero)  #=> true

  """
  @spec convert(DateTime.t) :: timestamp
  @spec convert(DateTime.t, :timestamp)   :: timestamp
  @spec convert(DateTime.t, :secs | :days) :: integer
  def convert(date, type \\ :timestamp)

  def convert(date, :timestamp),  do: to_timestamp(date)
  def convert(date, :secs),       do: to_secs(date)
  def convert(date, :days),       do: to_days(date)

  @doc """
  Convert a date to a timestamp value consumable by the Time module.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      Date.epoch |> Date.to_timestamp #=> {0,0,0}

  """
  @spec to_timestamp(DateTime.t) :: timestamp
  @spec to_timestamp(DateTime.t, :epoch | :zero) :: timestamp
  def to_timestamp(date, reference \\ :epoch)

  def to_timestamp(date, :epoch) do
    sec = to_secs(date)
    { div(sec, @million), rem(sec, @million), 0 }
  end

  def to_timestamp(date, :zero) do
    sec = to_secs(date, :zero)
    { div(sec, @million), rem(sec, @million), 0 }
  end

  @doc """
  Convert a date to an integer number of seconds since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      Date.from({{1999, 1, 2}, {12,13,14}}) |> Date.to_secs  #=> 915279194

  """
  @spec to_secs(DateTime.t) :: integer
  @spec to_secs(DateTime.t, :epoch | :zero) :: integer
  def to_secs(date, reference \\ :epoch)

  def to_secs(date, :epoch), do: to_secs(date, :zero) - epoch(:secs)
  def to_secs(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => s}, :zero) do
    :calendar.datetime_to_gregorian_seconds({{y, m, d}, {h, min, s}})
  end

  @doc """
  Convert the date to an integer number of days since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitray reference date.

  ## Examples

      to_days(now())  #=> 15780

  """
  @spec to_days(DateTime.t) :: integer
  @spec to_days(DateTime.t, :epoch | :zero) :: integer
  def to_days(date, reference \\ :epoch)

  def to_days(date, :epoch), do: to_days(date, :zero) - epoch(:days)
  def to_days(%DateTime{:year => y, :month => m, :day => d}, :zero) do
    :calendar.date_to_gregorian_days({y, m, d})
  end

  @doc """
  Return weekday number (as defined by ISO 8601) of the specified date.

  ## Examples

      Date.epoch |> Date.weekday  #=> 4 (i.e. Thursday)

  """
  @spec weekday(DateTime.t) :: weekday

  def weekday(%DateTime{:year => y, :month => m, :day => d}), do: :calendar.day_of_the_week({y, m, d})

  @doc """
  Returns the ordinal day number of the date.
  """
  @spec day(DateTime.t) :: daynum

  def day(date) do
    start_of_year = date |> set([month: 1, day: 1])
    1 + diff(start_of_year, date, :days)
  end

  @doc """
  Convert an iso ordinal day number to the day it represents in the
  current year. If no date is provided, a new one will be created, with
  the time will be set to 0:00:00, in UTC. Otherwise, the date provided will
  have it's month and day reset to the date represented by the ordinal day.

  ## Examples

      180 |> Date.from_iso_day       #=> %DateTime{year: 2014, month: 6, day: 7}
      180 |> Date.from_iso_day(date) #=> <modified date struct where the month and day has been set appropriately>
  """
  @spec from_iso_day(non_neg_integer, date | nil) :: DateTime.t
  def from_iso_day(day, date \\ nil)

  def from_iso_day(day, nil) do
    today = now |> set([month: 1, day: 1, hour: 0, minute: 0, second: 0, ms: 0])
    shift(today, days: day)
  end
  def from_iso_day(day, date) do
    reset = date |> set([month: 1, day: 1])
    shift(reset, days: day)
  end

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that date falls
  on.

  ## Examples

      Date.epoch |> Date.iso_week  #=> {1970,1}

  """
  @spec iso_week(DateTime.t) :: {year, weeknum}

  def iso_week(%DateTime{:year => y, :month => m, :day => d}) do
    :calendar.iso_week_number({y, m, d})
  end
  def iso_week(date), do: iso_week(from(date, :utc))

  @doc """
  Get the day of the week corresponding to the given name.

  ## Examples

    day_to_num("Monday")  => 1
    day_to_num("Mon")     => 1
    day_to_num("monday")  => 1
    day_to_num("mon")     => 1
    day_to_num(:mon)   => 1

  """
  @spec day_to_num(binary | atom()) :: integer
  @weekdays |> Enum.each fn {day_name, day_num} ->
    lower      = day_name |> String.downcase
    abbr_cased = day_name |> String.slice(0..2)
    abbr_lower = lower |> String.slice(0..2)
    symbol     = abbr_lower |> String.to_atom

    day_quoted = quote do
      def day_to_num(unquote(day_name)),   do: unquote(day_num)
      def day_to_num(unquote(lower)),      do: unquote(day_num)
      def day_to_num(unquote(abbr_cased)), do: unquote(day_num)
      def day_to_num(unquote(abbr_lower)), do: unquote(day_num)
      def day_to_num(unquote(symbol)),     do: unquote(day_num)
    end
    Module.eval_quoted __MODULE__, day_quoted, [], __ENV__
  end
  # Make an attempt at cleaning up the provided string
  def day_to_num(x), do: {:error, "Invalid day name: #{x}"}

  @doc """
  Get the name of the day corresponding to the provided number
  """
  @spec day_name(weekday) :: binary
  @weekdays |> Enum.each fn {name, day_num} ->
    def day_name(unquote(day_num)), do: unquote(name)
  end
  def day_name(x), do: {:error, "Invalid day num: #{x}"}

  @doc """
  Get the short name of the day corresponding to the provided number
  """
  @spec day_shortname(weekday) :: binary
  @weekdays |> Enum.each fn {name, day_num} ->
    def day_shortname(unquote(day_num)), do: String.slice(unquote(name), 0..2)
  end
  def day_shortname(x), do: {:error, "Invalid day num: #{x}"}

  @doc """
  Get the number of the month corresponding to the given name.

  ## Examples

    month_to_num("January") => 1
    month_to_num("Jan")     => 1
    month_to_num("january") => 1
    month_to_num("jan")     => 1
    month_to_num(:january)  => 1

  """
  @spec month_to_num(binary) :: integer
  @months |> Enum.each fn {month_name, month_num} ->
    lower      = month_name |> String.downcase
    abbr_cased = month_name |> String.slice(0..2)
    abbr_lower = lower |> String.slice(0..2)
    symbol     = abbr_lower |> String.to_atom
    full_chars = month_name |> String.to_char_list
    abbr_chars = abbr_cased |> String.to_char_list

    month_quoted = quote do
      def month_to_num(unquote(month_name)), do: unquote(month_num)
      def month_to_num(unquote(lower)),      do: unquote(month_num)
      def month_to_num(unquote(abbr_cased)), do: unquote(month_num)
      def month_to_num(unquote(abbr_lower)), do: unquote(month_num)
      def month_to_num(unquote(symbol)),     do: unquote(month_num)
      def month_to_num(unquote(full_chars)), do: unquote(month_num)
      def month_to_num(unquote(abbr_chars)), do: unquote(month_num)
    end
    Module.eval_quoted __MODULE__, month_quoted, [], __ENV__
  end
  # Make an attempt at cleaning up the provided string
  def month_to_num(x), do: {:error, "Invalid month name: #{x}"}

  @doc """
  Get the name of the month corresponding to the provided number
  """
  @spec month_name(month) :: binary
  @months |> Enum.each fn {name, month_num} ->
    def month_name(unquote(month_num)), do: unquote(name)
  end
  def month_name(x), do: {:error, "Invalid month num: #{x}"}

  @doc """
  Get the short name of the month corresponding to the provided number
  """
  @spec month_shortname(month) :: binary
  @months |> Enum.each fn {name, month_num} ->
    def month_shortname(unquote(month_num)), do: String.slice(unquote(name), 0..2)
  end
  def month_shortname(x), do: {:error, "Invalid month num: #{x}"}

  @doc """
  Return a 3-tuple {year, week number, weekday} for the given date.

  ## Examples

      Date.epoch |> Date.iso_triplet  #=> {1970, 1, 4}

  """
  @spec iso_triplet(DateTime.t) :: {year, weeknum, weekday}

  def iso_triplet(%DateTime{} = datetime) do
    { iso_year, iso_week } = iso_week(datetime)
    { iso_year, iso_week, weekday(datetime) }
  end

  @doc """
  Given an ISO triplet `{year, week number, weekday}`, convert it to a
  DateTime struct.

  ## Examples

      {2014, 5, 2} |> Date.from_iso_triplet #=> %DateTime{year: 2014, month: 2, day: 2}

  """
  @spec from_iso_triplet(iso_triplet) :: DateTime.t
  def from_iso_triplet({year, _, _} = triplet) do
    DateTime.new
    |> set([year: year, month: 1, day: 1])
    |> do_from_iso_triplet(triplet)
  end
  defp do_from_iso_triplet(date, {_, week, weekday}) do
    {year, _, first_weekday}  = date |> set([month: 1, day: 4]) |> iso_triplet
    weekday_offset            = first_weekday + 3
    ordinal                   = ((week * 7) + weekday) - weekday_offset
    cond do
      ordinal <= 0 -> do_from_iso_triplet(%{date | :year => year - 1}, {year, 53, weekday})
      true -> date |> shift(days: ordinal)
    end
  end

  @doc """
  Return the number of days in the month which the date falls on.

  ## Examples

      Date.epoch |> Date.days_in_month  #=> 31

  """
  @spec days_in_month(DateTime.t | {year, month}) :: num_of_days
  def days_in_month(%DateTime{:year => year, :month => month}) do
    :calendar.last_day_of_the_month(year, month)
  end
  def days_in_month(year, month) do
    :calendar.last_day_of_the_month(year, month)
  end

  @doc """
  Return a boolean indicating whether the given year is a leap year. You may
  pase a date or a year number.

  ## Examples

      Date.epoch |> Date.is_leap?  #=> false
      Date.is_leap?(2012)          #=> true

  """
  @spec is_leap?(DateTime.t | year) :: boolean

  def is_leap?(year) when is_integer(year), do: :calendar.is_leap_year(year)
  def is_leap?(%DateTime{:year => year}),   do: is_leap?(year)

  @doc """
  Return a boolean indicating whether the given date is valid.

  ## Examples

      Date.from({1,1,1}, {1,1,1}) |> Date.is_valid?           #=> true
      Date.from({12,13,14}) |> Date.is_valid?                 #=> false
      Date.from({12,12,12, {-1,59,59}}) |> Date.is_valid?     #=> false
      {{12,12,12},{1,1,1}, Date.timezone()} |> Date.is_valid? #=> true

  """
  @spec is_valid?(dtz | DateTime.t) :: boolean

  def is_valid?({date, time, tz}) do
    :calendar.valid_date(date) and is_valid_time?(time) and is_valid_tz?(tz)
  end
  def is_valid?(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec, :timezone => tz}) do
    :calendar.valid_date({y,m,d}) and is_valid_time?({h,min,sec}) and is_valid_tz?(tz)
  end

  defp is_valid_time?({hour,min,sec}) do
    hour >= 0 and hour < 24 and min >= 0 and min < 60 and sec >= 0 and sec < 60
  end

  defp is_valid_tz?(%TimezoneInfo{} = tz) when tz == %TimezoneInfo{}, do: false
  defp is_valid_tz?(%TimezoneInfo{}), do: true
  defp is_valid_tz?(_), do: false

  @doc """
  Produce a valid date from a possibly invalid one.

  All date's components will be clamped to the minimum or maximum valid value.

  ## Examples

      {{1,13,44}, {-8,60,61}}
      |> Date.normalize
      |> Date.local #=> DateTime[month: 12, day: 31, hour: 0, minute: 59, second: 59, ...]

  """
  @spec normalize(dtz) :: DateTime.t
  @spec normalize(atom(), term) :: DateTime.t

  def normalize({date, time}), do: normalize({date, time, timezone(:utc)})
  def normalize({date, time, tz}) do
    construct(normalize(:date, date), normalize(:time, time), tz)
  end

  defp normalize(:date, {year, month, day}) do
    year  = normalize(:year, year)
    month = normalize(:month, month)
    day   = normalize(:day, {year, month, day})
    {year, month, day}
  end
  defp normalize(:year, year) when year < 0, do: 0
  defp normalize(:year, year), do: year
  defp normalize(:month, month) do
    cond do
      month < 1   -> 1
      month > 12  -> 12
      true        -> month
    end
  end
  defp normalize(:time, {hour,min,sec}) do
    hour  = normalize(:hour, hour)
    min   = normalize(:minute, min)
    sec   = normalize(:second, sec)
    {hour, min, sec}
  end
  defp normalize(:hour, hour) do
    cond do
      hour < 0    -> 0
      hour > 23   -> 23
      true        -> hour
    end
  end
  defp normalize(:minute, min) do
    cond do
      min < 0    -> 0
      min > 59   -> 59
      true       -> min
    end
  end
  defp normalize(:second, sec) do
    cond do
      sec < 0    -> 0
      sec > 59   -> 59
      true       -> sec
    end
  end
  defp normalize(:ms, ms) do
    cond do
      ms < 0   -> 0
      ms > 999 -> 999
      true     -> ms
    end
  end
  defp normalize(:timezone, tz), do: tz
  defp normalize(:day, {year, month, day}) do
    year  = normalize(:year, year)
    month = normalize(:month, month)
    ndays = days_in_month(year, month)
    cond do
      day < 1     -> 1
      day > ndays -> ndays
      true        -> day
    end
  end

  @doc """
  Return a new date with the specified fields replaced by new values.

  Values are automatically validated and clamped to good values by default. If
  you wish to skip validation, perhaps for performance reasons, pass `validate: false`.

  Values are applied in order, so if you pass `[datetime: dt, date: d]`, the date value
  from `date` will override `datetime`'s date value.

  ## Examples

      Date.now |> Date.set(date: {1,1,1})                   #=> DateTime[year: 1, month: 1, day: 1, ...]
      Date.now |> Date.set(hour: 0)                         #=> DateTime[hour: 0, ...]
      Date.now |> Date.set([date: {1,1,1}, hour: 30])       #=> DateTime[year: 1, month: 1, day: 1, hour: 23, ...]
      Date.now |> Date.set([
        datetime: {{1,1,1}, {0,0,0}}, date: {2,2,2}
      ])                                                    #=> DateTime[year: 2, month: 2, day: 2, ...]
      Date.now |> Date.set([minute: 74, validate: false])   #=> DateTime[minute: 74, ...]

  """
  @spec set(DateTime.t, list({atom(), term})) :: DateTime.t

  def set(date, options) do
    validate? = options |> List.keyfind(:validate, 0, true)
    Enum.reduce options, date, fn option, result ->
      case option do
        {:validate, _} -> result
        {:datetime, {{y, m, d}, {h, min, sec}}} ->
          if validate? do
            %{result |
              :year =>   normalize(y,   :year),
              :month =>  normalize(m,   :month),
              :day =>    normalize(d,   :day),
              :hour =>   normalize(h,   :hour),
              :minute => normalize(min, :minute),
              :second => normalize(sec, :second)
            }
          else
            %{result | :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}
          end
        {:date, {y, m, d}} ->
          if validate? do
            %{result | :year => normalize(:year, y), :month => normalize(:month, m), :day => normalize(:day, {y, m, d})}
          else
            %{result | :year => y, :month => m, :day => d}
          end
        {:time, {h, m, s}} ->
          if validate? do
            %{result | :hour => normalize(:hour, h), :minute => normalize(:minute, m), :second => normalize(:second, s)}
          else
            %{result | :hour => h, :minute => m, :second => s}
          end
        {:day, d} ->
          if validate? do
            %{result | :day => normalize(:day, {result.year, result.month, d})}
          else
            %{result | :day => d}
          end
        {:timezone, tz} ->
          # Only convert timezones if they differ
          case result.timezone do
            # Date didn't have a timezone, so use UTC
            nil       -> %{result | :timezone => timezone(:utc)}
            origin_tz ->
              if origin_tz !== tz do
                converted = Timezone.convert(result, tz)
                %{converted | :timezone => tz}
              else
                result
              end
          end
        {name, val} when name in [:year, :month, :hour, :minute, :second, :ms] ->
          if validate? do
            Map.put(result, name, normalize(name, val))
          else
            Map.put(result, name, val)
          end
        {option_name, _}   -> raise "Invalid option passed to Date.set: #{option_name}"
      end
    end
  end

  @doc """
  Compare two dates returning one of the following values:

   * `-1` -- `this` comes after `other`
   * `0`  -- Both arguments represent the same date when coalesced to the same timezone.
   * `1`  -- `this` comes before `other`

  """
  @spec compare(DateTime.t, DateTime.t | :epoch | :zero | :distant_past | :distant_future) :: -1 | 0 | 1

  def compare(date, :epoch),       do: compare(date, epoch())
  def compare(date, :zero),        do: compare(date, zero())
  def compare(_, :distant_past),   do: -1
  def compare(_, :distant_future), do: 1
  def compare(date, date),         do: 0
  def compare(%DateTime{:timezone => thistz} = this, %DateTime{:timezone => othertz} = other) do
    localized = if thistz !== othertz do
      # Convert `other` to `this`'s timezone
      Timezone.convert(other, thistz)
    else
      other
    end
    difference = diff(this, localized, :secs)
    cond do
      difference < 0  -> -1
      difference == 0 -> 0
      difference > 0  -> 1
    end
  end

  @doc """
  Determine if two dates represent the same point in time
  """
  @spec equal?(DateTime.t, DateTime.t) :: boolean
  def equal?(this, other), do: compare(this, other) == 0

  @doc """
  Calculate time interval between two dates. If the second date comes after the
  first one in time, return value will be positive; and negative otherwise.
  """
  @spec diff(DateTime.t, DateTime.t, :timestamp) :: timestamp
  @spec diff(DateTime.t, DateTime.t, :secs | :days | :weeks | :months | :years) :: integer

  def diff(this, other, :timestamp) do
    diff(this, other, :secs) |> Time.from_sec
  end
  def diff(this, other, :secs) do
    to_secs(other, :zero) - to_secs(this, :zero)
  end
  def diff(this, other, :mins) do
    (to_secs(other, :zero) - to_secs(this, :zero)) |> div(60)
  end
  def diff(this, other, :hours) do
    (to_secs(other, :zero) - to_secs(this, :zero)) |> div(60) |> div(60)
  end
  def diff(this, other, :days) do
    to_days(other, :zero) - to_days(this, :zero)
  end
  def diff(this, other, :weeks) do
    # TODO: think of a more accurate method
    diff(this, other, :days) |> div(7)
  end
  def diff(this, other, :months) do
    %DateTime{:year => y1, :month => m1} = universal(this)
    %DateTime{:year => y2, :month => m2} = universal(other)
    ((y2 - y1) * 12) + (m2 - m1)
  end
  def diff(this, other, :years) do
    %DateTime{:year => y1} = universal(this)
    %DateTime{:year => y2} = universal(other)
    y2 - y1
  end

  @doc """
  Add time to a date using a timestamp, i.e. {megasecs, secs, microsecs}
  Same as shift(date, Time.to_timestamp(5, :mins), :timestamp).
  """
  @spec add(DateTime.t, timestamp) :: DateTime.t

  def add(date, {mega, sec, _}) do
    shift(date, [secs: (mega * @million) + sec])
  end

  @doc """
  Subtract time from a date using a timestamp, i.e. {megasecs, secs, microsecs}
  Same as shift(date, Time.to_timestamp(5, :mins) |> Time.invert, :timestamp).
  """
  @spec subtract(DateTime.t, timestamp) :: DateTime.t

  def subtract(date, {mega, sec, _}) do
    shift(date, [secs: (-mega * @million) - sec])
  end

  @doc """
  A single function for adjusting the date using various units: timestamp,
  seconds, minutes, hours, days, weeks, months, years.

  When shifting by timestamps, microseconds are ignored.

  If the list contains `:month` and at least one other unit, an ArgumentError
  is raised (due to ambiguity of such shifts). You can still shift by months
  separately.

  If `:year` is present, it is applied in the last turn.

  The returned date is always valid. If after adding months or years the day
  exceeds maximum number of days in the resulting month, that month's last day
  is used.

  To prevent day skew, fix up the date after shifting. For example, if you want
  to land on the last day of the next month, do the following:

      shift(date, 1, :month) |> set(:month, 31)

  Since `set/3` is capping values that are out of range, you will get the
  correct last day for each month.

  ## Examples

      date = from({{2013,3,5}, {23,23,23}})

      local(shift(date, secs: 24*3600*365))
      #=> {{2014,3,5}, {23,23,23}}

      local(shift(date, secs: -24*3600*(365*2 + 1)))  # +1 day for leap year 2012
      #=> {{2011,3,5}, {23,23,23}}

      local(shift(date, [secs: 13, day: -1, week: 2]))
      #=> {{2013,3,18}, {23,23,36}}

  """
  @spec shift(DateTime.t, list({atom(), term})) :: DateTime.t

  def shift(date, [{_, 0}]),               do: date
  def shift(date, [timestamp: {0,0,0}]),   do: date
  def shift(date, [timestamp: timestamp]), do: add(date, timestamp)
  def shift(%DateTime{:timezone => tz} = date, [{type, value}]) when type in [:secs, :mins, :hours] do
    secs = to_secs(date)
    secs = secs + case type do
      :secs   -> value
      :mins   -> value * 60
      :hours  -> value * 3600
    end
    shifted = from(secs, :secs)
    %{shifted | :timezone => tz}
  end
  def shift(%DateTime{:hour => h, :minute => m, :second => s, :timezone => tz} = date, [days: value]) do
    days = to_days(date)
    days = days + value
    shifted = from(days, :days) |> set([time: {h, m, s}])
    %{shifted | :timezone => tz}
  end
  def shift(date, [weeks: value]) do
    date |> shift([days: value * 7])
  end
  def shift(date, [months: value]) do
    %DateTime{
      :year => year, :month => month, :day => day,
      :hour => h, :minute => m, :second => s,
      :timezone => tz
    } = date

    month = month + value
    # Calculate a valid year value
    year = cond do
      month == 0 -> year - 1
      month < 0  -> year + div(month, 12) - 1
      month > 12 -> year + div(month - 1, 12)
      true       -> year
    end

    validate({year, round_month(month), day}) |> construct({h, m, s}, tz)
  end
  def shift(date, [years: value]) do
    %DateTime{
      :year => year, :month => month, :day => day,
      :hour => h, :minute => m, :second => s,
      :timezone => tz
    } = date
    validate({year + value, month, day}) |> construct({h, m, s}, tz)
  end

  Record.defrecordp :shift_rec, secs: 0, days: 0, years: 0

  # This clause will match lists with at least 2 values
  def shift(date, spec) when is_list(spec) do
    shift_rec(secs: sec, days: day, years: year)
      = Enum.reduce spec, shift_rec(), fn
        ({:timestamp, {mega, tsec, _}}, shift_rec(secs: sec) = rec) ->
          shift_rec(rec, [secs: sec + mega * @million + tsec])

        ({:secs, tsec}, shift_rec(secs: sec) = rec) ->
          shift_rec(rec, [secs: sec + tsec])

        ({:mins, min}, shift_rec(secs: sec) = rec) ->
          shift_rec(rec, [secs: sec + min * 60])

        ({:hours, hrs}, shift_rec(secs: sec) = rec) ->
          shift_rec(rec, [secs: sec + hrs * 3600])

        ({:days, days}, shift_rec(days: day) = rec) ->
          shift_rec(rec, [days: day + days])

        ({:weeks, weeks}, shift_rec(days: day) = rec) ->
          shift_rec(rec, [days: day + weeks * 7])

        ({:years, years}, shift_rec(years: year) = rec) ->
          shift_rec(rec, [years: year + years])

        ({:months, _}, _) ->
          raise ArgumentError, message: ":months not supported in bulk shifts"
      end

    # The order in which we apply secs and days is not important.
    # The year shift must always go last though.
    date |> shift([secs: sec]) |> shift([days: day]) |> shift([years: year])
  end

  # Primary constructor for DateTime objects
  defp construct({_,_,_} = date, {_,_,_} = time, nil), do: construct(date, time, timezone(:utc))
  defp construct({y, m, d}, {h, min, sec}, %TimezoneInfo{} = tz) do
    %DateTime{
      year: y, month: m, day: d,
      hour: h, minute: min, second: sec,
      timezone: tz
    }
  end
  defp construct({y, m, d}, {h, min, sec}, {_, name}) do
    %DateTime{
      year: y, month: m, day: d,
      hour: h, minute: min, second: sec,
      timezone: Timezone.get(name)
    }
  end
  def construct({date, time}, tz), do: construct(date, time, tz)

  defp validate({year, month, day}) do
    # Check if we got past the last day of the month
    max_day = days_in_month(year, month)
    if day > max_day do
      day = max_day
    end
    {year, month, day}
  end

  defp mod(a, b) do
    rem(rem(a, b) + b, b)
  end

  defp round_month(m) do
    case mod(m, 12) do
      0     -> 12
      other -> other
    end
  end

end
