defimpl Timex.Protocol, for: Date do
  @moduledoc """
  This module represents all functions specific to creating/manipulating/comparing Dates (year/month/day)
  """
  use Timex.Constants
  import Timex.Macros

  alias Timex.Types

  @epoch_seconds :calendar.datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}})

  @spec to_julian(Date.t) :: integer
  def to_julian(%Date{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  @spec to_gregorian_seconds(Date.t) :: integer
  def to_gregorian_seconds(date), do: to_seconds(date, :zero)

  @spec to_gregorian_microseconds(Date.t) :: integer
  def to_gregorian_microseconds(date), do: (to_seconds(date, :zero) * (1_000*1_000))

  @spec to_unix(Date.t) :: integer
  def to_unix(date), do: trunc(to_seconds(date, :epoch))

  @spec to_date(Date.t) :: Date.t
  def to_date(date), do: date

  @spec to_datetime(Date.t, timezone :: Types.valid_timezone) :: DateTime.t | {:error, term}
  def to_datetime(%Date{:year => y, :month => m, :day => d}, timezone) do
    Timex.DateTime.Helpers.construct({y,m,d}, timezone)
  end

  @spec to_naive_datetime(Date.t) :: NaiveDateTime.t
  def to_naive_datetime(%Date{:year => y, :month => m, :day => d}) do
    %NaiveDateTime{year: y, month: m, day: d, hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
  end

  @spec to_erl(Date.t) :: Types.date
  def to_erl(%Date{year: y, month: m, day: d}), do: {y,m,d}

  @spec century(Date.t) :: non_neg_integer
  def century(%Date{:year => year}), do: Timex.century(year)

  @spec is_leap?(Date.t) :: boolean
  def is_leap?(%Date{year: year}), do: :calendar.is_leap_year(year)

  @spec beginning_of_day(Date.t) :: Date.t
  def beginning_of_day(%Date{} = date), do: date

  @spec end_of_day(Date.t) :: Date.t
  def end_of_day(%Date{} = date), do: date

  @spec beginning_of_week(Date.t, Types.weekday) :: Date.t
  def beginning_of_week(%Date{} = date, weekstart) do
    case Timex.days_to_beginning_of_week(date, weekstart) do
      {:error, _} = err -> err
      days -> shift(date, [days: -days])
    end
  end

  @spec end_of_week(Date.t, Types.weekday) :: Date.t
  def end_of_week(%Date{} = date, weekstart) do
    case Timex.days_to_end_of_week(date, weekstart) do
      {:error, _} = err -> err
      days_to_end ->
        shift(date, [days: days_to_end])
    end
  end

  @spec beginning_of_year(Date.t) :: Date.t
  def beginning_of_year(%Date{} = date),
    do: %{date | :month => 1, :day => 1}

  @spec end_of_year(Date.t) :: Date.t
  def end_of_year(%Date{} = date),
    do: %{date | :month => 12, :day => 31}

  @spec beginning_of_quarter(Date.t) :: Date.t
  def beginning_of_quarter(%Date{month: month} = date) do
    month = 1 + (3 * (quarter(month) - 1))
    %{date | :month => month, :day => 1}
  end

  @spec end_of_quarter(Date.t) :: Date.t
  def end_of_quarter(%Date{month: month} = date) do
    month = 3 * quarter(month)
    end_of_month(%{date | :month => month, :day => 1})
  end

  @spec beginning_of_month(Date.t) :: Date.t
  def beginning_of_month(%Date{} = date),
    do: %{date | :day => 1}

  @spec end_of_month(Date.t) :: Date.t
  def end_of_month(%Date{} = date),
    do: %{date | :day => days_in_month(date)}

  @spec quarter(Date.t) :: integer
  def quarter(%Date{month: month}), do: Timex.quarter(month)

  def days_in_month(%Date{:year => y, :month => m}), do: Timex.days_in_month(y, m)

  def week_of_month(%Date{:year => y, :month => m, :day => d}), do: Timex.week_of_month(y,m,d)

  def weekday(%Date{:year => y, :month => m, :day => d}), do: :calendar.day_of_the_week({y, m, d})

  def day(%Date{} = date),
    do: 1 + Timex.diff(date, %Date{:year => date.year, :month => 1, :day => 1}, :days)

  def is_valid?(%Date{:year => y, :month => m, :day => d}) do
    :calendar.valid_date({y,m,d})
  end

  def iso_week(%Date{:year => y, :month => m, :day => d}),
    do: Timex.iso_week(y, m, d)

  def from_iso_day(%Date{year: year} = date, day) when is_day_of_year(day) do
    {year, month, day_of_month} = Timex.Helpers.iso_day_to_date_tuple(year, day)
    %{date | :year => year, :month => month, :day => day_of_month}
  end

  @doc """
  See docs for Timex.set/2 for details.
  """
  @spec set(Date.t, list({atom(), term})) :: Date.t | {:error, term}
  def set(%Date{} = date, options) do
    validate? = Keyword.get(options, :validate, true)
    Enum.reduce(options, date, fn
      _option, {:error, _} = err ->
        err
      option, %Date{} = result ->
        case option do
          {:validate, _} -> result
          {:datetime, {{y, m, d}, {_, _, _}}} ->
            if validate? do
              %{result |
                :year =>   Timex.normalize(:year,   y),
                :month =>  Timex.normalize(:month,  m),
                :day =>    Timex.normalize(:day,    {y,m,d}),
              }
            else
              %{result | :year => y, :month => m, :day => d}
            end
          {:date, {y, m, d}} ->
            if validate? do
              {yn,mn,dn} = Timex.normalize(:date, {y,m,d})
              %{result | :year => yn, :month => mn, :day => dn}
            else
              %{result | :year => y, :month => m, :day => d}
            end
          {:day, d} ->
            if validate? do
              %{result | :day => Timex.normalize(:day, {result.year, result.month, d})}
            else
              %{result | :day => d}
            end
          {name, val} when name in [:year, :month] ->
            if validate? do
              Map.put(result, name, Timex.normalize(name, val))
            else
              Map.put(result, name, val)
            end
          {name, _} when name in [:time, :timezone, :hour, :minute, :second, :microsecond] ->
            result
          {option_name, _}   ->
            {:error, {:invalid_option, option_name}}
        end
    end)
  end

  @spec shift(Date.t, list({atom(), term})) :: Date.t | {:error, term}
  def shift(%Date{} = date, [{_, 0}]),               do: date
  def shift(%Date{} = date, options) do
    allowed_options = Enum.filter(options, fn
      {:hours, value} when value >= 24 or value <= -24 -> true
      {:hours, _} -> false
      {:minutes, value} when value >= 24*60 or value <= -24*60 -> true
      {:minutes, _} -> false
      {:seconds, value} when value >= 24*60*60 or value <= -24*60*60 -> true
      {:seconds, _} -> false
      {:milliseconds, value} when value >= 24*60*60*1000 or value <= -24*60*60*1000 -> true
      {:milliseconds, _} -> false
      {:microseconds, {value, _}} when value >= 24*60*60*1000*1000 or value <= -24*60*60*1000*1000 -> true
      {:microseconds, value} when value >= 24*60*60*1000*1000 or value <= -24*60*60*1000*1000 -> true
      {:microseconds, _} -> false
      {_type, _value} -> true
    end)
    case Timex.shift(to_naive_datetime(date), allowed_options) do
      {:error, _} = err -> err
      %NaiveDateTime{:year => y, :month => m, :day => d} ->
        %Date{year: y, month: m, day: d}
    end
  end
  def shift(_, _), do: {:error, :badarg}

  defp to_seconds(%Date{year: y, month: m, day: d}, :zero),
    do: :calendar.datetime_to_gregorian_seconds({{y,m,d},{0,0,0}})
  defp to_seconds(%Date{year: y, month: m, day: d}, :epoch),
    do: (:calendar.datetime_to_gregorian_seconds({{y,m,d},{0,0,0}}) - @epoch_seconds)

end
