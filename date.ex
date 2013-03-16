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

  defmacrop make_tz(offset, name) do
    quote do
      { unquote(offset), unquote(name) }
    end
  end

  defmacrop local_tz do
    # TODO: change implmentation for cross-platform support
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

  @type time :: { hour, minute, second }
  @type hour :: 0..23
  @type minute :: 0..59
  @type second :: 0..59

  ### Constructing time zone objects ###

  @doc """
  Get a time zone object for the specified offset or name.

  When offset or name is invalid, an exception is thrown.

  ## Examples

    timezone(2)      #=> { 2.0, "EET" }
    timezone("EET")  #=> { 2.0, "EET" }
    timezone(:utc)   #=> { 0.0, "UTC" }
    timezone() or timezone(:local)  #=> <local time zone>

  """
  @spec timezone(none | :local | :utc | number | binary) :: tz
  def timezone(spec // :local)

  def timezone(:local) do
    local_tz()
  end

  def timezone(:utc) do
    make_tz(0.0, "UTC")
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

  ### Examples

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

  ### Examples

    now(:sec)   #=> 1363439013
    now(:days)  #=> 15780

  """
  @spec now(:sec | :days) :: integer
  def now(:sec) do
    to_sec(now)
  end

  def now(:days) do
    to_days(now)
  end

  @doc """
  Get current local date.
  """
  @spec local() :: datetime
  def local do
    #local(now)
    :calendar.local_time()
  end

  @doc """
  Convert date to local date.
  """
  @spec local(dtz) :: datetime
  def local({ datetime, {offset,_} }) do
    sec = :calendar.datetime_to_gregorian_seconds(datetime) + offset * 3600
    :calendar.gregorian_seconds_to_datetime(trunc(sec))
  end

  @doc """
  Convert date to local date using the provided time zone.
  """
  @spec local(dtz, tz) :: datetime
  def local({datetime,_}, tz) do
    # simply ignore the date's timezone and use tz instead
    local(make_date(datetime, tz))
  end

  @doc """
  Get current UTC date.
  """
  @spec universal() :: datetime
  def universal do
    #universal(now)
    :calendar.universal_time()
  end

  @doc """
  Convert date to UTC date.
  """
  @spec universal(dtz) :: datetime
  def universal({datetime, _}) do
    datetime
  end

  @doc """
  The first day of year zero (calendar's module default reference date).
  """
  def zero do
    { {{0,1,1}, {0,0,0}}, timezone(:utc) }
  end

  @doc """
  Return a date representing midnight the first day of year zero.
  """
  def distant_past do
    # TODO: think of a use cases
    { {{0,1,1}, {0,0,0}}, timezone(:utc) }
  end

  @doc """
  Return a date representing a remote moment in in the future. Can be used as a
  timeout value to effectively make the timeout infinite.
  """
  def distant_future do
    # TODO: evaluate whether it's distant enough
    { {{9999,12,31}, {23,59,59}}, timezone(:utc) }
  end

  @doc """
  The date of UNIX epoch used as default reference date by this module and also
  by Time module.
  """
  def epoch do
    { {{1970,1,1}, {0,0,0}}, timezone(:utc) }
  end

  @doc """
  Time interval since year 0 to UNIX epoch expressed in the specified units.
  """
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

  def from(value, type // :timestamp, reference // :epoch)

  def from({mega, sec, _}, :timestamp, :epoch) do
    # microseconds are ingnored
    from(mega * _million + sec, :sec)
  end

  def from({mega, sec, _}, :timestamp, 0) do
    from(mega * _million + sec, :sec, 0)
  end

  def from(sec, :sec, :epoch) do
    { :calendar.gregorian_seconds_to_datetime(sec + epoch(:sec)), timezone(:utc) }
  end

  def from(sec, :sec, 0) do
    { :calendar.gregorian_seconds_to_datetime(sec), timezone(:utc) }
  end

  def from(days, :days, :epoch) do
    { {:calendar.gregorian_days_to_date(days + epoch(:days)),{0,0,0}}, timezone(:utc) }
  end

  def from(days, :days, 0) do
    { {:calendar.gregorian_days_to_date(days),{0,0,0}}, timezone(:utc) }
  end

  ### Converting dates ###

  def to_timestamp(dtz) do
    sec = to_sec(dtz)
    { div(sec, _million), rem(sec, _million), 0 }
  end

  def to_sec(date, reference // :epoch)

  def to_sec(date, :epoch) do
    to_sec(date, 0) - epoch(:sec)
  end

  def to_sec(dtz={{{_,_,_},{_,_,_}}, {_,_}}, 0) do
    datetime = local(dtz)
    to_sec(datetime, 0)
  end

  def to_sec(datetime={{_,_,_},{_,_,_}}, 0) do
    :calendar.datetime_to_gregorian_seconds(datetime)
  end

  def to_sec(dtz1, dtz2) do
    # deprecate in favor of diff
    to_sec(dtz1, 0) - to_sec(dtz2, 0)
  end


  def to_days(date, reference // :epoch)

  def to_days({date, _}, ref) do
    to_days(date, ref)
  end

  def to_days(date, 0) do
    :calendar.date_to_gregorian_days(date)
  end

  def to_days(date, :epoch) do
    to_days(date, 0) - epoch(:days)
  end

  def to_days(date1, date2) do
    to_days(date1, 0) - to_days(date2, 0)
  end

  def convert(date, type // :timestamp)

  def convert(date, :sec) do
    to_sec(date)
  end

  def convert(date, :days) do
    to_days(date)
  end

  def convert(date, :timestamp) do
    to_timestamp(date)
  end

  ### Retrieving information about a date ###

  @doc """
  1 - Monday, ..., 7 - Sunday
  """
  def weekday(date={_year,_month,_day}) do
    :calendar.day_of_the_week(date)
  end

  def weekday({date, _}) do
    weekday(date)
  end

  def week_number(date={_year,_month,_day}) do
    :calendar.iso_week_number(date)
  end

  def week_number({date, _}) do
    week_number(date)
  end

  def is_leap({year,_,_}) do
    is_leap(year)
  end

  def is_leap({{year,_,_}, _}) do
    is_leap(year)
  end

  def is_leap(year) do
    :calendar.is_leap_year(year)
  end

  def iso_triplet(date={_year,_month,_day}) do
    { iso_year, iso_week } = week_number(date)
    { iso_year, iso_week, weekday(date) }
  end

  def iso_triplet({date, _}) do
    iso_triplet(date)
  end

  def days_in_month(year, month) do
    :calendar.last_day_of_the_month(year, month)
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

  def replace(dtz, value, type)

  def replace({datetime,_}, value, :tz) do
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

  Examples:

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
