defmodule Timex.Comparable.Diff do
  @moduledoc false

  alias Timex.Types
  alias Timex.Duration
  alias Timex.Comparable

  @spec diff(Types.microseconds(), Types.microseconds(), Comparable.granularity()) :: integer
  @spec diff(Types.valid_datetime(), Types.valid_datetime(), Comparable.granularity()) :: integer
  def diff(a, b, granularity) when is_integer(a) and is_integer(b) and is_atom(granularity) do
    do_diff(a, b, granularity)
  end

  def diff(a, b, granularity) do
    case {Timex.to_gregorian_microseconds(a), Timex.to_gregorian_microseconds(b)} do
      {{:error, _} = err, _} -> err
      {_, {:error, _} = err} -> err
      {au, bu} when is_integer(au) and is_integer(bu) -> diff(au, bu, granularity)
    end
  end

  defp do_diff(a, b, :duration), do: Duration.from_seconds(do_diff(a, b, :seconds))
  defp do_diff(a, b, :microseconds), do: do_diff(a, b, :microsecond)
  defp do_diff(a, b, :microsecond), do: a - b
  defp do_diff(a, b, :milliseconds), do: do_diff(a, b, :millisecond)
  defp do_diff(a, b, :millisecond), do: div(a - b, 1_000)
  defp do_diff(a, b, :seconds), do: do_diff(a, b, :second)
  defp do_diff(a, b, :second), do: div(a - b, 1_000 * 1_000)
  defp do_diff(a, b, :minutes), do: do_diff(a, b, :minute)
  defp do_diff(a, b, :minute), do: div(a - b, 1_000 * 1_000 * 60)
  defp do_diff(a, b, :hours), do: do_diff(a, b, :hour)
  defp do_diff(a, b, :hour), do: div(a - b, 1_000 * 1_000 * 60 * 60)
  defp do_diff(a, b, :days), do: do_diff(a, b, :day)
  defp do_diff(a, b, :day), do: div(a - b, 1_000 * 1_000 * 60 * 60 * 24)
  defp do_diff(a, b, :weeks), do: do_diff(a, b, :week)
  defp do_diff(a, b, :week), do: div(a - b, 1_000 * 1_000 * 60 * 60 * 24 * 7)
  defp do_diff(a, b, :calendar_weeks), do: do_diff(a, b, :calendar_week)

  defp do_diff(a, b, :calendar_week) do
    adate = :calendar.gregorian_seconds_to_datetime(div(a, 1_000 * 1_000))
    bdate = :calendar.gregorian_seconds_to_datetime(div(b, 1_000 * 1_000))

    days =
      cond do
        a > b ->
          ending = Timex.end_of_week(adate)
          start = Timex.beginning_of_week(bdate)
          endu = Timex.to_gregorian_microseconds(ending)
          startu = Timex.to_gregorian_microseconds(start)
          do_diff(endu, startu, :days)

        :else ->
          ending = Timex.end_of_week(bdate)
          start = Timex.beginning_of_week(adate)
          endu = Timex.to_gregorian_microseconds(ending)
          startu = Timex.to_gregorian_microseconds(start)
          do_diff(startu, endu, :days)
      end

    cond do
      days >= 0 && rem(days, 7) != 0 -> div(days, 7) + 1
      days <= 0 && rem(days, 7) != 0 -> div(days, 7) - 1
      :else -> div(days, 7)
    end
  end

  defp do_diff(a, b, :months), do: do_diff(a, b, :month)

  defp do_diff(a, b, :month) do
    diff_months(a, b)
  end

  defp do_diff(a, b, :years), do: do_diff(a, b, :year)

  defp do_diff(a, b, :year) do
    diff_years(a, b)
  end

  defp do_diff(_, _, granularity), do: {:error, {:invalid_granularity, granularity}}

  defp diff_years(a, b) do
    {start_date, _} = :calendar.gregorian_seconds_to_datetime(div(a, 1_000 * 1_000))
    {end_date, _} = :calendar.gregorian_seconds_to_datetime(div(b, 1_000 * 1_000))

    if a > b do
      diff_years(end_date, start_date, 0)
    else
      diff_years(start_date, end_date, 0) * -1
    end
  end

  defp diff_years({y, _, _}, {y, _, _}, acc) do
    acc
  end

  defp diff_years({y1, m, d}, {y2, _, _} = ed, acc) when y1 < y2 do
    sd2 = {y1 + 1, m, d}

    if :calendar.valid_date(sd2) do
      sd2_secs = :calendar.datetime_to_gregorian_seconds({sd2, {0, 0, 0}})
      ed_secs = :calendar.datetime_to_gregorian_seconds({ed, {0, 0, 0}})

      if sd2_secs <= ed_secs do
        diff_years(sd2, ed, acc + 1)
      else
        acc
      end
    else
      # This date is a leap day, so subtract a day and try again
      diff_years({y1, m, d - 1}, ed, acc)
    end
  end

  defp diff_months(a, a), do: 0

  defp diff_months(a, b) do
    {start_date, _} = :calendar.gregorian_seconds_to_datetime(div(a, 1_000 * 1_000))
    {end_date, _} = :calendar.gregorian_seconds_to_datetime(div(b, 1_000 * 1_000))
    do_diff_months(start_date, end_date)
  end

  defp do_diff_months({y1, m1, d1}, {y2, m2, d2}) do
    months = (y1 - y2) * 12 + m1 - m2
    days_in_month2 = Timex.days_in_month(y2, m2)

    cond do
      months < 0 && d2 < d1 && (days_in_month2 >= d1 || days_in_month2 != d2) ->
        months + 1

      months > 0 && d2 > d1 ->
        months - 1

      true ->
        months
    end
  end
end
