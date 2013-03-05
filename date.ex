defmodule Date do
  def local do
      # same as :erlang.localtime
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
      # same as :erlang.universaltime
      :calendar.universal_time
  end

  def universal(date) do
    # TODO: determine date's time zone and adjust for UTC
    :calendar.local_time_to_universal_time_dst(date)
  end

  def add(date, 0, _) do
    date
  end

  def add(date, value, type) when type in [:seconds, :minutes, :hours] do
    secs = :calendar.datetime_to_gregorian_seconds(date)
    secs = secs + case type do
      :seconds -> value
      :minutes -> value * 60
      :hours   -> value * 60 * 60
    end
    :calendar.gregorian_seconds_to_datetime(secs)
  end

  def add({date, time}, value, :days) do
    days = :calendar.date_to_gregorian_days(date)
    days = days + value
    { :calendar.gregorian_days_to_date(days), time }
  end

  def add({ {y, m, d}, time }, value, :months) do
    # assert value > 0
    months = m + value
    if months <= 12 do
      { {y, months, d}, time }
    else
      years = y + div(months - 1, 12)
      months = case rem(months, 12) do
        0 -> 12
        x -> x
      end
      { {years, months, d}, time }
    end
  end

  def add({ {y, m, d}, time }, value, :years) do
    { {y + value, m, d}, time }
  end
end
