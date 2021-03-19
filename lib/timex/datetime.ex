defmodule Timex.DateTime do
  if Version.compare(System.version(), "1.11.0") == :lt do
    @seconds_per_day 24 * 60 * 60

    def new(
          date,
          time,
          time_zone \\ "Etc/UTC",
          time_zone_database \\ Calendar.get_time_zone_database()
        )

    def new(%Date{calendar: calendar} = date, %Time{calendar: calendar} = time, "Etc/UTC", _db) do
      %{year: year, month: month, day: day} = date
      %{hour: hour, minute: minute, second: second, microsecond: microsecond} = time

      datetime = %DateTime{
        calendar: calendar,
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        microsecond: microsecond,
        std_offset: 0,
        utc_offset: 0,
        zone_abbr: "UTC",
        time_zone: "Etc/UTC"
      }

      {:ok, datetime}
    end

    def new(date, time, time_zone, time_zone_database) do
      with {:ok, naive_datetime} <- NaiveDateTime.new(date, time) do
        DateTime.from_naive(naive_datetime, time_zone, time_zone_database)
      end
    end

    @doc false
    def new!(
          date,
          time,
          time_zone \\ "Etc/UTC",
          time_zone_database \\ Calendar.get_time_zone_database()
        ) do
      case new(date, time, time_zone, time_zone_database) do
        {:ok, datetime} ->
          datetime

        {:ambiguous, dt1, dt2} ->
          raise ArgumentError,
                "cannot build datetime with #{inspect(date)} and #{inspect(time)} because such " <>
                  "instant is ambiguous in time zone #{time_zone} as there is an overlap " <>
                  "between #{inspect(dt1)} and #{inspect(dt2)}"

        {:gap, dt1, dt2} ->
          raise ArgumentError,
                "cannot build datetime with #{inspect(date)} and #{inspect(time)} because such " <>
                  "instant does not exist in time zone #{time_zone} as there is a gap " <>
                  "between #{inspect(dt1)} and #{inspect(dt2)}"

        {:error, reason} ->
          raise ArgumentError,
                "cannot build datetime with #{inspect(date)} and #{inspect(time)}, reason: #{
                  inspect(reason)
                }"
      end
    end

    @doc false
    def to_gregorian_seconds(
          %{
            std_offset: std_offset,
            utc_offset: utc_offset,
            microsecond: {microsecond, _}
          } = datetime
        ) do
      {days, day_fraction} =
        datetime
        |> to_iso_days()
        |> apply_tz_offset(utc_offset + std_offset)

      seconds_in_day = seconds_from_day_fraction(day_fraction)
      {days * @seconds_per_day + seconds_in_day, microsecond}
    end

    defp to_iso_days(%{
           calendar: calendar,
           year: year,
           month: month,
           day: day,
           hour: hour,
           minute: minute,
           second: second,
           microsecond: microsecond
         }) do
      calendar.naive_datetime_to_iso_days(year, month, day, hour, minute, second, microsecond)
    end

    defp apply_tz_offset(iso_days, 0), do: iso_days

    defp apply_tz_offset(iso_days, offset) do
      Calendar.ISO.add_day_fraction_to_iso_days(iso_days, -offset, 86400)
    end

    defp seconds_from_day_fraction({parts_in_day, @seconds_per_day}),
      do: parts_in_day

    defp seconds_from_day_fraction({parts_in_day, parts_per_day}),
      do: div(parts_in_day * @seconds_per_day, parts_per_day)
  else
    @doc false
    defdelegate new(
                  date,
                  time,
                  time_zone \\ "Etc/UTC",
                  time_zone_database \\ Calendar.get_time_zone_database()
                ),
                to: DateTime

    @doc false
    defdelegate new!(
                  date,
                  time,
                  time_zone \\ "Etc/UTC",
                  time_zone_database \\ Calendar.get_time_zone_database()
                ),
                to: DateTime

    @doc false
    defdelegate to_gregorian_seconds(datetime), to: DateTime
  end

  if Version.compare(System.version(), "1.10.0") == :lt do
    @doc false
    def shift_zone!(datetime, time_zone, time_zone_database \\ Calendar.get_time_zone_database()) do
      case DateTime.shift_zone(datetime, time_zone, time_zone_database) do
        {:ok, datetime} ->
          datetime

        {:error, reason} ->
          raise ArgumentError,
                "cannot shift #{inspect(datetime)} to #{inspect(time_zone)} time zone" <>
                  ", reason: #{inspect(reason)}"
      end
    end
  else
    @doc false
    defdelegate shift_zone!(
                  datetime,
                  time_zone,
                  time_zone_database \\ Calendar.get_time_zone_database()
                ),
                to: DateTime
  end
end
