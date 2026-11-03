defmodule Timex.CalendarSupport do
  @moduledoc false

  @year_10000 :calendar.datetime_to_gregorian_seconds({{10000, 1, 1}, {0, 0, 0}}) * 1_000_000

  defguard is_unsupported_year(year)
           when is_integer(year) and (year < 0 or year > 9999)

  # Protocol implementations assume ISO fields. Enforce that precondition at
  # the public API while leaving custom protocol representations to their owners.
  def validate(%{__struct__: type, calendar: calendar, year: year})
      when type in [Date, NaiveDateTime, DateTime] do
    with :ok <- validate_calendar(calendar), do: validate_year(year)
  end

  def validate(%Timex.AmbiguousDateTime{before: before, after: after_date}) do
    with :ok <- validate(before), do: validate(after_date)
  end

  def validate(%{__struct__: _}), do: :ok

  def validate(date) when is_map(date) do
    case {map_field(date, :year), map_field(date, :month), map_field(date, :day)} do
      {year, month, day} when not is_nil(year) and not is_nil(month) and not is_nil(day) ->
        with :ok <- validate_calendar(Map.get(date, :calendar, Calendar.ISO)),
             :ok <- validate_calendar(Map.get(date, "calendar", Calendar.ISO)),
             :ok <- validate_map_year(Map.get(date, :year)),
             do: validate_map_year(Map.get(date, "year"))

      _ ->
        :ok
    end
  end

  def validate({year, month, day})
      when is_integer(year) and month in 1..12 and day in 1..31,
      do: validate_year(year)

  def validate({{year, month, day}, _time}), do: validate({year, month, day})
  def validate(_), do: :ok

  def validate_comparison(%DateTime{} = date) do
    with :ok <- validate(date),
         {seconds, microseconds} <- Timex.DateTime.to_gregorian_seconds(date),
         do: validate_instant(seconds * 1_000_000 + microseconds)
  end

  def validate_comparison(%Timex.AmbiguousDateTime{before: before, after: after_date}) do
    with :ok <- validate_comparison(before), do: validate_comparison(after_date)
  end

  def validate_comparison(date), do: validate(date)

  def validate_instant(value) when value < 0, do: {:error, {:unsupported_year, -1}}

  def validate_instant(value) when value >= @year_10000,
    do: {:error, {:unsupported_year, 10000}}

  def validate_instant(_), do: :ok

  # Older Calendar.ISO versions raise before an out-of-range date can be
  # validated. Recognize only that specific failure from its actual arguments.
  def date_range_error([{Calendar.ISO, :date_from_iso_days, [days], _} | _])
      when is_integer(days) do
    case validate_instant(days * 86_400_000_000) do
      :ok -> nil
      error -> error
    end
  end

  def date_range_error(_), do: nil

  def validate_set_options(options) do
    Enum.reduce_while(options, :ok, fn option, :ok ->
      case validate_option_calendar(option) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  def validate_year(year) when is_unsupported_year(year),
    do: {:error, {:unsupported_year, year}}

  def validate_year(_), do: :ok

  defp validate_calendar(Calendar.ISO), do: :ok
  defp validate_calendar(calendar), do: {:error, {:unsupported_calendar, calendar}}

  defp validate_option_calendar({:date, %Date{calendar: calendar}}),
    do: validate_calendar(calendar)

  defp validate_option_calendar({:time, %Time{calendar: calendar}}),
    do: validate_calendar(calendar)

  defp validate_option_calendar({:datetime, {date, time}}) do
    with :ok <- validate_option_calendar({:date, date}),
         do: validate_option_calendar({:time, time})
  end

  defp validate_option_calendar(_), do: :ok

  defp validate_map_year(year) when is_binary(year) do
    case Integer.parse(year) do
      {year, _} -> validate_year(year)
      :error -> :ok
    end
  end

  defp validate_map_year(year), do: validate_year(year)

  defp map_field(map, name), do: Map.get(map, name, Map.get(map, Atom.to_string(name)))
end
