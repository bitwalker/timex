defmodule Date do
  ### Getting The Date ###

  @doc """
  Get current date in the local time zone.
  """
  def local do
      # same as :erlang.localtime()
      :calendar.local_time
  end

  @doc """
  Convert date to local time.
  """
  def local(date) do
      # TODO: determine date's time zone and adjust for the current time zone
      :calendar.universal_time_to_local_time(date)
  end

  @doc """
  Convert date to local time, the time zone of which is passed as the seconds
  argument.
  """
  def local(date, tz) do
      # TODO: determine date's time zone and adjust for tz
      date
  end

  @doc """
  Get current UTC date.
  """
  def universal do
      # same as :erlang.universaltime()
      :calendar.universal_time
  end

  @doc """
  Convert local date to UTC.
  """
  def universal(date) do
    # TODO: determine date's time zone and adjust for UTC
    :calendar.local_time_to_universal_time_dst(date)
  end

  @doc """
  Return a date representing midnight the first day of year zero. This same
  date is used as a reference point by Erlang's calendar module.
  """
  def distant_past do
    { {0,1,1}, {0,0,0} }
  end

  @doc """
  Return a date representing a remote moment in in the future. Can be used as a
  timeout value to effectively make the timeout indefinite.
  """
  def distant_future do
    { {9999,12,31}, {23,59,59} }
  end

  @doc """
  The date of UNIX epoch used as default reference date by this module and also
  by Time module.
  """
  def epoch do
    { {1970,1,1}, {0,0,0} }
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

  @doc """
  The first day of year zero (calendar's module default reference date).
  """
  def zero do
    { {0,1,1}, {0,0,0} }
  end

  ### Constructing the date from an existing value ###

  def from(value, type // :timestamp)

  def from({mega, sec, _}, :timestamp) do
    # microseconds are ingnored
    from(mega * _million + sec, :sec)
  end

  def from({mega, sec, _}, :timestamp_since_year_0) do
    from(mega * _million + sec - epoch(:sec), :sec)
  end

  def from(seconds, :sec) do
    :calendar.gregorian_seconds_to_datetime(seconds + epoch(:sec))
  end

  def from(days, :days) do
    { :calendar.gregorian_days_to_date(days + epoch(:days)), {0,0,0} }
  end


  ### Converting dates ###

  def to_timestamp(datetime) do
    seconds = to_sec(datetime)
    { div(seconds, _million), rem(seconds, _million), 0 }
  end

  def to_sec(datetime, reference // :epoch)

  def to_sec(datetime, 0) do
    :calendar.datetime_to_gregorian_seconds(datetime)
  end

  def to_sec(datetime, :epoch) do
    to_sec(datetime, 0) - epoch(:sec)
  end

  def to_sec(datetime1, datetime2) do
    to_sec(datetime1, 0) - to_sec(datetime2, 0)
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


  ### Date Arithmetic ###

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

  def is_valid({date, _time}) do
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
