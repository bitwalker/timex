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
  alias __MODULE__,         as: Date
  alias Timex.DateTime,     as: DateTime
  alias Timex.Time,         as: Time
  alias Timex.Timezone,     as: Timezone
  alias Timex.TimezoneInfo, as: TimezoneInfo

  # Date types
  @type year :: non_neg_integer
  @type month :: 1..12
  @type day :: 1..31
  @type daynum :: 1..366
  @type weekday :: 1..7
  @type weeknum :: 1..53
  @type num_of_days :: 28..31
  # Time types
  @type hour :: 0..23
  @type minute :: 0..59
  @type second :: 0..59
  @type timestamp :: {megaseconds, seconds, microseconds }
  @type megaseconds :: non_neg_integer
  @type seconds :: non_neg_integer
  @type microseconds :: non_neg_integer
  # Complex types
  @type time :: { hour, minute, second }
  @type date :: { year, month, day }
  @type datetime :: { date, time }
  @type dtz :: { datetime, TimezoneInfo.t }
  @type iso_triplet :: { year, weeknum, weekday }

  # Constants
  @valid_months 1..12
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
  # {is_leap_year, month, shift}
  @ordinal_day_map [
    {true, 1, 0}, {false, 1, 0},
    {true, 2, 31}, {false, 2, 31},
    {true, 3, 60}, {false, 3, 59},
    {true, 4, 91}, {false, 4, 90},
    {true, 5, 121}, {false, 5, 120},
    {true, 6, 152}, {false, 6, 151},
    {true, 7, 182}, {false, 7, 181},
    {true, 8, 213}, {false, 8, 212},
    {true, 9, 244}, {false, 9, 243},
    {true, 10, 274}, {false, 10, 273},
    {true, 11, 305}, {false, 11, 304},
    {true, 12, 335}, {false, 12, 334}
  ]

  @doc """
  Get a TimezoneInfo object for the specified offset or name.

  When offset or name is invalid, exception is raised.

  ## Examples

      iex> date = #{__MODULE__}.from({2015, 4, 12})
      iex> tz = #{__MODULE__}.timezone(:utc, date)
      iex> tz.full_name
      "UTC"

      iex> date = #{__MODULE__}.from({2015, 4, 12})
      iex> tz = #{__MODULE__}.timezone("America/Chicago", date)
      iex> {tz.full_name, tz.abbreviation}
      {"America/Chicago", "CDT"}

      iex> date = #{__MODULE__}.from({2015, 4, 12})
      iex> tz = #{__MODULE__}.timezone(+2, date)
      iex> {tz.full_name, tz.abbreviation}
      {"Etc/GMT-2", "GMT-2"}

  """
  @spec timezone(:local | :utc | number | binary, DateTime.t | nil) :: TimezoneInfo.t

  def timezone(:local, {{_,_,_},{_,_,_}}=datetime), do: Timezone.local(construct(datetime))
  def timezone(:local, %DateTime{}=date),           do: Timezone.local(date)
  def timezone(:utc, _),                            do: %TimezoneInfo{}
  defdelegate timezone(name, datetime),             to: Timezone, as: :get

  @doc """
  Get current date.

  ## Examples

      > #{__MODULE__}.now
      %Timex.DateTime{year: 2015, month: 6, day: 26, hour: 23, minute: 56, second: 12}

  """
  @spec now() :: DateTime.t
  def now do
    construct(calendar_universal_time(), %TimezoneInfo{})
  end

  @doc """
  Get the current date, in a specific timezone.

  ## Examples

      iex> %Timex.DateTime{timezone: tz} = #{__MODULE__}.now("America/Chicago")
      iex> tz.abbreviation in ["CST", "CDT"]
      true
      iex> tz.full_name === "America/Chicago"
      true
  """
  @spec now(binary) :: DateTime.t
  def now(tz) when is_binary(tz) do
    {{_,_,_}=date, {h,m,s,ms}} = calendar_universal_time()
    case Timezone.get(tz, {date, {h,m,s}}) do
      %TimezoneInfo{} = tzinfo ->
        construct({date, {h,m,s,ms}}, %TimezoneInfo{}) |> set(timezone: tzinfo)
      {:error, _} = error ->
        error
    end
  end

  @doc """
  Get representation of the current date in seconds or days since Epoch.

  See convert/2 for converting arbitrary dates to various time units.

  ## Examples

      > #{__MODULE__}.now(:secs)
      1363439013
      > #{__MODULE__}.now(:days)
      15780

  """
  @spec now(:secs | :days) :: integer

  def now(:secs), do: to_secs(now())
  def now(:days), do: to_days(now())

  @doc """
  Get current local date.

  See also `universal/0`.

  ## Examples

      > #{__MODULE__}.local
      %Timex.DateTime{year: 2013, month: 3, day: 16, hour: 11, minute: 1, second: 12, timezone: %TimezoneInfo{}}

  """
  @spec local() :: DateTime.t
  def local do
    date = construct(calendar_local_time())
    tz   = Timezone.local(date)
    %{date | :timezone => tz}
  end

  @doc """
  Convert a date to your local timezone.

  See also `universal/1`.

  ## Examples

      Date.now |> Date.local

  """
  @spec local(date :: DateTime.t) :: DateTime.t
  def local(%DateTime{:timezone => tz} = date) do
    case Timezone.local(date) do
      ^tz      -> date
      new_zone -> Timezone.convert(date, new_zone)
    end
  end

  @doc """
  Get current the current datetime in UTC.

  See also `local/0`. Delegates to `now/0`, since they are identical in behavior

  ## Examples

      > #{__MODULE__}.universal
      %Timex.DateTime{timezone: %Timex.TimezoneInfo{full_name: "UTC"}}

  """
  @spec universal() :: DateTime.t
  defdelegate universal, to: __MODULE__, as: :now

  @doc """
  Convert a date to UTC

  See also `local/1`.

  ## Examples

      > localdate = Date.local
      %Timex.DateTime{hour: 5, timezone: %Timex.TimezoneInfo{full_name: "America/Chicago"}}
      > localdate |> Date.universal
      %Timex.DateTime{hour: 10, timezone: %Timex.TimezoneInfo{full_name: "UTC"}}

  """
  @spec universal(DateTime.t) :: DateTime.t
  def universal(date), do: Timezone.convert(date, %TimezoneInfo{})

  @doc """
  The first day of year zero (calendar module's default reference date).

  See also `epoch/0`.

  ## Examples

      iex> date = %Timex.DateTime{year: 0, month: 1, day: 1, timezone: %Timex.TimezoneInfo{}}
      iex> #{__MODULE__}.zero === date
      true

  """
  @spec zero() :: DateTime.t
  def zero, do: construct({0, 1, 1}, {0, 0, 0}, %TimezoneInfo{})

  @doc """
  The date of Epoch, used as default reference date by this module
  and also by the Time module.

  See also `zero/0`.

  ## Examples

      iex> date = %Timex.DateTime{year: 1970, month: 1, day: 1, timezone: %Timex.TimezoneInfo{}}
      iex> #{__MODULE__}.epoch === date
      true

  """
  @spec epoch() :: DateTime.t
  def epoch, do: construct({1970, 1, 1}, {0, 0, 0}, %TimezoneInfo{})

  @doc """
  Time interval since year 0 of Epoch expressed in the specified units.

  ## Examples

      iex> #{__MODULE__}.epoch(:timestamp)
      {0,0,0}
      iex> #{__MODULE__}.epoch(:secs)
      62167219200

  """
  @spec epoch(:timestamp)   :: timestamp
  @spec epoch(:secs | :days)  :: integer

  def epoch(:timestamp), do: to_timestamp(epoch())
  def epoch(:secs),      do: to_secs(epoch(), :zero)

  @doc """
  Construct a date from Erlang's date or datetime value.

  You may specify the date's time zone as the second argument. If the argument
  is omitted, UTC time zone is assumed.

  When passing {year, month, day} as the first argument, the resulting date
  will indicate midnight of that day in the specified timezone (UTC by
  default).

  NOTE: When using `from` the input value is normalized to prevent invalid
  dates from being accidentally introduced. Use `set` with `validate: false`,
  or create the %DateTime{} by hand if you do not want normalization.
  ## Examples

      > Date.from(:erlang.universaltime)             #=> %DateTime{...}
      > Date.from(:erlang.localtime)                 #=> %Datetime{...}
      > Date.from(:erlang.localtime, :local)         #=> %DateTime{...}
      > Date.from({2014,3,16}, "America/Chicago")    #=> %DateTime{...}

  """
  @spec from(datetime | date) :: DateTime.t
  @spec from(datetime | date, :utc | :local | TimezoneInfo.t | binary) :: DateTime.t

  def from({y,m,d} = date) when is_integer(y) and is_integer(m) and is_integer(d), do: from(date, :utc)
  def from({{_,_,_},{_,_,_}} = datetime),          do: from(datetime, :utc)
  def from({{_,_,_},{_,_,_,_}} = datetime),        do: from(datetime, :utc)
  def from({_,_,_} = date, :utc),                  do: construct({date, {0,0,0}}, %TimezoneInfo{})
  def from({{_,_,_},{_,_,_}} = datetime, :utc),    do: construct(datetime, %TimezoneInfo{})
  def from({{_,_,_},{_,_,_,_}} = datetime, :utc),  do: construct(datetime, %TimezoneInfo{})
  def from({_,_,_} = date, :local),                do: from({date, {0,0,0}}, timezone(:local, {date, {0,0,0}}))
  def from({{_,_,_},{_,_,_}} = datetime, :local),  do: from(datetime, timezone(:local, datetime))
  def from({{_,_,_}=date,{h,min,sec,_}} = datetime, :local),do: from(datetime, timezone(:local, {date,{h, min, sec}}))
  def from({_,_,_} = date, %TimezoneInfo{} = tz),  do: from({date, {0,0,0}}, tz)
  def from({{_,_,_},{_,_,_}} = datetime, %TimezoneInfo{} = tz), do: construct(datetime, tz)
  def from({{_,_,_},{_,_,_,_}} = datetime, %TimezoneInfo{} = tz), do: construct(datetime, tz)
  def from({_,_,_} = date, tz) when is_binary(tz), do: from({date, {0, 0, 0}}, tz)
  def from({{_,_,_}=d,{h,m,s}}, tz) when is_binary(tz), do: from({d,{h,m,s,0}},tz)
  def from({{_,_,_}=date,{h,min,sec,_}} = datetime, tz) when is_binary(tz) do
    case timezone(tz, {date, {h,min,sec}}) do
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

      > Date.from(13, :secs)
      > Date.from(13, :days, :zero)
      > Date.from(Time.now, :timestamp)

  """
  @spec from(timestamp, :timestamp) :: DateTime.t
  @spec from(number, :us | :secs | :days)  :: DateTime.t
  @spec from(timestamp, :timestamp, :epoch | :zero) :: DateTime.t
  @spec from(number, :us | :secs | :days, :epoch | :zero)  :: DateTime.t
  def from(value, type, reference \\ :epoch)

  def from({mega, sec, us}, :timestamp, :epoch), do: from((mega * @million + sec) * @million + us, :us)
  def from({mega, sec, us}, :timestamp, :zero) do
    from((mega * @million + sec) * @million + us, :us, :zero)
  end
  def from(us, :us,   :epoch) do
    construct(calendar_gregorian_microseconds_to_datetime(us, epoch(:secs)), %TimezoneInfo{})
  end
  def from(us, :us,   :zero) do
    construct(calendar_gregorian_microseconds_to_datetime(us, 0), %TimezoneInfo{})
  end
  def from(sec, :secs, :epoch) do
    construct(:calendar.gregorian_seconds_to_datetime(trunc(sec) + epoch(:secs)), %TimezoneInfo{})
  end
  def from(sec, :secs, :zero) do
    construct(:calendar.gregorian_seconds_to_datetime(trunc(sec)), %TimezoneInfo{})
  end
  def from(days, :days, :epoch) do
    construct(:calendar.gregorian_days_to_date(trunc(days) + to_days(epoch(), :zero)), {0,0,0}, %TimezoneInfo{})
  end
  def from(days, :days, :zero) do
    construct(:calendar.gregorian_days_to_date(trunc(days)), {0,0,0}, %TimezoneInfo{})
  end

  @doc """
  Convert a date to a timestamp value consumable by the Time module.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.to_timestamp
      {0,0,0}

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
  With `to_secs/3`, you can also specify an option `utc: false | true`,
  which controls whether the DateTime is converted to UTC prior to calculating
  the number of seconds from the reference date. By default, UTC conversion is
  enabled.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      iex> #{__MODULE__}.from({{1999, 1, 2}, {12,13,14}}) |> #{__MODULE__}.to_secs
      915279194

  """
  @spec to_secs(DateTime.t) :: integer
  @spec to_secs(DateTime.t, :epoch | :zero) :: integer
  @spec to_secs(DateTime.t, :epoch | :zero, [utc: false | true]) :: integer
  def to_secs(date, reference \\ :epoch, options \\ [utc: true])

  def to_secs(date, :epoch, utc: true), do: to_secs(date, :zero) - epoch(:secs)
  def to_secs(date, :zero, utc: true) do
    offset = Timex.Timezone.diff(date, %TimezoneInfo{})
    case offset do
      0 -> utc_to_secs(date)
      _ -> utc_to_secs(date) + ( 60 * offset )
    end
  end
  def to_secs(date, :epoch, utc: false), do: to_secs(date, :zero, utc: false) - epoch(:secs)
  def to_secs(date, :zero, utc: false), do: utc_to_secs(date)

  defp utc_to_secs(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => s}) do
    :calendar.datetime_to_gregorian_seconds({{y, m, d}, {h, min, s}})
  end


  @doc """
  Convert the date to an integer number of days since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitray reference date.

  ## Examples

      iex> #{__MODULE__}.from({1970, 1, 15}) |> #{__MODULE__}.to_days
      14

  """
  @spec to_days(DateTime.t) :: integer
  @spec to_days(DateTime.t, :epoch | :zero) :: integer
  def to_days(date, reference \\ :epoch)

  def to_days(date, :epoch), do: to_days(date, :zero) - to_days(epoch(), :zero)
  def to_days(%DateTime{:year => y, :month => m, :day => d}, :zero) do
    :calendar.date_to_gregorian_days({y, m, d})
  end

  @doc """
  Gets the current century

  ## Examples

      iex> #{__MODULE__}.century
      21

  """
  @spec century() :: non_neg_integer
  def century(), do: Date.now |> century

  @doc """
  Given a date, get the century this date is in.

  ## Examples

      iex> #{__MODULE__}.now |> #{__MODULE__}.century
      21

  """
  @spec century(DateTime.t) :: non_neg_integer
  def century(%DateTime{:year => y}) do
    base_century = div(y, 100)
    years_past   = rem(y, 100)
    cond do
      base_century == (base_century - years_past) -> base_century
      true -> base_century + 1
    end
  end

  @doc """
  Return weekday number (as defined by ISO 8601) of the specified date.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.weekday
      4 # (i.e. Thursday)

  """
  @spec weekday(DateTime.t) :: weekday

  def weekday(%DateTime{:year => y, :month => m, :day => d}), do: :calendar.day_of_the_week({y, m, d})

  @doc """
  Returns the ordinal day number of the date.

  ## Examples

      iex> #{__MODULE__}.from({{2015,6,26},{0,0,0}}) |> #{__MODULE__}.day
      177
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

      # Creating a DateTime from the given day
      iex> expected = #{__MODULE__}.from({{2015, 6, 29}, {0,0,0}})
      iex> (#{__MODULE__}.from_iso_day(180) === expected)
      true

      # Shifting a DateTime to the given day
      iex> date = #{__MODULE__}.from({{2015,6,26}, {12,0,0}})
      iex> expected = #{__MODULE__}.from({{2015, 6, 29}, {12,0,0}})
      iex> (#{__MODULE__}.from_iso_day(180, date) === expected)
      true
  """
  @spec from_iso_day(non_neg_integer, DateTime.t | nil) :: DateTime.t
  def from_iso_day(day, date \\ nil)

  def from_iso_day(day, nil) do
    {{year,_,_},_} = :calendar.universal_time
    datetime = iso_day_to_date_tuple(year, day)
    Date.from(datetime)
  end
  def from_iso_day(day, %DateTime{year: year} = date) do
    {year, month, day_of_month} = iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end
  defp iso_day_to_date_tuple(year, day) do
    {year, day} = cond do
      day < 1 && :calendar.is_leap_year(year - 1) -> {year - 1, day + 366}
      day < 1                                     -> {year - 1, day + 365}
      day > 366 && :calendar.is_leap_year(year)   -> {year, day - 366}
      day > 365                                   -> {year, day - 365}
      true                                        -> {year, day}
    end
    {_, month, first_of_month} = Enum.take_while(@ordinal_day_map, fn {_, _, oday} -> oday <= day end) |> List.last
    {year, month, day - first_of_month}
  end

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that date falls
  on.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.iso_week
      {1970,1}

  """
  @spec iso_week(DateTime.t) :: {year, weeknum}

  def iso_week(%DateTime{:year => y, :month => m, :day => d}) do
    :calendar.iso_week_number({y, m, d})
  end
  def iso_week(date), do: iso_week(from(date, :utc))

  @doc """
  Get the day of the week corresponding to the given name.

  ## Examples

      iex> #{__MODULE__}.day_to_num("Monday")
      1
      iex> #{__MODULE__}.day_to_num("monday")
      1
      iex> #{__MODULE__}.day_to_num("Mon")
      1
      iex> #{__MODULE__}.day_to_num("mon")
      1
      iex> #{__MODULE__}.day_to_num(:mon)
      1

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

  ## Examples

      iex> #{__MODULE__}.day_name(1)
      "Monday"
      iex> #{__MODULE__}.day_name(0)
      {:error, "Invalid day num: 0"}
  """
  @spec day_name(weekday) :: binary
  @weekdays |> Enum.each fn {name, day_num} ->
    def day_name(unquote(day_num)), do: unquote(name)
  end
  def day_name(x), do: {:error, "Invalid day num: #{x}"}

  @doc """
  Get the short name of the day corresponding to the provided number

  ## Examples

      iex> #{__MODULE__}.day_shortname(1)
      "Mon"
      iex> #{__MODULE__}.day_shortname(0)
      {:error, "Invalid day num: 0"}
  """
  @spec day_shortname(weekday) :: binary
  @weekdays |> Enum.each fn {name, day_num} ->
    def day_shortname(unquote(day_num)), do: String.slice(unquote(name), 0..2)
  end
  def day_shortname(x), do: {:error, "Invalid day num: #{x}"}

  @doc """
  Get the number of the month corresponding to the given name.

  ## Examples

      iex> #{__MODULE__}.month_to_num("January")
      1
      iex> #{__MODULE__}.month_to_num("january")
      1
      iex> #{__MODULE__}.month_to_num("Jan")
      1
      iex> #{__MODULE__}.month_to_num("jan")
      1
      iex> #{__MODULE__}.month_to_num(:jan)
      1
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

  ## Examples

      iex> #{__MODULE__}.month_name(1)
      "January"
      iex> #{__MODULE__}.month_name(0)
      {:error, "Invalid month num: 0"}
  """
  @spec month_name(month) :: binary
  @months |> Enum.each fn {name, month_num} ->
    def month_name(unquote(month_num)), do: unquote(name)
  end
  def month_name(x), do: {:error, "Invalid month num: #{x}"}

  @doc """
  Get the short name of the month corresponding to the provided number

  ## Examples

      iex> #{__MODULE__}.month_name(1)
      "January"
      iex> #{__MODULE__}.month_name(0)
      {:error, "Invalid month num: 0"}
  """
  @spec month_shortname(month) :: binary
  @months |> Enum.each fn {name, month_num} ->
    def month_shortname(unquote(month_num)), do: String.slice(unquote(name), 0..2)
  end
  def month_shortname(x), do: {:error, "Invalid month num: #{x}"}

  @doc """
  Return a 3-tuple {year, week number, weekday} for the given date.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.iso_triplet
      {1970, 1, 4}

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

      iex> expected = #{__MODULE__}.from({2014, 1, 28})
      iex> #{__MODULE__}.from_iso_triplet({2014, 5, 2}) === expected
      true

  """
  @spec from_iso_triplet(iso_triplet) :: DateTime.t
  def from_iso_triplet({year, week, weekday}) do
    {_, _, jan4weekday} = Date.from({year, 1, 4}) |> iso_triplet
    offset = jan4weekday + 3
    ordinal_date = ((week * 7) + weekday) - offset
    datetime = iso_day_to_date_tuple(year, ordinal_date)
    Date.from(datetime)
  end

  @doc """
  Return the number of days in the month which the date falls on.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.days_in_month
      31

  """
  @spec days_in_month(DateTime.t | {year, month}) :: num_of_days
  def days_in_month(%DateTime{:year => year, :month => month}) when year >= 0 and month in @valid_months do
    :calendar.last_day_of_the_month(year, month)
  end
  def days_in_month(year, month) when year >= 0 and month in @valid_months do
    :calendar.last_day_of_the_month(year, month)
  end
  def days_in_month(year, month) do
    valid_year?  = year > 0
    valid_month? = month in @valid_months
    cond do
      !valid_year? && valid_month? ->
        raise ArgumentError, message: "Invalid year passed to days_in_month/2: #{year}"
      valid_year? && !valid_month? ->
        raise ArgumentError, message: "Invalid month passed to days_in_month/2: #{month}"
      true ->
        raise ArgumentError, message: "Invalid year/month pair passed to days_in_month/2: {#{year}, #{month}}"
    end
  end

  @doc """
  Return a boolean indicating whether the given year is a leap year. You may
  pase a date or a year number.

  ## Examples

      iex> #{__MODULE__}.epoch |> #{__MODULE__}.is_leap?
      false
      iex> #{__MODULE__}.is_leap?(2012)
      true

  """
  @spec is_leap?(DateTime.t | year) :: boolean
  def is_leap?(year) when is_integer(year), do: :calendar.is_leap_year(year)
  def is_leap?(%DateTime{:year => year}),   do: is_leap?(year)

  @doc """
  Return a boolean indicating whether the given date is valid.

  ## Examples

      iex> #{__MODULE__}.from({{1,1,1}, {1,1,1}}) |> #{__MODULE__}.is_valid?
      true
      iex> %Timex.DateTime{} |> #{__MODULE__}.set([month: 13, validate: false]) |> #{__MODULE__}.is_valid?
      false
      iex> %Timex.DateTime{} |> #{__MODULE__}.set(hour: -1) |> #{__MODULE__}.is_valid?
      false

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

  defp is_valid_tz?(%TimezoneInfo{:full_name => tzname}), do: Timezone.exists?(tzname)
  defp is_valid_tz?(_), do: false

  @doc """
  Produce a valid date from a possibly invalid one.

  All date's components will be clamped to the minimum or maximum valid value.

  ## Examples

      iex> expected = #{__MODULE__}.from({{1, 12, 31}, {0, 59, 59}}, :local)
      iex> date     = {{1,12,31},{0,59,59}}
      iex> localtz  = Timex.Timezone.local(date)
      iex> result   = {{1,12,31},{0,59,59}, localtz} |> #{__MODULE__}.normalize |> #{__MODULE__}.local
      iex> result === expected
      true

  """
  @spec normalize(datetime | dtz | {date, time, TimezoneInfo.t}) :: DateTime.t

  def normalize({{_,_,_}=date, time}), do: normalize({date, time, %TimezoneInfo{}})
  def normalize({{_,_,_}=date, time, tz}) do
    construct(do_normalize(:date, date), do_normalize(:time, time), tz)
  end

  @spec do_normalize(atom(), term) :: DateTime.t
  defp do_normalize(:date, {year, month, day}) do
    year  = do_normalize(:year, year)
    month = do_normalize(:month, month)
    day   = do_normalize(:day, {year, month, day})
    {year, month, day}
  end
  defp do_normalize(:year, year) when year < 0, do: 0
  defp do_normalize(:year, year), do: year
  defp do_normalize(:month, month) do
    cond do
      month < 1   -> 1
      month > 12  -> 12
      true        -> month
    end
  end
  defp do_normalize(:time, {hour,min,sec}) do
    hour  = do_normalize(:hour, hour)
    min   = do_normalize(:minute, min)
    sec   = do_normalize(:second, sec)
    {hour, min, sec}
  end
  defp do_normalize(:time, {hour,min,sec,ms}) do
    {h,m,s} = do_normalize(:time, {hour,min,sec})
    msecs   = do_normalize(:ms, ms)
    {h, m, s, msecs}
  end
  defp do_normalize(:hour, hour) do
    cond do
      hour < 0    -> 0
      hour > 23   -> 23
      true        -> hour
    end
  end
  defp do_normalize(:minute, min) do
    cond do
      min < 0    -> 0
      min > 59   -> 59
      true       -> min
    end
  end
  defp do_normalize(:second, sec) do
    cond do
      sec < 0    -> 0
      sec > 59   -> 59
      true       -> sec
    end
  end
  defp do_normalize(:ms, ms) do
    cond do
      ms < 0   -> 0
      ms > 999 -> 999
      true     -> ms
    end
  end
  defp do_normalize(:timezone, tz), do: tz
  defp do_normalize(:day, {year, month, day}) do
    year  = do_normalize(:year, year)
    month = do_normalize(:month, month)
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

      iex> now = #{__MODULE__}.epoch
      iex> #{__MODULE__}.set(now, date: {1,1,1})
      %Timex.DateTime{year: 1, month: 1, day: 1, hour: 0, minute: 0, second: 0, timezone: %Timex.TimezoneInfo{}, calendar: :gregorian}
      iex> #{__MODULE__}.set(now, hour: 8)
      %Timex.DateTime{year: 1970, month: 1, day: 1, hour: 8, minute: 0, second: 0, timezone: %Timex.TimezoneInfo{}, calendar: :gregorian}
      iex> #{__MODULE__}.set(now, [date: {2013,3,26}, hour: 30])
      %Timex.DateTime{year: 2013, month: 3, day: 26, hour: 23, minute: 0, second: 0, timezone: %Timex.TimezoneInfo{}, calendar: :gregorian}
      iex> #{__MODULE__}.set(now, [
      ...>   datetime: {{2013,3,26}, {12,30,0}},
      ...>   date: {2014,4,12}
      ...>])
      %Timex.DateTime{year: 2014, month: 4, day: 12, hour: 12, minute: 30, second: 0, timezone: %Timex.TimezoneInfo{}, calendar: :gregorian}
      iex> #{__MODULE__}.set(now, [minute: 74, validate: false])
      %Timex.DateTime{year: 1970, month: 1, day: 1, hour: 0, minute: 74, second: 0, timezone: %Timex.TimezoneInfo{}, calendar: :gregorian}

  """
  @spec set(DateTime.t, list({atom(), term})) :: DateTime.t
  def set(%DateTime{} = date, options) do
    validate? = case options |> List.keyfind(:validate, 0, true) do
      {:validate, bool} -> bool
      _                 -> true
    end
    Enum.reduce options, date, fn option, result ->
      case option do
        {:validate, _} -> result
        {:datetime, {{y, m, d}, {h, min, sec}}} ->
          if validate? do
            %{result |
              :year =>   do_normalize(:year,   y),
              :month =>  do_normalize(:month,  m),
              :day =>    do_normalize(:day,    {y,m,d}),
              :hour =>   do_normalize(:hour,   h),
              :minute => do_normalize(:minute, min),
              :second => do_normalize(:second, sec)
            }
          else
            %{result | :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}
          end
        {:date, {y, m, d}} ->
          if validate? do
            {yn,mn,dn} = do_normalize(:date, {y,m,d})
            %{result | :year => yn, :month => mn, :day => dn}
          else
            %{result | :year => y, :month => m, :day => d}
          end
        {:time, {h, m, s}} ->
          if validate? do
            %{result | :hour => do_normalize(:hour, h), :minute => do_normalize(:minute, m), :second => do_normalize(:second, s)}
          else
            %{result | :hour => h, :minute => m, :second => s}
          end
        {:day, d} ->
          if validate? do
            %{result | :day => do_normalize(:day, {result.year, result.month, d})}
          else
            %{result | :day => d}
          end
        {:timezone, tz} ->
          tz = case tz do
            %TimezoneInfo{} -> tz
            _ -> Timezone.get(tz, result)
          end
          if validate? do
            %{result | :timezone => do_normalize(:timezone, tz)}
          else
            %{result | :timezone => tz}
          end
        {name, val} when name in [:year, :month, :hour, :minute, :second, :ms] ->
          if validate? do
            Map.put(result, name, do_normalize(name, val))
          else
            Map.put(result, name, val)
          end
        {option_name, _}   -> raise "Invalid option passed to Date.set: #{option_name}"
      end
    end
  end

  @doc """
  Compare two dates returning one of the following values:

   * `-1` -- the first date comes before the second one
   * `0`  -- both arguments represent the same date when coalesced to the same timezone.
   * `1`  -- the first date comes after the second one

  You can optionality specify a granularity of any of

  :years :months :weeks :days :hours :mins :secs :timestamp

  and the dates will be compared with the cooresponding accuracy.
  The default granularity is :secs.

  ## Examples

      iex> date1 = #{__MODULE__}.from({2014, 3, 4})
      iex> date2 = #{__MODULE__}.from({2015, 3, 4})
      iex> #{__MODULE__}.compare(date1, date2, :years)
      -1
      iex> #{__MODULE__}.compare(date2, date1, :years)
      1
      iex> #{__MODULE__}.compare(date1, date1)
      0

  """
  @spec compare(DateTime.t, DateTime.t | :epoch | :zero | :distant_past | :distant_future) :: -1 | 0 | 1
  @spec compare(DateTime.t, DateTime.t, :years | :months | :weeks | :days | :hours | :mins | :secs | :timestamp) :: -1 | 0 | 1

  def compare(date, :epoch),       do: compare(date, epoch())
  def compare(date, :zero),        do: compare(date, zero())
  def compare(_, :distant_past),   do: +1
  def compare(_, :distant_future), do: -1
  def compare(date, date),         do: 0
  def compare(a, b),               do: compare(a, b, :secs)
  def compare( this, other, granularity)
    when granularity in [:years, :months, :weeks, :days, :hours, :mins, :secs, :timestamp] do
    difference = diff(this, other, granularity)
    cond do
      difference < 0  -> +1
      difference == 0 -> 0
      difference > 0  -> -1
    end
  end
  def compare(_, _, _), do: {:error, "Invalid comparison granularity."}

  @doc """
  Determine if two dates represent the same point in time

  ## Examples

      iex> date1 = #{__MODULE__}.from({2014, 3, 1})
      iex> date2 = #{__MODULE__}.from({2014, 3, 1})
      iex> #{__MODULE__}.equal?(date1, date2)
      true
  """
  @spec equal?(DateTime.t, DateTime.t) :: boolean
  def equal?(this, other), do: compare(this, other) == 0

  @doc """
  Calculate time interval between two dates. If the second date comes after the
  first one in time, return value will be positive; and negative otherwise.
  You must specify one of the following units:

  :years :months :weeks :days :hours :mins :secs :timestamp

  and the result will be an integer value of those units or a timestamp.
  """
  @spec diff(DateTime.t, DateTime.t, :timestamp) :: timestamp
  @spec diff(DateTime.t, DateTime.t, :secs | :mins | :hours | :days | :weeks | :months | :years) :: integer

  def diff(this, other, :timestamp) do
    diff(this, other, :secs) |> Time.from(:secs)
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

  def add(%DateTime{} = date, {mega, sec, _}) do
    shift(date, [secs: (mega * @million) + sec])
  end

  @doc """
  Subtract time from a date using a timestamp, i.e. {megasecs, secs, microsecs}
  Same as shift(date, Time.to_timestamp(5, :mins) |> Time.invert, :timestamp).
  """
  @spec subtract(DateTime.t, timestamp) :: DateTime.t

  def subtract(%DateTime{} = date, {mega, sec, _}) do
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

  def shift(%DateTime{} = date, [{_, 0}]),               do: date
  def shift(%DateTime{} = date, [timestamp: {0,0,0}]),   do: date
  def shift(%DateTime{} = date, [timestamp: timestamp]), do: add(date, timestamp)
  def shift(%DateTime{timezone: tz} = date, [{type, value}]) when type in [:secs, :mins, :hours] do
    secs = to_secs(date, :epoch, utc: false)
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
  def shift(%DateTime{} = date, [weeks: value]) do
    date |> shift([days: value * 7])
  end
  def shift(%DateTime{} = date, [months: value]) do
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
  def shift(%DateTime{} = date, [years: value]) do
    %DateTime{
      :year => year, :month => month, :day => day,
      :hour => h, :minute => m, :second => s,
      :timezone => tz
    } = date
    validate({year + value, month, day}) |> construct({h, m, s}, tz)
  end

  Record.defrecordp :shift_rec, secs: 0, days: 0, years: 0

  # This clause will match lists with at least 2 values
  def shift(%DateTime{} = date, spec) when is_list(spec) do
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
  defp construct({{_, _, _} = date, {_, _, _} = time}),      do: construct(date, time, %TimezoneInfo{})
  defp construct({{_, _, _} = date, {_, _, _, _} = time}),   do: construct(date, time, %TimezoneInfo{})
  defp construct({_,_,_} = date, {_,_,_} = time, nil),       do: construct(date, time, %TimezoneInfo{})
  defp construct({_,_,_} = date, {_,_,_,_} = time, nil),     do: construct(date, time, %TimezoneInfo{})
  defp construct(date, {h, min, sec}, %TimezoneInfo{} = tz), do: construct(date, {h, min, sec, 0}, tz)
  defp construct({_,_,_}=date, {_,_,_,_}=time, %TimezoneInfo{} = tz) do
    {y,m,d}        = do_normalize(:date, date)
    {h,min,sec,ms} = do_normalize(:time, time)
    %DateTime{
      year: y, month: m, day: d,
      hour: h, minute: min, second: sec,
      ms: ms,
      timezone: tz
    }
  end
  defp construct({_,_,_}=date, {_,_,_,_}=time, {_, name}) do
    {y,m,d}        = do_normalize(:date, date)
    {h,min,sec,ms} = do_normalize(:time, time)
    dt = %DateTime{
      year: y, month: m, day: d,
      hour: h, minute: min, second: sec,
      ms: ms
    }
    %{dt | :timezone => Timezone.get(name, dt)}
  end
  defp construct(date, {h, min, sec}, tz), do: construct(date, {h, min, sec, 0}, tz)
  defp construct({date, time}, tz), do: construct(date, time, tz)

  defp validate({year, month, day}) do
    # Check if we got past the last day of the month
    max_day = days_in_month(year, month)
    if day > max_day do
      day = max_day
    end
    {year, month, day}
  end

  defp mod(a, b), do: rem(rem(a, b) + b, b)

  defp round_month(m) do
    case mod(m, 12) do
      0     -> 12
      other -> other
    end
  end

  defp calendar_universal_time() do
    {_, _, us} = ts = Timex.Time.now
    {d,{h,min,sec}} = :calendar.now_to_universal_time(ts)
    {d,{h,min,sec,round(us/1000)}}
  end

  defp calendar_local_time() do
    {_, _, us} = ts = Timex.Time.now
    {d,{h,min,sec}} = :calendar.now_to_local_time(ts)
    {d,{h,min,sec,round(us/1000)}}
  end

  defp calendar_gregorian_microseconds_to_datetime(us, addseconds) do
    sec = div(us, @million)
    u   = rem(us, @million)
    {d,{h,m,s}} = :calendar.gregorian_seconds_to_datetime(sec + addseconds)
    {d,{h,m,s,round(u/1000)}}
  end

end
