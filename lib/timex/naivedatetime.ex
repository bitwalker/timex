defmodule Timex.NaiveDateTime do
  if Version.compare(System.version(), "1.11.0") == :lt do
    @seconds_per_day 24 * 60 * 60

    @doc false
    def new!(date, time) do
      case NaiveDateTime.new(date, time) do
        {:ok, naive_datetime} ->
          naive_datetime

        {:error, reason} ->
          raise ArgumentError, "cannot build naive datetime, reason: #{inspect(reason)}"
      end
    end

    @doc false
    def new!(
          year,
          month,
          day,
          hour,
          minute,
          second,
          microsecond \\ {0, 0},
          calendar \\ Calendar.ISO
        ) do
      case NaiveDateTime.new(year, month, day, hour, minute, second, microsecond, calendar) do
        {:ok, naive_datetime} ->
          naive_datetime

        {:error, reason} ->
          raise ArgumentError, "cannot build naive datetime, reason: #{inspect(reason)}"
      end
    end

    @doc false
    def to_gregorian_seconds(%NaiveDateTime{
          calendar: calendar,
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second,
          microsecond: {microsecond, precision}
        }) do
      {days, day_fraction} =
        calendar.naive_datetime_to_iso_days(
          year,
          month,
          day,
          hour,
          minute,
          second,
          {microsecond, precision}
        )

      seconds_in_day = seconds_from_day_fraction(day_fraction)
      {days * @seconds_per_day + seconds_in_day, microsecond}
    end

    defp seconds_from_day_fraction({parts_in_day, @seconds_per_day}),
      do: parts_in_day

    defp seconds_from_day_fraction({parts_in_day, parts_per_day}),
      do: div(parts_in_day * @seconds_per_day, parts_per_day)
  else
    @doc false
    defdelegate new!(date, time), to: NaiveDateTime

    @doc false
    defdelegate new!(
                  year,
                  month,
                  day,
                  hour,
                  minute,
                  second,
                  microsecond \\ {0, 0},
                  calendar \\ Calendar.ISO
                ),
                to: NaiveDateTime

    @doc false
    defdelegate to_gregorian_seconds(naive), to: NaiveDateTime
  end
end
