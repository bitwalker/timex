# Consider adding the following functions
# is_future = diff(date, :now) > 0
# is_past = diff(date, :now) < 0
# next(date, type) = shift(date, 1, type)
# prev(date, type) = shift(date, -1, type)
# beginning_of_month
# end_of_month

defmodule Date do
  @moduledoc """
  Module for working with dates.

  Functions that produce time intervals use UNIX epoch (or simly Epoch) as
  default reference date. Epoch is defined as midnight of January 1, 1970.

  Time intervals in this module don't account for leap seconds.

  Supported tasks:

    * get current date in the desired time zone
    * convert dates between time zones and time units
    * introspect dates to find out weekday, week number, number of days in
      a given month, etc.
    * parse dates from string
    * format dates to string
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
      { unquote(datetime), unquote(tz) }
    end
  end

  defmacrop make_date(date, time, tz) do
    quote do
      { {unquote(date), unquote(time)}, unquote(tz) }
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

  When offset or name is invalid, an exception is thrown.

  ## Examples

    timezone()       #=> <local time zone>
    timezone(:utc)   #=> { 0.0, "UTC" }
    timezone(2)      #=> { 2.0, "EET" }
    timezone("EET")  #=> { 2.0, "EET" }

  """
  @spec timezone() :: tz
  @spec timezone(:local | :utc | number | binary) :: tz
  def timezone(spec // :local)

  def timezone(:local) do
    # TODO: change implementation for cross-platform support
    datestr = System.cmd('date "+%z %Z"')
    { :ok, [offs|[name]], _ } = :io_lib.fread('~d ~s', datestr)

    hours_offs = div(offs, 100)
    min_offs = offs - hours_offs * 100
    offset = hours_offs + min_offs / 60

    #datetime = :calendar.universal_time()
    #local_time = :calendar.universal_time_to_local_time(datetime)
    #hour_offset = (:calendar.datetime_to_gregorian_seconds(local_time) - :calendar.datetime_to_gregorian_seconds(datetime)) / 3600
    #timezone(hour_offset, "TimeZoneName")

    make_tz(offset, to_binary(name))
  end

  def timezone(:utc) do
    make_tz(:utc)
  end

  def timezone(offset) when is_number(offset) do
    # TODO: fetch time zone name
    # An exception should be thrown for invalid offsets
    make_tz(offset, "TimeZoneName")
  end

  def timezone(name) when is_binary(name) do
    # TODO: determine the offset
    # An exception should be thrown for invalid names
    make_tz(2, name)
  end

  @doc """
  Return a time zone object for the given offset-name combination.

  An exception is thrown in the case of invalid or non-matching arguments.

  ## Examples

    timezone(2, "EET")  #=> { 2.0, "EET" }
    timezone(2, "PST")  #=> <exception>

  """
  @spec timezone(number, binary) :: tz
  def timezone(offset, name) when is_number(offset) and is_binary(name) do
    make_tz(offset, name)
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
    now(:days)  #=> 15780

  """
  @spec now(:sec | :days) :: integer
  def now(:sec) do
    to_sec(now())
  end

  def now(:days) do
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
  Convert date to local date.

  See also `universal/1`.

  ## Examples

    local(now())  #=> {{2013,3,16}, {14,29,22}} (same as local())

  """
  @spec local(dtz) :: datetime
  def local({ datetime, {offset,_} }) do
    sec = :calendar.datetime_to_gregorian_seconds(datetime) + offset * 3600
    :calendar.gregorian_seconds_to_datetime(trunc(sec))
  end

  @doc """
  Convert date to local date using the provided time zone.

  ## Examples

    local(now(), timezone(:utc))  #=> {{2013,3,16}, {12,29,22}}

  """
  @spec local(dtz, tz) :: datetime
  def local({datetime,_}, tz) do
    local(make_date(datetime, tz))
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
  def universal({datetime, _}) do
    datetime
  end

  @doc """
  The first day of year zero (calendar's module default reference date).

  See also `epoch/0`.

  ## Examples

    to_sec(zero(), 0)  #=> 0

  """
  @spec zero() :: dtz
  def zero do
    make_date({0,1,1}, {0,0,0}, make_tz(:utc))
  end

  @doc """
  Return the date representing a very distant moment in the past.

  See also `distant_future/0`.
  """
  @spec distant_past() :: dtz
  def distant_past do
    # TODO: think of use cases
    make_date({0,1,1}, {0,0,0}, make_tz(:utc))
  end

  @doc """
  Return the date representing a remote moment in the future. Can be used as
  a timeout value to effectively make the timeout infinite.

  See also `distant_past/0`.
  """
  @spec distant_future() :: dtz
  def distant_future do
    # TODO: evaluate whether it's distant enough
    make_date({9999,12,31}, {23,59,59}, make_tz(:utc))
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
    epoch(:days)  #=> 719528

  """
  @spec epoch(:timestamp)   :: timestamp
  @spec epoch(:sec | :days) :: integer
  def epoch(:timestamp) do
    to_timestamp(epoch)
  end

  def epoch(:sec) do
    to_sec(epoch, 0)
  end

  def epoch(:days) do
    to_days(epoch, 0)
  end

  ### Constructing the date from an existing value ###

  @doc """
  Construct a date from Erlang's date or datetime value.

  You may specify the date's time zone as the second argument. If the argument
  is omitted, UTC time zone is assumed.

  ## Examples

    from(:erlang.universaltime)      #=> { {{2013,3,16}, {12,22,20}}, {0.0,"UTC"} }

    from(:erlang.localtime)          #=> { {{2013,3,16}, {14,18,41}}, {0.0,"UTC"} }
    from(:erlang.localtime, :local)  #=> { {{2013,3,16}, {14,18,51}}, {2.0,"EET"} }

    tz = Date.timezone(-8, "PST")
    from({2013,3,16}, tz)            #=> { {{2013,3,16}, {0,0,0}}, {-8,"PST"} }

  """
  @spec from(date | datetime) :: dtz
  @spec from(date | datetime, :utc | :local | tz) :: dtz

  def from(date={_,_,_}) do
    from({date, {0,0,0}}, :utc)
  end

  def from(datetime={ {_,_,_},{_,_,_} }) do
    from(datetime, :utc)
  end

  def from(date={_,_,_}, :utc) do
    from({date, {0,0,0}}, :utc)
  end

  def from(datetime={ {_,_,_},{_,_,_} }, :utc) do
    make_date(datetime, make_tz(:utc))
  end

  def from(date={_,_,_}, :local) do
    from({date, {0,0,0}}, :local)
  end

  def from(datetime={ {_,_,_},{_,_,_} }, :local) do
    make_date(datetime, timezone())
  end

  def from(date={_,_,_}, tz={_,_}) do
    from({date, {0,0,0}}, tz)
  end

  def from(datetime={ {_,_,_},{_,_,_} }, tz={_,_}) do
    make_date(datetime, tz)
  end

  @doc """
  Construct a date from a time interval since Epoch or year 0.

  UTC time zone is assumed. This assumption can be modified by setting desired
  time zone using replace/3 after the date is constructed.

  ## Examples

    from(13, :sec)      #=> { {{1970,1,1}, {0,0,13}}, {0.0,"UTC"} }
    from(13, :days, 0)  #=> { {{0,1,14}, {0,0,0}}, {0.0,"UTC"} }

    date = from(Time.now, :timestamp)
    replace(date, :tz, timezone())     #=> yields the same value as Date.now would

  """
  @spec from(timestamp, :timestamp) :: dtz
  @spec from(number, :sec | :days)  :: dtz
  @spec from(timestamp, :timestamp, :epoch | 0) :: dtz
  @spec from(number, :sec | :days, :epoch | 0)  :: dtz
  def from(value, type, reference // :epoch)

  def from({mega, sec, _}, :timestamp, :epoch) do
    from(mega * _million + sec, :sec)
  end

  def from({mega, sec, _}, :timestamp, 0) do
    from(mega * _million + sec, :sec, 0)
  end

  def from(sec, :sec, :epoch) do
    make_date(:calendar.gregorian_seconds_to_datetime(trunc(sec) + epoch(:sec)), make_tz(:utc))
  end

  def from(sec, :sec, 0) do
    make_date(:calendar.gregorian_seconds_to_datetime(trunc(sec)), make_tz(:utc))
  end

  def from(days, :days, :epoch) do
    make_date(:calendar.gregorian_days_to_date(trunc(days) + epoch(:days)), {0,0,0}, make_tz(:utc))
  end

  def from(days, :days, 0) do
    make_date(:calendar.gregorian_days_to_date(trunc(days)), {0,0,0}, make_tz(:utc))
  end

  ### Converting dates ###

  @doc """
  Multi-purpose conversion function. Converts a date to the specified time
  interval since Epoch. If you'd like to specify year 0 as a reference date,
  use one of the to_* functions.

  ## Examples

    date = now()
    convert(date, :sec) + epoch(:sec) == to_sec(date, 0)  #=> true

  """
  @spec convert(dtz) :: timestamp
  @spec convert(dtz, :timestamp)   :: timestamp
  @spec convert(dtz, :sec | :days) :: timestamp
  def convert(date, type // :timestamp)

  def convert(date, :timestamp) do
    to_timestamp(date)
  end

  def convert(date, :sec) do
    to_sec(date)
  end

  def convert(date, :days) do
    to_days(date)
  end

  @doc """
  Convert the date to timestamp value consumable by the Time module.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

    to_timestamp(epoch()) #=> {0,0,0}

  """
  @spec to_timestamp(dtz) :: timestamp
  @spec to_timestamp(dtz, :epoch | 0) :: timestamp
  def to_timestamp(date, reference // :epoch)

  def to_timestamp(date, :epoch) do
    sec = to_sec(date)
    { div(sec, _million), rem(sec, _million), 0 }
  end

  def to_timestamp(date, 0) do
    sec = to_sec(date, 0)
    { div(sec, _million), rem(sec, _million), 0 }
  end

  @doc """
  Convert the date to an integer number of seconds since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitrary reference date.

  ## Examples

    date = from({{1999,1,2}, {12,13,14}})
    to_sec(date)  #=> 915279194

  """
  @spec to_sec(dtz) :: integer
  @spec to_sec(dtz, :epoch | 0) :: integer
  def to_sec(date, reference // :epoch)

  def to_sec(date, :epoch) do
    to_sec(date, 0) - epoch(:sec)
  end

  def to_sec({datetime, _}, 0) do
    :calendar.datetime_to_gregorian_seconds(datetime)
  end

  @doc """
  Convert the date to an integer number of days since Epoch or year 0.

  See also `diff/2` if you want to specify an arbitray reference date.

  ## Examples

    to_days(now())  #=> 15780

  """
  @spec to_days(dtz) :: integer
  @spec to_days(dtz, :epoch | 0) :: integer
  def to_days(date, reference // :epoch)

  def to_days(date, :epoch) do
    to_days(date, 0) - epoch(:days)
  end

  def to_days({{date,_}, _}, 0) do
    :calendar.date_to_gregorian_days(date)
  end

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
  Return a pair {year, week number} (as defined by ISO 8601) that date falls
  on.

  ## Examples

    weeknum(epoch())  #=> {1970,1}

  """
  @spec weeknum(dtz | datetime) :: {year, weeknum}

  def weeknum({date={_year,_month,_day}, _time}) do
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

  def iso_triplet(date) do
    localtime = local(date)
    { iso_year, iso_week } = weeknum(localtime)
    { iso_year, iso_week, weekday(localtime) }
  end

  @doc """
  Return number of days is in the month which date falls on.

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

  def is_valid({date, _time}) do
    # TODO: validate the time as well
    :calendar.is_valid(date)
  end

  def validate({year, month, day}, direction // :past)

  def validate({year, month, day}, :past) do
    # Check if we got past the last day of the month
    max_day = days_in_month(year, month)
    if day > max_day do
      day = max_day
    end
    {year, month, day}
  end

  def validate({year, month, day}, :future) do
    # Check if we got past the last day of the month
    max_day = days_in_month(year, month)
    if day > max_day do
      day = max_day
    end
    {year, month, day}
  end

  def replace(date, type, value)

  def replace({datetime,_}, :tz, value) do
    {datetime, value}
  end

  ### Formatting dates ###

  @doc "Returns a binary with the ISO 8601 representation of the date"
  def iso_format({ {year, month, day}, {hour, min, sec} }) do
    list_to_binary(:io_lib.format("~4.10.0B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B",
                                  [year, month, day, hour, min, sec]))
  end

  @doc "Returns a binary with the RFC 1123 representation of the date"
  def rfc_format(date) do
    # :httpd_util.rfc1123_date() assumes that date is local
    list_to_binary(:httpd_util.rfc1123_date(date))
  end

  ### Comparing dates ###

  def cmp(date, 0) do
    cmp(date, zero)
  end

  def cmp(date, :epoch) do
    cmp(date, epoch)
  end

  def cmp(date1, date2) do
    diff = to_sec(date1) - to_sec(date2)
    cond do
      diff < 0  -> -1
      diff == 0 -> 0
      diff > 0  -> 1
    end
  end

  @doc """
  Same as cmp, but returns atoms :ascending, :equal, and :descending for cmp's
  -1, 0, and 1, respectively.
  """
  def compare(date, 0) do
    compare(date, zero)
  end

  def compare(date, :epoch) do
    compare(date, epoch)
  end

  def compare(date1, date2) do
    diff = to_sec(date1) - to_sec(date2)
    cond do
      diff < 0  -> :ascending
      diff == 0 -> :equal
      diff > 0  -> :descending
    end
  end

  def diff(date1, date2, type // :timestamp)

  def diff(date1, date2, :timestamp) do
    Time.from_sec(to_sec(date1, date2))
  end

  def diff(date1, date2, :sec) do
    to_sec(date1, date2)
  end

  def diff(date1, date2, :days) do
    to_days(date1, date2)
  end

  def diff(date1, date2, :weeks) do
    to_days(date1, date2)
  end

  def diff(date1, date2, :months) do
    to_days(date1, date2)
  end

  def diff(date1, date2, :years) do
    to_days(date1, date2)
  end

  ### Date arithmetic ###

  @doc """
  """
  def add(datetime, {mega, sec, _}) do
    # microseconds are simply ignored
    shift(datetime, mega * _million + sec, :sec)
  end

  def sub(datetime, {mega, sec, _}) do
    shift(datetime, -mega * _million - sec, :sec)
  end

  def shift(datetime, timestamp={_,_,_}) do
    add(datetime, timestamp)
  end

  def shift(datetime, spec) when is_list(spec) do
    Enum.reduce spec, datetime, fn({value, type}, result) ->
      shift(result, value, type)
    end
  end

  def shift(datetime, spec, :strict) when is_list(spec) do
    Enum.reduce normalize_shift(spec), datetime, fn({value, type}, result) ->
      shift(result, value, type)
    end
  end

  @doc """
  A single function for adjusting the date using various units: seconds,
  minutes, hours, days, weeks, months, years.

  The returned date is always valid. If after adding months or years the day
  exceeds maximum number of days in the resulting month, that month's last day
  is assumed.

  ## Examples

    datetime = {{2013,3,5},{23,23,23}}

    Date.shift(datetime, 24*3600*365, :sec)
    #=> {{2014,3,5},{23,23,23}}

    Date.shift(datetime, -24*3600*(365*2 + 1), :sec)   # +1 day for leap year 2012
    #=> {{2011,3,5},{23,23,23}}

  """
  def shift(date, 0, _) do
    date
  end

  def shift(date, value, type) when type in [:sec, :min, :hours] do
    # TODO: time zone adjustments
    sec = to_sec(date)
    sec = sec + case type do
      :sec   -> value
      :min   -> value * 60
      :hours -> value * 60 * 60
    end
    from(sec, :sec)
  end

  def shift({date, time}, value, :days) do
    # TODO: time zone adjustments
    days = to_days(date, 0)
    days = days + value
    { :calendar.gregorian_days_to_date(days), time }
  end

  def shift(date, value, :weeks) do
    shift(date, value * 7, :days)
  end

  def shift({ {year, month, day}, time }, value, :months) do
    month = month + value

    # Calculate a valid year value
    year = cond do
      month == 0 -> year - 1
      month < 0  -> year + div(month, 12) - 1
      month > 12 -> year + div(month - 1, 12)
      true       -> year
    end

    { validate({year, round_month(month), day}), time }
  end

  def shift({ {year, month, day}, time }, value, :years) do
    { validate({year + value, month, day}), time }
  end

  def normalize_shift(spec) when is_list(spec) do
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
