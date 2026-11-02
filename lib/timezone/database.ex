defmodule Timex.Timezone.Database do
  @behaviour Calendar.TimeZoneDatabase

  alias Timex.Timezone
  alias Timex.TimezoneInfo
  alias Timex.PosixTimezone

  @impl true
  @doc false
  def time_zone_period_from_utc_iso_days(iso_days, time_zone) do
    if Tzdata.zone_exists?(time_zone) do
      Tzdata.TimeZoneDatabase.time_zone_period_from_utc_iso_days(iso_days, time_zone)
    else
      # These digits are UTC, not local wall time in the requested zone.
      {year, month, day, hour, minute, second, microsecond} =
        Calendar.ISO.naive_datetime_from_iso_days(iso_days)

      with {:ok, naive} <-
             NaiveDateTime.new(year, month, day, hour, minute, second, microsecond) do
        case Timezone.lookup_posix(time_zone) do
          %PosixTimezone{} = tz -> PosixTimezone.period_from_utc(tz, naive)
          nil -> time_zone_periods_from_wall_datetime_fallback(naive, time_zone)
        end
      else
        {:error, _} ->
          {:error, :time_zone_not_found}
      end
    end
  end

  @impl true
  @doc false
  def time_zone_periods_from_wall_datetime(naive, time_zone) do
    if Tzdata.zone_exists?(time_zone) do
      seconds = naive |> NaiveDateTime.to_erl() |> :calendar.datetime_to_gregorian_seconds()

      case Tzdata.periods_for_time(time_zone, seconds, :wall) do
        [period] ->
          {:ok, to_period(period)}

        [_, _] = periods ->
          [earlier, later] = Enum.sort_by(periods, & &1.from.utc)
          {:ambiguous, to_period(earlier), to_period(later)}

        [] ->
          with {:ok, period} <- utc_period(time_zone, seconds) do
            gap_for_wall_time(time_zone, seconds, period)
          end

        {:error, _} ->
          time_zone_periods_from_wall_datetime_fallback(naive, time_zone)
      end
    else
      time_zone_periods_from_wall_datetime_fallback(naive, time_zone)
    end
  end

  # Follow actual UTC transitions, including dynamically generated future periods.
  # The finite list returned by Tzdata.periods/1 cannot describe every future gap.
  defp gap_for_wall_time(time_zone, seconds, %{until: %{wall: wall, utc: utc}} = earlier)
       when is_integer(wall) and is_integer(utc) and wall <= seconds do
    with {:ok, later} <- utc_period(time_zone, utc) do
      if is_integer(later.from.wall) and later.from.wall > seconds do
        gap_between(earlier, later)
      else
        gap_for_wall_time(time_zone, seconds, later)
      end
    end
  end

  defp gap_for_wall_time(time_zone, seconds, %{from: %{wall: wall, utc: utc}} = later)
       when is_integer(wall) and is_integer(utc) and wall > seconds do
    with {:ok, earlier} <- utc_period(time_zone, utc - 1) do
      if is_integer(earlier.until.wall) and earlier.until.wall <= seconds do
        gap_between(earlier, later)
      else
        gap_for_wall_time(time_zone, seconds, earlier)
      end
    end
  end

  defp gap_for_wall_time(_time_zone, _seconds, _period),
    do: {:error, :time_zone_not_found}

  defp utc_period(time_zone, seconds) do
    case Tzdata.periods_for_time(time_zone, seconds, :utc) do
      [period] -> {:ok, period}
      _ -> {:error, :time_zone_not_found}
    end
  end

  defp gap_between(earlier, later) do
    until_wall =
      earlier.until.wall |> :calendar.gregorian_seconds_to_datetime() |> NaiveDateTime.from_erl!()

    from_wall =
      later.from.wall |> :calendar.gregorian_seconds_to_datetime() |> NaiveDateTime.from_erl!()

    {:gap, {to_period(earlier), until_wall}, {to_period(later), from_wall}}
  end

  defp to_period(period) do
    %{utc_offset: period.utc_off, std_offset: period.std_off, zone_abbr: period.zone_abbr}
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
    case Timezone.lookup_posix(time_zone) do
      %PosixTimezone{} = tz ->
        PosixTimezone.periods_from_wall_datetime(tz, naive)

      nil ->
        with %TimezoneInfo{} = tz <- Timezone.get(time_zone, naive) do
          {:ok, TimezoneInfo.to_period(tz)}
        end
    end
  end

  defp period_boundary_to_naive(:min), do: {:ok, :min}
  defp period_boundary_to_naive(:max), do: {:ok, :max}

  defp period_boundary_to_naive({_, {{y, m, d}, {hh, mm, ss}}}) do
    NaiveDateTime.new(y, m, d, hh, mm, ss)
  end

  defp period_boundary_to_naive(_), do: {:error, :invalid_period}
end
