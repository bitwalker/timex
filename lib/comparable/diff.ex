defmodule Timex.Comparable.Diff do
  @moduledoc false

  alias Timex.Types
  alias Timex.Duration
  alias Timex.Comparable

  @units [:years, :months, :weeks, :calendar_weeks, :days,
          :hours, :minutes, :seconds, :milliseconds, :microseconds,
          :duration]

  @spec diff(Types.microseconds, Types.microseconds, Comparable.granularity) :: integer
  def diff(a, a, granularity) when is_integer(a), do: zero(granularity)
  def diff(a, b, granularity) when is_integer(a) and is_integer(b) and is_atom(granularity) do
    do_diff(a, b, granularity)
  end

  defp do_diff(a, a, type),      do: zero(type)
  defp do_diff(a, b, :duration), do: Duration.from_seconds(do_diff(a,b,:seconds))
  defp do_diff(a, b, :microseconds), do: a - b
  defp do_diff(a, b, :milliseconds), do: div(a - b, 1_000)
  defp do_diff(a, b, :seconds),      do: div(a - b, 1_000*1_000)
  defp do_diff(a, b, :minutes),      do: div(a - b, 1_000*1_000*60)
  defp do_diff(a, b, :hours),        do: div(a - b, 1_000*1_000*60*60)
  defp do_diff(a, b, :days),         do: div(a - b, 1_000*1_000*60*60*24)
  defp do_diff(a, b, :weeks),        do: div(a - b, 1_000*1_000*60*60*24*7)
  defp do_diff(a, b, :calendar_weeks) do
    adate      = :calendar.gregorian_seconds_to_datetime(div(a, 1_000*1_000))
    bdate      = :calendar.gregorian_seconds_to_datetime(div(b, 1_000*1_000))
    days = cond do
      a > b ->
        ending     = Timex.end_of_week(adate)
        start      = Timex.beginning_of_week(bdate)
        endu       = Timex.to_gregorian_microseconds(ending)
        startu     = Timex.to_gregorian_microseconds(start)
        do_diff(endu, startu, :days)
      :else ->
        ending     = Timex.end_of_week(bdate)
        start      = Timex.beginning_of_week(adate)
        endu       = Timex.to_gregorian_microseconds(ending)
        startu     = Timex.to_gregorian_microseconds(start)
        do_diff(startu, endu, :days)
    end
    cond do
      days >= 0 && rem(days, 7) != 0 -> div(days, 7) + 1
      days <= 0 && rem(days, 7) != 0 -> div(days, 7) - 1
      :else -> div(days, 7)
    end
  end
  defp do_diff(a, b, :months) do
    {high_y, high_m, high_d, low_y, low_m, low_d, sign} = convert_to_signed_date_tuples(a, b)

    nof_months = (high_y * 12 + high_m) - (low_y * 12 + low_m)
    nof_months = if (nof_months == 0 || low_d <= high_d),  do: nof_months, else: nof_months - 1
    nof_months * sign
  end
  defp do_diff(a, b, :years) do
    {high_y, high_m, high_d, low_y, low_m, low_d, sign} = convert_to_signed_date_tuples(a, b)

    nof_years = high_y - low_y
    nof_years = if (nof_years == 0 || {low_y, low_m, low_d} <= {high_y - nof_years, high_m, high_d}),  do: nof_years, else: nof_years - 1
    nof_years * sign
  end

  defp do_diff(_, _, granularity) when not granularity in @units,
    do: {:error, {:invalid_granularity, granularity}}

  defp zero(:duration), do: Duration.zero
  defp zero(_type), do: 0

  defp convert_to_signed_date_tuples(a, b) do
    cond do
      a > b ->
        {{high_y, high_m, high_d}, _} = :calendar.gregorian_seconds_to_datetime(div(a, 1_000*1_000))
        {{low_y, low_m, low_d}, _}    = :calendar.gregorian_seconds_to_datetime(div(b, 1_000*1_000))
        {high_y, high_m, high_d, low_y, low_m, low_d, 1}
      :else ->
        {{low_y, low_m, low_d}, _}    = :calendar.gregorian_seconds_to_datetime(div(a, 1_000*1_000))
        {{high_y, high_m, high_d}, _} = :calendar.gregorian_seconds_to_datetime(div(b, 1_000*1_000))
        {high_y, high_m, high_d, low_y, low_m, low_d, -1}
    end
  end

end
