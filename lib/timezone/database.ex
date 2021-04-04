defmodule Timex.Timezone.Database do
  @behaviour Calendar.TimeZoneDatabase

  alias Timex.Timezone
  alias Timex.TimezoneInfo

  @impl true
  @doc false
  def time_zone_period_from_utc_iso_days(iso_days, time_zone) do
    db = Tzdata.TimeZoneDatabase

    case db.time_zone_period_from_utc_iso_days(iso_days, time_zone) do
      {:error, :time_zone_not_found} ->
        # Get a NaiveDateTime for time_zone_periods_from_wall_datetime
        {year, month, day, hour, minute, second, microsecond} =
          Calendar.ISO.naive_datetime_from_iso_days(iso_days)

        with {:ok, naive} <-
               NaiveDateTime.new(year, month, day, hour, minute, second, microsecond) do
          time_zone_periods_from_wall_datetime(naive, time_zone)
        else
          {:error, _} ->
            {:error, :time_zone_not_found}
        end

      result ->
        result
    end
  end

  @impl true
  @doc false
  def time_zone_periods_from_wall_datetime(naive, time_zone) do
    db = Tzdata.TimeZoneDatabase

    if Tzdata.zone_exists?(time_zone) do
      case db.time_zone_periods_from_wall_datetime(naive, time_zone) do
        {:error, :time_zone_not_found} ->
          time_zone_periods_from_wall_datetime_fallback(naive, time_zone)

        result ->
          result
      end
    else
      time_zone_periods_from_wall_datetime_fallback(naive, time_zone)
    end
  end

  # Fallback method which looks for a desired timezone in the process state
  defp time_zone_periods_from_wall_datetime_fallback(naive, time_zone) do
    # Try to pop the time zone from process state, validate the desired datetime falls
    # within the bounds of the time zone, and return its period description if so
    case Process.put(__MODULE__, nil) do
      %TimezoneInfo{from: from, until: until} = tz ->
        with {:ok, range_start} <- period_boundary_to_naive(from),
             {:ok, range_end} <- period_boundary_to_naive(until) do
          cond do
            range_start == :min and range_end == :max ->
              {:ok, TimezoneInfo.to_period(tz)}

            range_start == :min and NaiveDateTime.compare(naive, range_end) in [:lt, :eq] ->
              {:ok, TimezoneInfo.to_period(tz)}

            range_end == :max and NaiveDateTime.compare(naive, range_start) in [:gt, :eq] ->
              {:ok, TimezoneInfo.to_period(tz)}

            range_start != :min and range_end != :max and
              NaiveDateTime.compare(naive, range_start) in [:gt, :eq] and
                NaiveDateTime.compare(naive, range_end) in [:lt, :eq] ->
              {:ok, TimezoneInfo.to_period(tz)}

            :else ->
              {:error, :time_zone_not_found}
          end
        else
          {:error, _} ->
            {:error, :time_zone_not_found}
        end

      nil ->
        time_zone_periods_from_wall_datetime_by_name(naive, time_zone)
    end
  end

  # Fallback method which attempts to lookup the timezone by name
  defp time_zone_periods_from_wall_datetime_by_name(naive, time_zone) do
    with %TimezoneInfo{} = tz <- Timezone.get(time_zone, naive) do
      {:ok, TimezoneInfo.to_period(tz)}
    end
  end

  defp period_boundary_to_naive(:min), do: {:ok, :min}
  defp period_boundary_to_naive(:max), do: {:ok, :max}

  defp period_boundary_to_naive({_, {{y, m, d}, {hh, mm, ss}}}) do
    NaiveDateTime.new(y, m, d, hh, mm, ss)
  end

  defp period_boundary_to_naive(_), do: {:error, :invalid_period}
end
