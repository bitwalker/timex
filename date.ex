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
    :httpd_util.rfc1123_date(date)
  end

  ### Date Arithmetic ###

  def shift(date, 0, _) do
    date
  end

  def shift(date, value, type) when type in [:seconds, :minutes, :hours] do
    secs = :calendar.datetime_to_gregorian_seconds(date)
    secs = secs + case type do
      :seconds -> value
      :minutes -> value * 60
      :hours   -> value * 60 * 60
    end
    :calendar.gregorian_seconds_to_datetime(secs)
  end

  def shift({date, time}, value, :days) do
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
