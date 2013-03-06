defrecord TimeDelta.Struct, days: 0, seconds: 0, micro: 0

defmodule TimeDelta do
  @moduledoc "Time delta construction"

  def from_value(value, :microseconds) do
    normalize TimeDelta.Struct.new([micro: value])
  end

  def from_value(value, :milliseconds) do
    normalize TimeDelta.Struct.new([micro: value * 1000])
  end

  def from_value(value, :seconds) do
    normalize TimeDelta.Struct.new([seconds: value])
  end

  def from_value(value, :minutes) do
    normalize TimeDelta.Struct.new([seconds: value * 60])
  end

  def from_value(value, :hours) do
    normalize TimeDelta.Struct.new([seconds: value * 3600])
  end

  def from_value(value, :days) do
    normalize TimeDelta.Struct.new([days: value])
  end

  def from_value(value, :weeks) do
    normalize TimeDelta.Struct.new([days: value * 7])
  end

  def add(td1, td2) do
    td = td1.update_days(fn(val) -> val + td2.days end)
    td = td.update_seconds(fn(val) -> val + td2.seconds end)
    td = td.update_micro(fn(val) -> val + td2.micro end)
    normalize td
  end

  def from_values(pairs) do
    Enum.reduce pairs, TimeDelta.Struct.new, fn({val, type}, acc) ->
      add(acc, TimeDelta.from_value(val, type))
    end
  end

  defp normalize(record) do
    if record.micro >= 1000000 do
      new_micro = rem record.micro, 1000000
      new_seconds = record.seconds + div record.micro, 1000000
    else
      new_micro = record.micro
      new_seconds = record.seconds
    end

    if new_seconds >= 3600 * 24 do
      new_days = record.days + div new_seconds, 3600 * 24
      new_seconds = rem new_seconds, 3600 * 24
    else
      new_days = record.days
    end

    TimeDelta.Struct.new [days: new_days, seconds: new_seconds, micro: new_micro]
  end
end

defmodule Date do
  ### Getting The Date ###

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

  ### Converting Dates ###

  @doc "Returns a binary with the ISO 8601 representation of the date"
  def iso8601({ {year, month, day}, {hour, min, sec} }) do
    list_to_binary(:io_lib.format("~4.10.0B-~2.10.0B-~2.10.0B ~2.10.0B:~2.10.0B:~2.10.0B",
                                  [year, month, day, hour, min, sec]))
  end

  @doc "Returns a binary with the RFC 1123 representation of the date"
  def rfc1123(date) do
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
  Another flavor of the shift function that accepts a timedelta value as its
  second argument.
  """
  def shift(date, timedelta) do
    date = shift(date, timedelta.days, :days)
    date = shift(date, timedelta.seconds, :seconds)
    # TODO: think about microseconds
    date
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
    cond do
      month == 0 ->
        year = year - 1
      month < 0 ->
        year = year + div(month, 12) - 1
      month > 12 ->
        year = year + div(month - 1, 12)
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
