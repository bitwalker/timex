defimpl Timex.Protocol, for: Date do
  @moduledoc """
  This module represents all functions specific to creating/manipulating/comparing Dates (year/month/day)
  """
  use Timex.Constants
  import Timex.Macros

  @epoch_seconds :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  def to_julian(%Date{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  def to_gregorian_seconds(date), do: to_seconds(date, :zero)

  def to_gregorian_microseconds(date), do: to_seconds(date, :zero) * (1_000 * 1_000)

  def to_unix(date), do: trunc(to_seconds(date, :epoch))

  def to_date(date), do: date

  def to_datetime(%Date{} = date, timezone) do
    with {:tzdata, tz} when is_binary(tz) <- {:tzdata, Timex.Timezone.name_of(timezone)},
         {:ok, datetime} <- Timex.DateTime.new(date, ~T[00:00:00], tz, Timex.Timezone.Database) do
      datetime
    else
      {:tzdata, err} ->
        err

      {:error, _} = err ->
        err

      {:gap, _a, b} ->
        b

      {:ambiguous, _a, b} ->
        b
    end
  end

  def to_naive_datetime(%Date{year: y, month: m, day: d}) do
    Timex.NaiveDateTime.new!(y, m, d, 0, 0, 0)
  end

  def to_erl(%Date{year: y, month: m, day: d}), do: {y, m, d}

  def century(%Date{:year => year}), do: Timex.century(year)

  def is_leap?(%Date{year: year}), do: :calendar.is_leap_year(year)

  def beginning_of_day(%Date{} = date), do: date

  def end_of_day(%Date{} = date), do: date

  def beginning_of_week(%Date{} = date, weekstart) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> shift(date, days: -days)
    end
  end

  def end_of_week(%Date{} = date, weekstart) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err ->
        err

      days_to_end ->
        shift(date, days: days_to_end)
    end
  end

  def beginning_of_year(%Date{} = date),
    do: %{date | :month => 1, :day => 1}

  def end_of_year(%Date{} = date),
    do: %{date | :month => 12, :day => 31}

  def beginning_of_quarter(%Date{month: month} = date) do
    month = 1 + 3 * (Timex.quarter(month) - 1)
    %{date | :month => month, :day => 1}
  end

  def end_of_quarter(%Date{month: month} = date) do
    month = 3 * Timex.quarter(month)
    end_of_month(%{date | :month => month, :day => 1})
  end

  def beginning_of_month(%Date{} = date),
    do: %{date | :day => 1}

  def end_of_month(%Date{} = date),
    do: %{date | :day => days_in_month(date)}

  def quarter(%Date{year: y, month: m, day: d}), do: Calendar.ISO.quarter_of_year(y, m, d)

  def days_in_month(%Date{:year => y, :month => m}), do: Timex.days_in_month(y, m)

  def week_of_month(%Date{:year => y, :month => m, :day => d}), do: Timex.week_of_month(y, m, d)

  def weekday(%Date{} = date), do: Timex.Date.day_of_week(date)
  def weekday(%Date{} = date, weekstart), do: Timex.Date.day_of_week(date, weekstart)

  def day(%Date{} = date),
    do: 1 + Timex.diff(date, %Date{:year => date.year, :month => 1, :day => 1}, :days)

  def is_valid?(%Date{:year => y, :month => m, :day => d}) do
    :calendar.valid_date({y, m, d})
  end

  def iso_week(%Date{:year => y, :month => m, :day => d}),
    do: Timex.iso_week(y, m, d)

  def from_iso_day(%Date{year: year}, day) when is_day_of_year(day) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(year, day)
    %Date{year: year, month: month, day: day_of_month}
  end

  def set(%Date{} = date, options), do: Timex.Set.set(date, options, :invalid_option)

  def shift(%Date{} = date, [{_, 0}]), do: date

  def shift(%Date{} = date, options) do
    allowed_options =
      Enum.filter(options, fn
        {:hours, value} when value >= 24 or value <= -24 ->
          true

        {:hours, _} ->
          false

        {:minutes, value} when value >= 24 * 60 or value <= -24 * 60 ->
          true

        {:minutes, _} ->
          false

        {:seconds, value} when value >= 24 * 60 * 60 or value <= -24 * 60 * 60 ->
          true

        {:seconds, _} ->
          false

        {:milliseconds, value}
        when value >= 24 * 60 * 60 * 1000 or value <= -24 * 60 * 60 * 1000 ->
          true

        {:milliseconds, _} ->
          false

        {:microseconds, {value, _}}
        when value >= 24 * 60 * 60 * 1000 * 1000 or value <= -24 * 60 * 60 * 1000 * 1000 ->
          true

        {:microseconds, value}
        when value >= 24 * 60 * 60 * 1000 * 1000 or value <= -24 * 60 * 60 * 1000 * 1000 ->
          true

        {:microseconds, _} ->
          false

        {_type, _value} ->
          true
      end)

    case Timex.shift(to_naive_datetime(date), allowed_options) do
      {:error, _} = err ->
        err

      %NaiveDateTime{:year => y, :month => m, :day => d} ->
        %Date{year: y, month: m, day: d}
    end
  end

  defp to_seconds(%Date{year: y, month: m, day: d}, :zero),
    do: :calendar.datetime_to_gregorian_seconds({{y, m, d}, {0, 0, 0}})

  defp to_seconds(%Date{year: y, month: m, day: d}, :epoch),
    do: :calendar.datetime_to_gregorian_seconds({{y, m, d}, {0, 0, 0}}) - @epoch_seconds
end
