# Consider adding the following functions
# is_future = diff(date, :now) > 0
# is_past = diff(date, :now) < 0
# next(date, type) = shift(date, 1, type)
# prev(date, type) = shift(date, -1, type)
# beginning_of_month
# end_of_month

defmodule Date.Helper do
  @moduledoc false

  defmacro def_replace(arg) do
    quote do
      def replace(date, unquote(arg), value) do
        greg_date = Date.Conversions.to_gregorian(date)
        { date, time, tz } = replace_priv(greg_date, unquote(arg), value)
        make_date(date, time, tz)
      end
    end
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
  def timezone(spec // :local)

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

    make_tz(offset, to_binary(name))
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
      epoch(:days)  #=> 719528

  """
  @spec epoch(:timestamp)   :: timestamp
  @spec epoch(:sec | :days) :: integer
  def epoch(:timestamp) do
    to_timestamp(epoch)
  end

  def epoch(:sec) do
    to_sec(epoch, :zero)
  end

  def epoch(:days) do
    to_days(epoch, :zero)
  end

  @doc """
  Return the date representing a very distant moment in the past.

  See also `distant_future/0`.
  """
  @spec distant_past() :: dtz
  def distant_past do
    # TODO: think of use cases
    # cannot set the year to less than 0 here because Erlang functions don't
    # accept it
    # FIXME: consider returning an atom
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
    # FIXME: consider returning an atom
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
  time zone using replace/3 after the date is constructed.

  ## Examples

      from(13, :sec)          #=> { {{1970,1,1}, {0,0,13}}, {0.0,"UTC"} }
      from(13, :days, :zero)  #=> { {{0,1,14}, {0,0,0}}, {0.0,"UTC"} }

      date = from(Time.now, :timestamp)
      replace(date, :tz, timezone())     #=> yields the same value as Date.now would

  """
  @spec from(timestamp, :timestamp) :: dtz
  @spec from(number, :sec | :days)  :: dtz
  @spec from(timestamp, :timestamp, :epoch | :zero) :: dtz
  @spec from(number, :sec | :days, :epoch | :zero)  :: dtz
  def from(value, type, reference // :epoch)

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

  def from(days, :days, :epoch) do
    make_date(:calendar.gregorian_days_to_date(trunc(days) + epoch(:days)), {0,0,0}, make_tz(:utc))
  end

  def from(days, :days, :zero) do
    make_date(:calendar.gregorian_days_to_date(trunc(days)), {0,0,0}, make_tz(:utc))
  end

  # FIXME: support custom reference date

  ### Formatting dates ###

  @doc """
  Return date's string representation in the specified format.

  Format specifiers :iso* produce a string according to ISO 8601.

  ## Examples

      date = {{2013,3,5},{23,25,19}}
      eet = timezone(2, "EET")
      pst = Date.timezone(-8, "PST")

      format(from(date, eet), :iso)        #=> "2013-03-05 21:25:19Z"
      format(from(date, eet), :iso_local)  #=> "2013-03-05 23:25:19"
      format(from(date, pst), :iso_full)   #=> "2013-03-05 23:25:19-0800"

      format(from(date, pst), :rfc1123)    #=> "Wed, 05 Mar 2013 23:25:19 PST"
      format(from(date, pst), :rfc1123z)   #=> "Tue, 05 Mar 2013 23:25:19 -0800"

  """
  @spec format(dtz, :iso | :iso_local | :iso_full | :iso_week | :iso_weekday | :iso_ordinal | :rfc1123 | :rfc1123z | binary) :: binary

  def format(date, :iso) do
    format_iso(universal(date), "Z")
  end

  def format(date, :iso_local) do
     format_iso(local(date), "")
  end

  def format(date, :iso_full) do
    {{year,month,day}, {hour,min,sec}} = local(date)
    { _, _, {offset,_} } = Date.Conversions.to_gregorian(date)
    abs_offs = abs(offset)
    hour_offs = trunc(abs_offs)
    min_offs = round((abs_offs - hour_offs) * 60)
    fstr = if offset < 0 do
      "~4..0B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0B-~2..0B~2..0B"
    else
      "~4..0B-~2..0B-~2..0BT~2..0B:~2..0B:~2..0B+~2..0B~2..0B"
    end
    iolist_to_binary(:io_lib.format(fstr, [year, month, day, hour, min, sec, hour_offs, min_offs]))
  end

  def format(date, :iso_week) do
    {year, week} = weeknum(date)
    iolist_to_binary(:io_lib.format("~4.10.0B-W~2.10.0B", [year, week]))
  end

  def format(date, :iso_weekday) do
    {year, week, day} = iso_triplet(date)
    iolist_to_binary(:io_lib.format("~4.10.0B-W~2.10.0B-~B", [year, week, day]))
  end

  def format(date, :iso_ordinal) do
    {{year,_,_},_} = local(date)

    start_of_year = replace(date, [month: 1, day: 1])
    days = diff(start_of_year, date, :days)

    iolist_to_binary(:io_lib.format("~4.10.0B-~3.10.0B", [year, days]))
  end

  def format(date, :rfc1123) do
    localdate = local(date)
    { _, _, {_,tz_name} } = Date.Conversions.to_gregorian(date)

    format_rfc(localdate, {:name, tz_name})
  end

  def format(date, :rfc1123z) do
    localdate = local(date)
    { _, _, {tz_offset,_} } = Date.Conversions.to_gregorian(date)

    format_rfc(localdate, {:offset, tz_offset})
  end

  def format(_date, _fmt) do
    raise NotImplemented
  end

  defp format_iso({{year,month,day}, {hour,min,sec}}, tz_char) do
    iolist_to_binary(:io_lib.format("~4.10.0B-~2.10.0B-~2.10.0BT~2.10.0B:~2.10.0B:~2.10.0B~s",
                                  [year, month, day, hour, min, sec, tz_char]))
  end

  defp format_rfc(date, tz) do
    { {year,month,day}, {hour,min,sec} } = date
    day_name = weekday_name(weekday(date), :short)
    month_name = month_name(month, :short)
    fstr = case tz do
      { :name, tz_name } ->
        if tz_name == "UTC" do
          tz_name = "GMT"
        end
        "~s, ~2..0B ~s ~4..0B ~2..0B:~2..0B:~2..0B #{tz_name}"
      { :offset, tz_offset } ->
        sign = if tz_offset >= 0 do "+" else "-" end
        tz_offset = abs(tz_offset)
        tz_hrs = trunc(tz_offset)
        tz_min = trunc((tz_offset - tz_hrs) * 60)
        tz_spec = :io_lib.format("~s~2..0B~2..0B", [sign, tz_hrs, tz_min])
        "~s, ~2..0B ~s ~4..0B ~2..0B:~2..0B:~2..0B #{tz_spec}"
    end
    iolist_to_binary(:io_lib.format(fstr,
        [day_name, day, month_name, year, hour, min, sec]))
  end

  @doc """
  Convert a weekday number to its English name.

  ## Examples

      weekday_name(1, :short)  #=> "Mon"
      weekday_name(3, :full)   #=> "Wednesday"

  """
  @spec weekday_name(weekday, :short | :full) :: String.t

  def weekday_name(day, :short) when day in 1..7 do
    case day do
      1 -> "Mon"; 2 -> "Tue"; 3 -> "Wed"; 4 -> "Thu";
      5 -> "Fri"; 6 -> "Sat"; 7 -> "Sun"
    end
  end

  def weekday_name(day, :full) when day in 1..7 do
    case day do
      1 -> "Monday"; 2 -> "Tuesday"; 3 -> "Wednesday"; 4 -> "Thursday";
      5 -> "Friday"; 6 -> "Saturday"; 7 -> "Sunday"
    end
  end

  @doc """
  Convert a month number to its English name.

  ## Examples

      month_name(1, :short)  #=> "Jan"
      month_name(3, :full)   #=> "March"

  """
  @spec month_name(month, :short | :full) :: String.t

  def month_name(month, :short) when month in 1..12 do
    case month do
      1 -> "Jan";  2 -> "Feb";  3 -> "Mar";  4 -> "Apr";
      5 -> "May";  6 -> "Jun";  7 -> "Jul";  8 -> "Aug";
      9 -> "Sep"; 10 -> "Oct"; 11 -> "Nov"; 12 -> "Dec"
    end
  end

  def month_name(month, :full) when month in 1..12 do
    case month do
      1 -> "January";    2 -> "February";  3 -> "March";     4 -> "April";
      5 -> "May";        6 -> "June";      7 -> "July";      8 -> "August";
      9 -> "September"; 10 -> "October";  11 -> "November"; 12 -> "December"
    end
  end

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
  @spec convert(dtz, :sec | :days) :: integer
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
  @spec to_timestamp(dtz, :epoch | :zero) :: timestamp
  def to_timestamp(date, reference // :epoch)

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
  def to_sec(date, reference // :epoch)

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
  def to_days(date, reference // :epoch)

  def to_days(date, :epoch) do
    to_days(date, :zero) - epoch(:days)
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
    # FIXME: add time zone normalization

    { {year,month,day}, {hour,min,sec}, tz } = Date.Conversions.to_gregorian(date)

    month = cond do
      month < 1   -> 1
      month > 12  -> 12
      true        -> month
    end
    ndays = days_in_month(year, month)
    day = cond do
      day < 1     -> 1
      day > ndays -> ndays
      true        -> day
    end

    hour = cond do
      hour < 0    -> 0
      hour > 23   -> 23
      true        -> hour
    end
    min = cond do
      min < 0    -> 0
      min > 59   -> 59
      true       -> min
    end
    sec = cond do
      sec < 0    -> 0
      sec > 59   -> 59
      true       -> sec
    end

    make_date({year,month,day}, {hour,min,sec}, tz)
  end

  @doc """
  Return a new date with the specified fields replaced by new values.

  ## Examples

      replace(now(), :date, {1,1,1})       #=> { {{1,1,1}, {12,52,47}}, {2.0,"EET"} }
      replace(now(), :hour, 0)             #=> { {{2013,3,17}, {0,53,39}}, {2.0,"EET"} }
      replace(now(), :tz, timezone(:utc))  #=> { {{2013,3,17}, {12,54,23}}, {0.0,"UTC"} }

  """
  @spec replace(dtz, :datetime, datetime) :: dtz

  @spec replace(dtz, :date, date) :: dtz
  @spec replace(dtz, :year, year) :: dtz
  @spec replace(dtz, :month, month) :: dtz
  @spec replace(dtz, :day, day) :: dtz

  @spec replace(dtz, :time, time) :: dtz
  @spec replace(dtz, :hour, hour) :: dtz
  @spec replace(dtz, :minute, minute) :: dtz
  @spec replace(dtz, :second, second) :: dtz

  @spec replace(dtz, :tz, tz) :: dtz

  import Date.Helper, only: [def_replace: 1]
  def_replace(:datetime)
  def_replace(:date)
  def_replace(:year)
  def_replace(:month)
  def_replace(:day)
  def_replace(:time)
  def_replace(:hour)
  def_replace(:min)
  def_replace(:sec)
  def_replace(:tz)

  defp replace_priv({_, _, tz}, :datetime, value) do
    { date, time } = value
    { date, time, tz }
  end

  defp replace_priv({_, time, tz}, :date, value) do
    { value, time, tz }
  end

  defp replace_priv({{_,month,day}, time, tz}, :year, value) do
    { {value,month,day}, time, tz }
  end

  defp replace_priv({{year,_,day}, time, tz}, :month, value) do
    { {year,value,day}, time, tz }
  end

  defp replace_priv({{year,month,_}, time, tz}, :day, value) do
    { {year,month,value}, time, tz }
  end

  defp replace_priv({date, _, tz}, :time, value) do
    { date, value, tz }
  end

  defp replace_priv({date, {_,min,sec}, tz}, :hour, value) do
    { date, {value,min,sec}, tz }
  end

  defp replace_priv({date, {hour,_,sec}, tz}, :min, value) do
    { date, {hour,value,sec}, tz }
  end

  defp replace_priv({date, {hour,min,_}, tz}, :sec, value) do
    { date, {hour,min,value}, tz }
  end

  defp replace_priv({date, time, _}, :tz, value) do
    { date, time, value }
  end

  @doc """
  Return a new date with the specified fields replaced by new values.

  ## Examples

      replace(now(), [date: {1,1,1}, hour: 13, second: 61, tz: timezone(:utc)])
      #=> { {{1,1,1}, {13,45,61}}, {0.0,"UTC"} }

  """
  @spec replace(dtz, list) :: dtz

  def replace(date, values) when is_list(values) do
    greg_date = Date.Conversions.to_gregorian(date)
    { date, time, tz } = Enum.reduce values, greg_date, fn({atom, value}, date) ->
      replace_priv(date, atom, value)
    end
    make_date(date, time, tz)
  end

  ### Comparing dates ###

  @doc """
  Compare two dates returning one of the following values:

    -1  -- date2 comes before date1 in time

     0  -- both arguments represent the same date (their representation is not
           necessarily the same, e.g. they may have different times defined in
           different time zones; but after coalescing them to the same time zone,
           they would be equal down to separate components)

     1  -- date2 comes after date1 in time (natural order)

  """
  @spec compare(dtz, dtz | :epoch | :zero) :: -1 | 0 | 1

  def compare(date, :epoch) do
    compare(date, epoch)
  end

  def compare(date, :zero) do
    compare(date, zero)
  end

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
  @spec diff(dtz, dtz, :sec | :days | :weeks | :months | :years) :: integer

  def diff(date1, date2, :timestamp) do
    Time.from_sec(diff(date1, date2, :sec))
  end

  def diff(date1, date2, :sec) do
    to_sec(date2, :zero) - to_sec(date1, :zero)
  end

  def diff(date1, date2, :days) do
    to_days(date2, :zero) - to_days(date1, :zero)
  end

  def diff(date1, date2, :weeks) do
    # TODO: think of a more accurate method
    div(diff(date1, date2, :days), 7)
  end

  def diff(_date1, _date2, :months) do
    # FIXME: this is tricky. Need to calculate actual months rather than days * 30.
    raise NotImplemented
  end

  def diff(date1, date2, :years) do
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
    shift(date, mega * _million + sec, :sec)
  end

  @doc """
  Same as shift(date, Time.invert(timestamp), :timestamp).
  """
  @spec sub(dtz, timestamp) :: dtz

  def sub(date, {mega, sec, _}) do
    shift(date, -mega * _million - sec, :sec)
  end

  @doc """
  Shift the date by each time interval in the list in order. To achieve the
  most accurate result, use `shift(date, list, :strict)`.

  ## Examples

      date = from({{2013,3,5}, {23,23,23}})

      local(shift(date, [sec: 13, days: -1, weeks: 2]))
      #=> {{2013,3,18}, {23,23,36}}

  """
  @spec shift(dtz, list) :: dtz

  def shift(date, spec) when is_list(spec) do
    Enum.reduce spec, date, fn({type, value}, date) ->
      shift(date, value, type)
    end
  end

  @doc """
  Shift the date by each time interval in the list, sorting the list in
  advance. The intervals in the list are ordered in such a way as to minimise
  the skew of applying each shift.

  ## Examples

  """
  @spec shift_strict(dtz, list) :: dtz

  def shift_strict(date, spec) when is_list(spec) do
    Enum.reduce normalize_shift(spec), date, fn({type, value}, date) ->
      shift(date, value, type)
    end
  end

  @doc """
  A single function for adjusting the date using various units: timestamp,
  seconds, minutes, hours, days, weeks, months, years.

  When shifting by timestamps, microseconds are ignored.

  The returned date is always valid. If after adding months or years the day
  exceeds maximum number of days in the resulting month, that month's last day
  is used.

  ## Examples

      date = from({{2013,3,5}, {23,23,23}})

      local(shift(date, 24*3600*365, :sec))
      #=> {{2014,3,5}, {23,23,23}}

      local(shift(date, -24*3600*(365*2 + 1), :sec))  # +1 day for leap year 2012
      #=> {{2011,3,5}, {23,23,23}}

  """
  @spec shift(dtz, integer, :timestamp | :sec | :min | :hour | :days | :weeks | :months | :years) :: dtz

  def shift(date, 0, _) do
    date
  end

  def shift(date, {0,0,0}, :timestamp) do
    date
  end

  def shift(date, timestamp, :timestamp) do
    add(date, timestamp)
  end

  def shift(date, value, type) when type in [:sec, :min, :hours] do
    sec = to_sec(date)
    sec = sec + case type do
      :sec   -> value
      :min   -> value * 60
      :hours -> value * 60 * 60
    end
    { _, _, tz } = Date.Conversions.to_gregorian(date)
    replace(from(sec, :sec), :tz, tz)
  end

  def shift(date, value, :days) do
    days = to_days(date)
    days = days + value
    { _, time, tz } = Date.Conversions.to_gregorian(date)
    replace(from(days, :days), [time: time, tz: tz])
  end

  def shift(date, value, :weeks) do
    shift(date, value * 7, :days)
  end

  def shift(date, value, :months) do
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

  def shift(date, value, :years) do
    { {year,month,day}, time, tz } = Date.Conversions.to_gregorian(date)
    make_date(validate({year + value, month, day}), time, tz)
  end

  ### Private helper function ###

  defp normalize_shift(spec) when is_list(spec) do
    # FIXME: implement proper algorithm
    spec
  end

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
