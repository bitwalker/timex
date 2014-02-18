# Consider adding the following functions
# next(date, type) = shift(date, 1, type)
# prev(date, type) = shift(date, -1, type)

defmodule Date.Helper do
  @moduledoc false

  defp body(arg, name, priv) do
    quote do
      def unquote(name)(date, [{unquote(arg), value}]) do
        greg_date = Date.Conversions.to_gregorian(date)
        { date, time, tz } = unquote(priv)(greg_date, unquote(arg), value)
        make_date(date, time, tz)
      end
    end
  end

  defmacro def_set(arg) do
    body(arg, :set, :set_priv)
  end

  defmacro def_rawset(arg) do
    body(arg, :rawset, :rawset_priv)
  end
end

defmodule Date do
  @moduledoc """
  Module for working with dates.

  Functions that produce time intervals use UNIX epoch (or simly Epoch) as
  default reference date. Epoch is defined as UTC midnight of January 1, 1970.

  Time intervals in this module don't account for leap seconds.

  Supported tasks:

    * get current date in the desired time zone
    * convert dates between time zones and time units
    * introspect dates to find out weekday, week number, number of days in
      a given month, etc.
    * parse dates from string
    * compare dates
    * date arithmetic

  """

  ## Primary constructor for time zones
  defmacrop make_tz(:utc) do
    { 0.0, "UTC" }
  end

  defmacrop make_tz(offset, name) do
    quote do
      { unquote(offset), unquote(name) }
    end
  end

  ## Primary constructor for dates
  defmacrop make_date(datetime, tz) do
    quote do
      Date.Helpers.from(unquote(datetime), unquote(tz))
    end
  end

  defmacrop make_date(date, time, tz) do
    quote do
      Date.Helpers.from(unquote(date), unquote(time), unquote(tz))
    end
  end

  ### Base types ###

  @type dtz :: { datetime, tz }
  @type tz :: { number, binary }

  @type datetime :: { date, time }

  @type date :: { year, month, day }
  @type year :: non_neg_integer
  @type month :: 1..12
  @type day :: 1..31
  @type daynum :: 1..366
  @type weekday :: 1..7
  @type weeknum :: 1..53
  @type num_of_days :: 28..31

  @type time :: { hour, minute, second }
  @type hour :: 0..23
  @type minute :: 0..59
  @type second :: 0..59

  # Same as Time's timestamp type
  @type timestamp :: {megaseconds, seconds, microseconds }
  @type megaseconds :: non_neg_integer
  @type seconds :: non_neg_integer
  @type microseconds :: non_neg_integer

  ### Constructing time zone objects ###

  @doc """
  Get a time zone object for the specified offset or name.

  When offset or name is invalid, ArgumentError exception is raised.

  ## Examples

      timezone()       #=> <local time zone>
      timezone(:utc)   #=> { 0.0, "UTC" }
      timezone(2)      #=> { 2.0, "EET" }
      timezone("EET")  #=> { 2.0, "EET" }

  """
  @spec timezone() :: tz
  @spec timezone(:local | :utc | number | binary) :: tz
  def timezone(spec \\ :local)

  def timezone(:local) do
    # FIXME: change implementation for cross-platform support
    datestr = System.cmd('date "+%z %Z"')
    { :ok, [offs|[name]], _ } = :io_lib.fread('~d ~s', datestr)

    hours_offs = div(offs, 100)
    min_offs = offs - hours_offs * 100
    offset = hours_offs + min_offs / 60

    #datetime = :calendar.universal_time()
    #local_time = :calendar.universal_time_to_local_time(datetime)
    #hour_offset = (:calendar.datetime_to_gregorian_seconds(local_time) - :calendar.datetime_to_gregorian_seconds(datetime)) / 3600
    #timezone(hour_offset, "TimeZoneName")

    make_tz(offset, to_string(name))
  end

  def timezone(:utc) do
    make_tz(:utc)
  end

  def timezone(offset) when is_number(offset) do
    # FIXME: fetch time zone name
    tz = make_tz(offset, "TimeZoneName")
    if not is_valid_tz(tz) do
      raise ArgumentError, message: "Time zone with given name not found"
    else
      tz
    end
  end

  def timezone(name) when is_binary(name) do
    # TODO: determine the offset
    tz = make_tz(2, name)
    if not is_valid_tz(tz) do
      raise ArgumentError, message: "Time zone with given offset not found"
    else
      tz
    end
  end

  @doc """
  Return a time zone object for the given offset-name combination.

  ArgumentError exception is raised in the case of invalid or non-matching
  arguments.

  ## Examples

      timezone(2, "EET")  #=> { 2.0, "EET" }
      timezone(2, "PST")  #=> <ArgumentError>

  """
  @spec timezone(number, binary) :: tz
  def timezone(offset, name) when is_number(offset) and is_binary(name) do
    tz = make_tz(offset, name)
    if not is_valid_tz(tz) do
      raise ArgumentError, message: "Time zone with given name and offset combination not found"
    else
      tz
    end
  end

  ### Getting the date ###

  @doc """
  Get current date.

  ## Examples

      now  #=> { {{2013,3,16}, {11,1,12}}, {2.0,"EET"} }

  """
  @spec now() :: dtz
  def now do
    datetime = :calendar.universal_time()
    tz = timezone()
    make_date(datetime, tz)
  end

  @doc """
  Get representation of the current date in seconds or days since Epoch.

  See convert/2 for converting arbitrary dates to various time units.

  ## Examples

      now(:sec)   #=> 1363439013
      now(:day)  #=> 15780

  """
  @spec now(:sec | :day) :: integer
  def now(:sec) do
    to_sec(now())
  end

  def now(:day) do
    to_days(now())
  end

  @doc """
  Get current local date.

  See also `universal/0`.

  ## Examples

      local()  #=> {{2013,3,16}, {14,28,42}}

  """
  @spec local() :: datetime
  def local do
    #local(now)
    :calendar.local_time()
  end

  @doc """
  Convert date to local date in the date's time zone. If you'd like to specify
  time zone local to your system, use `local/2`.

  See also `universal/1`.

  ## Examples

      local(now())  #=> {{2013,3,16}, {14,29,22}} (same as local())

  """
  @spec local(dtz) :: datetime
  def local(date) do
    { date, time, {offset,_} } = Date.Conversions.to_gregorian(date)
    sec = :calendar.datetime_to_gregorian_seconds({date, time}) + offset * 3600
    :calendar.gregorian_seconds_to_datetime(trunc(sec))
  end

  @doc """
  Convert date to local date using the provided time zone.

  ## Examples

      local(now(), timezone(:utc))  #=> {{2013,3,16}, {12,29,22}}

  """
  @spec local(dtz, tz) :: datetime
  def local(date, tz) do
    { date, time, _ } = Date.Conversions.to_gregorian(date)
    local(make_date(date, time, tz))
  end

  @doc """
  Get current UTC date.

  See also `local/0`.

  ## Examples

      universal()  #=> {{2013,3,16}, {12,33,6}}

  """
  @spec universal() :: datetime
  def universal do
    #universal(now)
    :calendar.universal_time()
  end

  @doc """
  Convert date to UTC date.

  See also `local/1`.

  ## Examples

      universal(now())  #=> {{2013,3,16}, {12,33,16}}

  """
  @spec universal(dtz) :: datetime
  def universal(date) do
    { date, time, _ } = Date.Conversions.to_gregorian(date)
    { date, time }
  end

  @doc """
  The first day of year zero (calendar's module default reference date).

  See also `epoch/0`.

  ## Examples

      to_sec(zero(), :zero)  #=> 0

  """
  @spec zero() :: dtz
  def zero do
    make_date({0,1,1}, {0,0,0}, make_tz(:utc))
  end

  @doc """
  The date of Epoch (used as default reference date by this module and also by
  Time module).

  See also `zero/0`.

  ## Examples

      to_sec(epoch())  #=> 0

  """
  @spec epoch() :: dtz
  def epoch do
    make_date({1970,1,1}, {0,0,0}, make_tz(:utc))
  end

  @doc """
  Time interval since year 0 to Epoch expressed in the specified units.

  ## Examples

      epoch()       #=> {{{1970,1,1},{0,0,0}},{0.0,"UTC"}}
      epoch(:sec)   #=> 62167219200
      epoch(:day)  #=> 719528

  """
  @spec epoch(:timestamp)   :: timestamp
  @spec epoch(:sec | :day) :: integer
  def epoch(:timestamp) do
    to_timestamp(epoch)
  end

  def epoch(:sec) do
    to_sec(epoch, :zero)
  end

  def epoch(:day) do
    to_days(epoch, :zero)
  end

  ### Constructing the date from an existing value ###

  @doc """
  Construct a date from Erlang's date or datetime value.

  You may specify the date's time zone as the second argument. If the argument
  is omitted, UTC time zone is assumed.

  When passing {year, month, day} as the first argument, the resulting date
  will indicate midnight of that day in the specified timezone (UTC by
  default).

  ## Examples

      from(:erlang.universaltime)      #=> { {{2013,3,16}, {12,22,20}}, {0.0,"UTC"} }

      from(:erlang.localtime)          #=> { {{2013,3,16}, {14,18,41}}, {0.0,"UTC"} }
      from(:erlang.localtime, :local)  #=> { {{2013,3,16}, {12,18,51}}, {2.0,"EET"} }

      tz = Date.timezone(-8, "PST")
      from({2013,3,16}, tz)            #=> { {{2013,3,16}, {8,0,0}}, {-8,"PST"} }

  """
  @spec from(date | datetime) :: dtz
  @spec from(date | datetime, :utc | :local | tz) :: dtz

  def from(date={_,_,_}) do
    from(date, :utc)
  end

  def from(datetime={ {_,_,_},{_,_,_} }) do
    from(datetime, :utc)
  end

  def from(date={_,_,_}, :utc) do
    make_date({date, {0,0,0}}, make_tz(:utc))
  end

  def from(datetime={ {_,_,_},{_,_,_} }, :utc) do
    make_date(datetime, make_tz(:utc))
  end

  def from(date={_,_,_}, :local) do
    from({date, {0,0,0}}, timezone())
  end

  def from(datetime={ {_,_,_},{_,_,_} }, :local) do
    from(datetime, timezone())
  end

  def from(date={_,_,_}, tz={_,_}) do
    from({date, {0,0,0}}, tz)
  end

  def from(datetime={ {_,_,_},{_,_,_} }, tz={offset,_}) do
    # convert datetime to UTC
    sec = :calendar.datetime_to_gregorian_seconds(datetime) - offset * 3600
    make_date(:calendar.gregorian_seconds_to_datetime(trunc(sec)), tz)
  end

  @doc """
  Construct a date from a time interval since Epoch or year 0.

  UTC time zone is assumed. This assumption can be modified by setting desired
  time zone using set/3 after the date is constructed.

  ## Examples

      from(13, :sec)          #=> { {{1970,1,1}, {0,0,13}}, {0.0,"UTC"} }
      from(13, :day, :zero)  #=> { {{0,1,14}, {0,0,0}}, {0.0,"UTC"} }

      date = from(Time.now, :timestamp)
      set(date, :tz, timezone())     #=> yields the same value as Date.now would

  """
  @spec from(timestamp, :timestamp) :: dtz
  @spec from(number, :sec | :day)  :: dtz
  @spec from(timestamp, :timestamp, :epoch | :zero) :: dtz
  @spec from(number, :sec | :day, :epoch | :zero)  :: dtz
  def from(value, type, reference \\ :epoch)

  def from({mega, sec, _}, :timestamp, :epoch) do
    from(mega * _million + sec, :sec)
  end

  def from({mega, sec, _}, :timestamp, :zero) do
    from(mega * _million + sec, :sec, :zero)
  end

  def from(sec, :sec, :epoch) do
    make_date(:calendar.gregorian_seconds_to_datetime(trunc(sec) + epoch(:sec)), make_tz(:utc))
  end

  def from(sec, :sec, :zero) do
    make_date(:calendar.gregorian_seconds_to_datetime(trunc(sec)), make_tz(:utc))
  end

  def from(days, :day, :epoch) do
    make_date(:calendar.gregorian_days_to_date(trunc(days) + epoch(:day)), {0,0,0}, make_tz(:utc))
  end

  def from(days, :day, :zero) do
    make_date(:calendar.gregorian_days_to_date(trunc(days)), {0,0,0}, make_tz(:utc))
  end

  # FIXME: support custom reference date

  ### Converting dates ###

  @doc """
  Multi-purpose conversion function. Converts a date to the specified time
  interval since Epoch. If you'd like to specify year 0 as a reference date,
  use one of the to_* functions.

  ## Examples

      date = now()
      convert(date, :sec) + epoch(:sec) == to_sec(date, :zero)  #=> true

  """
  @spec convert(dtz) :: timestamp
  @spec convert(dtz, :timestamp)   :: timestamp
  @spec convert(dtz, :sec | :day) :: integer
  def convert(date, type \\ :timestamp)

  def convert(date, :timestamp) do
    to_timestamp(date)
  end

  def convert(date, :sec) do
    to_sec(date)
  end

  def convert(date, :day) do
    to_days(date)
  end

  @doc """
  Convert the date to timestamp value consumable by the Time module.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      to_timestamp(epoch()) #=> {0,0,0}

  """
  @spec to_timestamp(dtz) :: timestamp
  @spec to_timestamp(dtz, :epoch | :zero) :: timestamp
  def to_timestamp(date, reference \\ :epoch)

  def to_timestamp(date, :epoch) do
    sec = to_sec(date)
    { div(sec, _million), rem(sec, _million), 0 }
  end

  def to_timestamp(date, :zero) do
    sec = to_sec(date, :zero)
    { div(sec, _million), rem(sec, _million), 0 }
  end

  # FIXME: support reference date

  @doc """
  Convert the date to an integer number of seconds since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

      date = from({{1999,1,2}, {12,13,14}})
      to_sec(date)  #=> 915279194

  """
  @spec to_sec(dtz) :: integer
  @spec to_sec(dtz, :epoch | :zero) :: integer
  def to_sec(date, reference \\ :epoch)

  def to_sec(date, :epoch) do
    to_sec(date, :zero) - epoch(:sec)
  end

  def to_sec(date, :zero) do
    { date, time, _ } = Date.Conversions.to_gregorian(date)
    :calendar.datetime_to_gregorian_seconds({date,time})
  end

  # FIXME: support reference date

  @doc """
  Convert the date to an integer number of days since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitray reference date.

  ## Examples

      to_days(now())  #=> 15780

  """
  @spec to_days(dtz) :: integer
  @spec to_days(dtz, :epoch | :zero) :: integer
  def to_days(date, reference \\ :epoch)

  def to_days(date, :epoch) do
    to_days(date, :zero) - epoch(:day)
  end

  def to_days(date, :zero) do
    { date, _, _ } = Date.Conversions.to_gregorian(date)
    :calendar.date_to_gregorian_days(date)
  end

  # FIXME: support reference date

  ### Retrieving information about a date ###

  @doc """
  Return weekday number (as defined by ISO 8601) of the specified date.

  ## Examples

      weekday(epoch())  #=> 4 (i.e. Thursday)

  """
  @spec weekday(dtz | datetime) :: weekday

  def weekday({date={_year,_month,_day}, _time}) do
    :calendar.day_of_the_week(date)
  end

  def weekday(date) do
    weekday(local(date))
  end

  @doc """
  Returns the ordinal day number of the date.
  """
  @spec daynum(dtz) :: daynum

  def daynum(date) do
    # rawset for more efficiency
    start_of_year = rawset(date, [month: 1, day: 1])
    1 + diff(start_of_year, date, :day)
  end

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that date falls
  on.

  ## Examples

      iso_weeknum(epoch())  #=> {1970,1}

  """
  @spec iso_weeknum(dtz | datetime) :: {year, weeknum}

  def iso_weeknum({date={_year,_month,_day}, _time}) do
    :calendar.iso_week_number(date)
  end

  def iso_weeknum(date) do
    iso_weeknum(local(date))
  end

  @doc """
  Return the week number from the year's start.

  ## Examples

      weeknum(epoch())  #=> {1970,1}

  """
  @spec weeknum(dtz | datetime) :: {year, weeknum}

  def weeknum({date={_year,_month,_day}, _time}) do
    # FIXME
    :calendar.iso_week_number(date)
  end

  def weeknum(date) do
    weeknum(local(date))
  end

  @doc """
  Return a 3-tuple {year, week number, weekday} for the given date.

  ## Examples

      iso_triplet(epoch())  #=> {1970, 1, 4}

  """
  @spec iso_triplet(dtz) :: {year, weeknum, weekday}

  def iso_triplet(datetime={{_year,_month,_day}, _time}) do
    { iso_year, iso_week } = weeknum(datetime)
    { iso_year, iso_week, weekday(datetime) }
  end

  def iso_triplet(date) do
    iso_triplet(local(date))
  end

  @doc """
  Return the number of days in the month which the date falls on.

  ## Examples

      days_in_month(epoch())  #=> 31

  """
  @spec days_in_month(dtz) :: num_of_days

  def days_in_month(date) do
    {{year,month,_}, _} = local(date)
    days_in_month(year, month)
  end

  @doc """
  Return number of days in the given month.

  ## Examples

      days_in_month(2012, 2)  #=> 29
      days_in_month(2013, 2)  #=> 28

  """
  @spec days_in_month(year, month) :: num_of_days

  def days_in_month(year, month) do
    :calendar.last_day_of_the_month(year, month)
  end

  @doc """
  Return a boolean indicating whether the given year is a leap year. You may
  pase a date or a year number.

  ## Examples

      is_leap(epoch())  #=> false
      is_leap(2012)     #=> true

  """
  @spec is_leap(dtz | year) :: boolean

  def is_leap(year) when is_integer(year) do
    :calendar.is_leap_year(year)
  end

  def is_leap(date) do
    {{year,_,_}, _} = local(date)
    is_leap(year)
  end

  ### Validating and modifying dates ###

  @doc """
  Return a boolean indicating whether the given date is valid.

  ## Examples

      is_valid(from({{1,1,1}, {1,1,1}}))        #=> true
      is_valid(from({12,13,14}))                #=> false
      is_valid(from({{12,12,12}, {-1,59,59}}))  #=> false

  """
  @spec is_valid(dtz) :: boolean

  def is_valid(date) do
    { date, time, tz } = Date.Conversions.to_gregorian(date)
    :calendar.valid_date(date) and is_valid_time(time) and is_valid_tz(tz)
  end

  defp is_valid_time({hour,min,sec}) do
    hour >= 0 and hour < 24 and min >= 0 and min < 60 and sec >= 0 and sec < 60
  end

  defp is_valid_tz({_offset, _name}) do
    # FIXME: implement time zone validation
    true
  end

  @doc """
  Produce a valid date from a possibly invalid one.

  All date's components will be clamped to the minimum or maximum valid value.

  ## Examples

      date = { {1,13,44}, {-8,60,61} }
      local(normalize(from(date)))  #=> { {1,12,31}, {0,59,59} }

  """
  @spec normalize(dtz) :: dtz

  def normalize(date) do
    { date, time, tz } = Date.Conversions.to_gregorian(date)
    make_date(norm_date(date), norm_time(time), norm_tz(tz))
  end

  defp norm_date({year,month,day}) do
    year  = norm_year(year)
    month = norm_month(month)
    day   = norm_day(year, month, day)
    {year, month, day}
  end

  defp norm_year(year) when year < 0 do
    0
  end

  defp norm_year(year) do
    year
  end

  defp norm_month(month) do
    cond do
      month < 1   -> 1
      month > 12  -> 12
      true        -> month
    end
  end

  defp norm_day(year, month, day) do
    ndays = days_in_month(year, month)
    cond do
      day < 1     -> 1
      day > ndays -> ndays
      true        -> day
    end
  end

  defp norm_time({hour,min,sec}) do
    hour  = norm_hour(hour)
    min   = norm_min(min)
    sec   = norm_sec(sec)
    {hour, min, sec}
  end

  defp norm_hour(hour) do
    cond do
      hour < 0    -> 0
      hour > 23   -> 23
      true        -> hour
    end
  end

  defp norm_min(min) do
    cond do
      min < 0    -> 0
      min > 59   -> 59
      true       -> min
    end
  end

  defp norm_sec(sec) do
    cond do
      sec < 0    -> 0
      sec > 59   -> 59
      true       -> sec
    end
  end

  defp norm_tz(tz) do
    # FIXME: add time zone normalization
    tz
  end

  @doc """
  Return a new date with the specified fields replaced by new values.

  Values that are not in range are capped from both sides. The result is always
  a valid date. If you don't want to enforce date validity, use rawset/2 instead.

  ## Examples

      set(now(), date: {1,1,1})       #=> { {{1,1,1}, {12,52,47}}, {2.0,"EET"} }
      set(now(), hour: 0)             #=> { {{2013,3,17}, {0,53,39}}, {2.0,"EET"} }
      set(now(), tz: timezone(:utc))  #=> { {{2013,3,17}, {12,54,23}}, {0.0,"UTC"} }

      set(now(), [date: {1,1,1}, hour: 13, second: 61, tz: timezone(:utc)])
      #=> { {{1,1,1}, {13,45,61}}, {0.0,"UTC"} }

  """
  @spec set(dtz, [datetime: datetime]) :: dtz

  @spec set(dtz, [date: date]) :: dtz
  @spec set(dtz, [year: year]) :: dtz
  @spec set(dtz, [month: month]) :: dtz
  @spec set(dtz, [day: day]) :: dtz

  @spec set(dtz, [time: time]) :: dtz
  @spec set(dtz, [hour: hour]) :: dtz
  @spec set(dtz, [minute: minute]) :: dtz
  @spec set(dtz, [second: second]) :: dtz

  @spec set(dtz, [tz: tz]) :: dtz

  import Date.Helper, only: [def_set: 1, def_rawset: 1]
  def_set(:datetime)
  def_set(:date)
  def_set(:year)
  def_set(:month)
  def_set(:day)
  def_set(:time)
  def_set(:hour)
  def_set(:min)
  def_set(:sec)
  def_set(:tz)

  def set(date, values) when is_list(values) do
    greg_date = Date.Conversions.to_gregorian(date)
    { date, time, tz } = Enum.reduce values, greg_date, fn({atom, value}, date) ->
      set_priv(date, atom, value)
    end
    make_date(date, time, tz)
  end

  defp set_priv({_, _, tz}, :datetime, value) do
    { date, time } = value
    { norm_date(date), norm_time(time), tz }
  end

  defp set_priv({_, time, tz}, :date, value) do
    { norm_date(value), time, tz }
  end

  defp set_priv({{_,month,day}, time, tz}, :year, value) do
    { {norm_year(value),month,day}, time, tz }
  end

  defp set_priv({{year,_,day}, time, tz}, :month, value) do
    { {year,norm_month(value),day}, time, tz }
  end

  defp set_priv({{year,month,_}, time, tz}, :day, value) do
    { {year,month,norm_day(year,month,value)}, time, tz }
  end

  defp set_priv({date, _, tz}, :time, value) do
    { date, norm_time(value), tz }
  end

  defp set_priv({date, {_,min,sec}, tz}, :hour, value) do
    { date, {norm_hour(value),min,sec}, tz }
  end

  defp set_priv({date, {hour,_,sec}, tz}, :min, value) do
    { date, {hour,norm_min(value),sec}, tz }
  end

  defp set_priv({date, {hour,min,_}, tz}, :sec, value) do
    { date, {hour,min,norm_sec(value)}, tz }
  end

  defp set_priv({date, time, _}, :tz, value) do
    { date, time, norm_tz(value) }
  end

  @doc """
  Return a new date with the specified fields replaced by new values.

  The values are not checked, so the result is not guaranteed to be a valid
  date. If you want to enforce date validity, use set/2 instead.

  ## Examples

      rawset(now(), :date, {1,1,1})       #=> { {{1,1,1}, {12,52,47}}, {2.0,"EET"} }
      rawset(now(), :hour, 0)             #=> { {{2013,3,17}, {0,53,39}}, {2.0,"EET"} }
      rawset(now(), :tz, timezone(:utc))  #=> { {{2013,3,17}, {12,54,23}}, {0.0,"UTC"} }

  """
  @spec rawset(dtz, [datetime: datetime]) :: dtz

  @spec rawset(dtz, [date: date]) :: dtz
  @spec rawset(dtz, [year: year]) :: dtz
  @spec rawset(dtz, [month: month]) :: dtz
  @spec rawset(dtz, [day: day]) :: dtz

  @spec rawset(dtz, [time: time]) :: dtz
  @spec rawset(dtz, [hour: hour]) :: dtz
  @spec rawset(dtz, [minute: minute]) :: dtz
  @spec rawset(dtz, [second: second]) :: dtz

  @spec rawset(dtz, [tz: tz]) :: dtz

  def_rawset(:datetime)
  def_rawset(:date)
  def_rawset(:year)
  def_rawset(:month)
  def_rawset(:day)
  def_rawset(:time)
  def_rawset(:hour)
  def_rawset(:min)
  def_rawset(:sec)
  def_rawset(:tz)

  def rawset(date, values) when is_list(values) do
    greg_date = Date.Conversions.to_gregorian(date)
    { date, time, tz } = Enum.reduce values, greg_date, fn({atom, value}, date) ->
      rawset_priv(date, atom, value)
    end
    make_date(date, time, tz)
  end

  defp rawset_priv({_, _, tz}, :datetime, value) do
    { date, time } = value
    { date, time, tz }
  end

  defp rawset_priv({_, time, tz}, :date, value) do
    { value, time, tz }
  end

  defp rawset_priv({{_,month,day}, time, tz}, :year, value) do
    { {value,month,day}, time, tz }
  end

  defp rawset_priv({{year,_,day}, time, tz}, :month, value) do
    { {year,value,day}, time, tz }
  end

  defp rawset_priv({{year,month,_}, time, tz}, :day, value) do
    { {year,month,value}, time, tz }
  end

  defp rawset_priv({date, _, tz}, :time, value) do
    { date, value, tz }
  end

  defp rawset_priv({date, {_,min,sec}, tz}, :hour, value) do
    { date, {value,min,sec}, tz }
  end

  defp rawset_priv({date, {hour,_,sec}, tz}, :min, value) do
    { date, {hour,value,sec}, tz }
  end

  defp rawset_priv({date, {hour,min,_}, tz}, :sec, value) do
    { date, {hour,min,value}, tz }
  end

  defp rawset_priv({date, time, _}, :tz, value) do
    { date, time, value }
  end

  ### Comparing dates ###

  @doc """
  Compare two dates returning one of the following values:

   * `-1` -- date2 comes before date1 in time

   * `0`  -- both arguments represent the same date (their representation is not
            necessarily the same, e.g. they may have different times defined in
            different time zones; but after coalescing them to the same time zone,
            they would be equal down to separate components)

   * `1`  -- date2 comes after date1 in time (natural order)

  """
  @spec compare(dtz, dtz | :epoch | :zero) :: -1 | 0 | 1

  def compare(date, :epoch) do
    compare(date, epoch)
  end

  def compare(date, :zero) do
    compare(date, zero)
  end

  def compare(_, :distant_past), do: -1
  def compare(_, :distant_future), do: 1

  def compare(date, date), do: 0

  def compare(date1, date2) do
    diffsec = to_sec(date2) - to_sec(date1)
    cond do
      diffsec < 0  -> -1
      diffsec == 0 -> 0
      diffsec > 0  -> 1
    end
  end

  @doc """
  Calculate time interval between two dates. If the second date comes after the
  first one in time, return value will be positive; and negative otherwise.
  """
  @spec diff(dtz, dtz, :timestamp) :: timestamp
  @spec diff(dtz, dtz, :sec | :day | :week | :month | :year) :: integer

  def diff(date1, date2, :timestamp) do
    Time.from_sec(diff(date1, date2, :sec))
  end

  def diff(date1, date2, :sec) do
    to_sec(date2, :zero) - to_sec(date1, :zero)
  end

  def diff(date1, date2, :day) do
    to_days(date2, :zero) - to_days(date1, :zero)
  end

  def diff(date1, date2, :week) do
    # TODO: think of a more accurate method
    div(diff(date1, date2, :day), 7)
  end

  def diff(date1, date2, :month) do
    # Only take years and months into account
    {{y1, m1, _}, _} = universal(date1)
    {{y2, m2, _}, _} = universal(date2)
    (y2 - y1) * 12 + m2 - m1
  end

  def diff(date1, date2, :year) do
    {{year1,_,_}, _} = local(date1)
    {{year2,_,_}, _} = local(date2)
    year2 - year1
  end

  ### Date arithmetic ###

  @doc """
  Same as shift(date, timestamp, :timestamp).
  """
  @spec add(dtz, timestamp) :: dtz

  def add(date, {mega, sec, _}) do
    shift(date, [sec: mega * _million + sec])
  end

  @doc """
  Same as shift(date, Time.invert(timestamp), :timestamp).
  """
  @spec sub(dtz, timestamp) :: dtz

  def sub(date, {mega, sec, _}) do
    shift(date, [sec: -mega * _million - sec])
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

      local(shift(date, sec: 24*3600*365))
      #=> {{2014,3,5}, {23,23,23}}

      local(shift(date, sec: -24*3600*(365*2 + 1)))  # +1 day for leap year 2012
      #=> {{2011,3,5}, {23,23,23}}

      local(shift(date, [sec: 13, day: -1, week: 2]))
      #=> {{2013,3,18}, {23,23,36}}

  """
  @spec shift(dtz, list) :: dtz
  #@spec shift(dtz, integer, :timestamp | :sec | :min | :hour | :day | :week | :month | :year) :: dtz

  def shift(date, [{_, 0}]) do
    date
  end

  def shift(date, [timestamp: {0,0,0}]) do
    date
  end

  def shift(date, [timestamp: timestamp]) do
    add(date, timestamp)
  end

  def shift(date, [{type, value}]) when type in [:sec, :min, :hour] do
    sec = to_sec(date)
    sec = sec + case type do
      :sec   -> value
      :min   -> value * 60
      :hour  -> value * 3600
    end
    { _, _, tz } = Date.Conversions.to_gregorian(date)
    rawset(from(sec, :sec), [tz: tz])  # rawset for performance
  end

  def shift(date, [day: value]) do
    days = to_days(date)
    days = days + value
    { _, time, tz } = Date.Conversions.to_gregorian(date)
    set(from(days, :day), [time: time, tz: tz])  # rawset for performance
  end

  def shift(date, [week: value]) do
    shift(date, [day: value * 7])
  end

  def shift(date, [month: value]) do
    { {year,month,day}, time, tz } = Date.Conversions.to_gregorian(date)

    month = month + value

    # Calculate a valid year value
    year = cond do
      month == 0 -> year - 1
      month < 0  -> year + div(month, 12) - 1
      month > 12 -> year + div(month - 1, 12)
      true       -> year
    end

    make_date(validate({year, round_month(month), day}), time, tz)
  end

  def shift(date, [year: value]) do
    { {year,month,day}, time, tz } = Date.Conversions.to_gregorian(date)
    make_date(validate({year + value, month, day}), time, tz)
  end

  defrecordp :shift_rec, sec: 0, day: 0, year: 0

  # This clause will match lists with at least 2 values
  def shift(date, spec) when is_list(spec) do
    shift_rec(sec: sec, day: day, year: year)
      = Enum.reduce spec, shift_rec(), fn
        ({:timestamp, {mega, tsec, _}}, shift_rec(sec: sec)=rec) ->
          shift_rec(rec, [sec: sec + mega * _million + tsec])

        ({:sec, tsec}, shift_rec(sec: sec)=rec) ->
          shift_rec(rec, [sec: sec + tsec])

        ({:min, min}, shift_rec(sec: sec)=rec) ->
          shift_rec(rec, [sec: sec + min * 60])

        ({:hour, hrs}, shift_rec(sec: sec)=rec) ->
          shift_rec(rec, [sec: sec + hrs * 3600])

        ({:day, days}, shift_rec(day: day)=rec) ->
          shift_rec(rec, [day: day + days])

        ({:week, weeks}, shift_rec(day: day)=rec) ->
          shift_rec(rec, [day: day + weeks * 7])

        ({:year, years}, shift_rec(year: year)=rec) ->
          shift_rec(rec, [year: year + years])

        ({:month, _}, _) ->
          raise ArgumentError, message: ":month not supported in bulk shifts"
      end

    # The order in which we apply sec and days is not important.
    # The year shift must always go last though.
    date |> shift([sec: sec]) |> shift([day: day]) |> shift([year: year])
  end

  ### Private helper function ###

  defp validate({year, month, day})

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
      0 -> 12
      other -> other
    end
  end

  defp _million, do: 1000000
end
