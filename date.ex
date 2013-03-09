defmodule Date do
  ### Getting The Date ###

  def from(value, type // nil)

  def from({mega, secs, _}, type) when type in [nil, :timestamp] do
    # microseconds are ingnored
    from(mega * 1000000 + secs, :sec)
  end

  def from(seconds, :sec) do
    :calendar.gregorian_seconds_to_datetime(seconds)
  end

  def from(days, :days) do
    { :calendar.gregorian_days_to_date(days), {0,0,0} }
  end

  def to_sec(date) do
    :calendar.datetime_to_gregorian_seconds(date)
  end

  def to_days(date) do
    :calendar.date_to_gregorian_days(date)
  end

  def convert(date, :sec) do
    to_sec(date)
  end

  def convert(date, :days) do
    to_days(date)
  end

  @doc """
  1 - Monday, ..., 7 - Sunday
  """
  def weekday({date, _}) do
    weekday(date)
  end

  def weekday(date) do
    :calendar.day_of_the_week(date)
  end

  def iso_triplet({date, _}) do
    iso_triplet(date)
  end

  def iso_triplet(date) do
    { iso_year, iso_week } = :calendar.iso_week_number(date)
    { iso_year, iso_week, weekday(date) }
  end

  def local do
      # same as :erlang.localtime()
      :calendar.local_time
  end

  def local(date) do
      # TODO: determine date's time zone and adjust for the current time zone
      :calendar.universal_time_to_local_time(date)
  end

  def local(date, tz) do
      # TODO: determine date's time zone and adjust for tz
      date
  end

  def universal do
      # same as :erlang.universaltime()
      :calendar.universal_time
  end

  def universal(date) do
    # TODO: determine date's time zone and adjust for UTC
    :calendar.local_time_to_universal_time_dst(date)
  end

  def distant_past do
    { {0,1,1}, {0,0,0} }
  end

  def distant_future do
    { {9999,12,31}, {23,59,59} }
  end

  ### Converting Dates ###

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

  def seconds_since_0(date) do
    # date has to be in UTC
    :calendar.datetime_to_gregorian_seconds(date)
  end

  def seconds_since_1970(date) do
    # date has to be in UTC
    unix_epoch = { {1970, 1, 1}, {0, 0, 0} }
    unix_seconds = :calendar.datetime_to_gregorian_seconds(unix_epoch)
    :calendar.datetime_to_gregorian_seconds(date) - unix_seconds
  end

  def seconds_diff(date1, date2) do
    seconds1 = :calendar.datetime_to_gregorian_seconds(date1)
    seconds2 = :calendar.datetime_to_gregorian_seconds(date2)
    seconds1 - seconds2
  end

  ### Date Arithmetic ###

  @doc """
  Another flavor of the shift function that accepts a timestamp value as its
  second argument.
  """
  def shift(date, {mega, secs, _}) do
    # microseconds are simply ignored
    shift(date, mega * 1000000 + secs, :seconds)
  end

  def shift(datetime, spec) when is_list(spec) do
    Enum.reduce spec, datetime, fn({value, type}, result) ->
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

    Date.shift(datetime, 24*3600*365, :seconds)
    #=> {{2014,3,5},{23,23,23}}

    Date.shift(datetime, -24*3600*(365*2 + 1), :seconds)   # +1 day for leap year 2012
    #=> {{2011,3,5},{23,23,23}}

  """
  def shift(date, 0, _) do
    date
  end

  def shift(date, value, type) when type in [:seconds, :minutes, :hours] do
    # TODO: time zone adjustments
    secs = :calendar.datetime_to_gregorian_seconds(date)
    secs = secs + case type do
      :seconds -> value
      :minutes -> value * 60
      :hours   -> value * 60 * 60
    end
    :calendar.gregorian_seconds_to_datetime(secs)
  end

  def shift({date, time}, value, :days) do
    # TODO: time zone adjustments
    days = :calendar.date_to_gregorian_days(date)
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

  defp validate({year, month, day}) do
    # Check if we got past the last day of the month
    max_day = :calendar.last_day_of_the_month(year, month)
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
end
