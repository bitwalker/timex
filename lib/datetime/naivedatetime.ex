defimpl Timex.Protocol, for: NaiveDateTime do
  @moduledoc """
  This module implements Timex functionality for NaiveDateTime
  """
  alias Timex.AmbiguousDateTime
  import Timex.Macros

  @epoch_seconds :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  def now(), do: NaiveDateTime.utc_now()

  def to_julian(%NaiveDateTime{year: y, month: m, day: d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  def to_gregorian_seconds(date) do
    with {s, _} <- Timex.NaiveDateTime.to_gregorian_seconds(date), do: s
  end

  def to_gregorian_microseconds(%NaiveDateTime{} = date) do
    with {s, us} <- Timex.NaiveDateTime.to_gregorian_seconds(date) do
      s * (1_000 * 1_000) + us
    end
  end

  def to_unix(date) do
    with {s, _} <- Timex.NaiveDateTime.to_gregorian_seconds(date) do
      s - @epoch_seconds
    end
  end

  def to_date(date), do: NaiveDateTime.to_date(date)

  def to_datetime(%NaiveDateTime{} = naive, timezone) do
    with %DateTime{} = datetime <- Timex.Timezone.convert(naive, timezone) do
      datetime
    else
      %AmbiguousDateTime{} = datetime ->
        datetime

      {:error, _} = err ->
        err
    end
  end

  def to_naive_datetime(%NaiveDateTime{} = date), do: date

  def to_erl(%NaiveDateTime{} = d), do: NaiveDateTime.to_erl(d)

  def century(%NaiveDateTime{:year => year}), do: Timex.century(year)

  def is_leap?(%NaiveDateTime{year: year}), do: :calendar.is_leap_year(year)

  def beginning_of_day(%NaiveDateTime{:microsecond => {_, precision}} = datetime) do
    %{datetime | :hour => 0, :minute => 0, :second => 0, :microsecond => {0, precision}}
  end

  def end_of_day(%NaiveDateTime{microsecond: {_, precision}} = datetime) do
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    %{datetime | :hour => 23, :minute => 59, :second => 59, :microsecond => us}
  end

  def beginning_of_week(%NaiveDateTime{microsecond: {_, precision}} = date, weekstart) do
    with ws when is_atom(ws) <- Timex.standardize_week_start(weekstart) do
      date = Timex.Date.beginning_of_week(date, ws)
      Timex.NaiveDateTime.new!(date.year, date.month, date.day, 0, 0, 0, {0, precision})
    end
  end

  def end_of_week(%NaiveDateTime{microsecond: {_, precision}} = date, weekstart) do
    with ws when is_atom(ws) <- Timex.standardize_week_start(weekstart) do
      date = Timex.Date.end_of_week(date, ws)
      us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
      Timex.NaiveDateTime.new!(date.year, date.month, date.day, 23, 59, 59, us)
    end
  end

  def beginning_of_year(%NaiveDateTime{year: year, microsecond: {_, precision}}) do
    Timex.NaiveDateTime.new!(year, 1, 1, 0, 0, 0, {0, precision})
  end

  def end_of_year(%NaiveDateTime{year: year, microsecond: {_, precision}}) do
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    Timex.NaiveDateTime.new!(year, 12, 31, 23, 59, 59, us)
  end

  def beginning_of_quarter(%NaiveDateTime{month: month} = date) do
    month = 1 + 3 * (Timex.quarter(month) - 1)
    beginning_of_month(%{date | :month => month, :day => 1})
  end

  def end_of_quarter(%NaiveDateTime{month: month} = date) do
    month = 3 * Timex.quarter(month)
    end_of_month(%{date | :month => month, :day => 1})
  end

  def beginning_of_month(%NaiveDateTime{year: year, month: month, microsecond: {_, precision}}),
    do: Timex.NaiveDateTime.new!(year, month, 1, 0, 0, 0, {0, precision})

  def end_of_month(%NaiveDateTime{year: year, month: month, microsecond: {_, precision}} = date) do
    day = days_in_month(date)
    us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
    Timex.NaiveDateTime.new!(year, month, day, 23, 59, 59, us)
  end

  def quarter(%NaiveDateTime{year: y, month: m, day: d}),
    do: Calendar.ISO.quarter_of_year(y, m, d)

  def days_in_month(%NaiveDateTime{year: y, month: m}), do: Timex.days_in_month(y, m)

  def week_of_month(%NaiveDateTime{year: y, month: m, day: d}),
    do: Timex.week_of_month(y, m, d)

  def weekday(%NaiveDateTime{} = date),
    do: Timex.Date.day_of_week(date)

  def weekday(%NaiveDateTime{} = date, weekstart),
    do: Timex.Date.day_of_week(date, weekstart)

  def day(%NaiveDateTime{} = date), do: Date.day_of_year(date)

  def is_valid?(%NaiveDateTime{
        :year => y,
        :month => m,
        :day => d,
        :hour => h,
        :minute => min,
        :second => sec
      }) do
    :calendar.valid_date({y, m, d}) and Timex.is_valid_time?({h, min, sec})
  end

  def iso_week(%NaiveDateTime{:year => y, :month => m, :day => d}),
    do: Timex.iso_week(y, m, d)

  def from_iso_day(%NaiveDateTime{year: year} = date, day) when is_day_of_year(day) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end

  def set(%NaiveDateTime{} = date, options) do
    validate? = Keyword.get(options, :validate, true)

    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err

      option, result ->
        case option do
          {:validate, _} ->
            result

          {:datetime, {{y, m, d}, {h, min, sec}}} ->
            if validate? do
              %{
                result
                | :year => Timex.normalize(:year, y),
                  :month => Timex.normalize(:month, m),
                  :day => Timex.normalize(:day, {y, m, d}),
                  :hour => Timex.normalize(:hour, h),
                  :minute => Timex.normalize(:minute, min),
                  :second => Timex.normalize(:second, sec)
              }
            else
              %{
                result
                | :year => y,
                  :month => m,
                  :day => d,
                  :hour => h,
                  :minute => min,
                  :second => sec
              }
            end

          {:date, {y, m, d}} ->
            if validate? do
              {yn, mn, dn} = Timex.normalize(:date, {y, m, d})
              %{result | :year => yn, :month => mn, :day => dn}
            else
              %{result | :year => y, :month => m, :day => d}
            end

          {:date, %Date{} = d} ->
            Timex.set(result, date: {d.year, d.month, d.day})

          {:time, {h, m, s}} ->
            if validate? do
              %{
                result
                | :hour => Timex.normalize(:hour, h),
                  :minute => Timex.normalize(:minute, m),
                  :second => Timex.normalize(:second, s)
              }
            else
              %{result | :hour => h, :minute => m, :second => s}
            end

          {:time, {h, m, s, ms}} ->
            if validate? do
              %{
                result
                | :hour => Timex.normalize(:hour, h),
                  :minute => Timex.normalize(:minute, m),
                  :second => Timex.normalize(:second, s),
                  :microsecond => Timex.normalize(:microsecond, ms)
              }
            else
              %{result | :hour => h, :minute => m, :second => s, :microsecond => ms}
            end

          {:time, %Time{} = t} ->
            Timex.set(result, time: {t.hour, t.minute, t.second, t.microsecond})

          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end

          {name, val} when name in [:year, :month, :hour, :minute, :second, :microsecond] ->
            if validate? do
              Map.put(result, name, Timex.normalize(name, val))
            else
              Map.put(result, name, val)
            end

          {name, _} when name in [:timezone] ->
            result

          {option_name, _} ->
            {:error, {:bad_option, option_name}}
        end
    end)
  end

  def shift(%NaiveDateTime{} = datetime, shifts) when is_list(shifts) do
    with {:ok, dt} <- DateTime.from_naive(datetime, "Etc/UTC", Timex.Timezone.Database) do
      case Timex.shift(dt, shifts) do
        {:error, _} = err ->
          err

        %AmbiguousDateTime{after: datetime} ->
          DateTime.to_naive(datetime)

        %DateTime{} = datetime ->
          DateTime.to_naive(datetime)
      end
    end
  end
end
