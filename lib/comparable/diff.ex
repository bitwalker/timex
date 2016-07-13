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
    {ly,lm,ld,ey,em,ed,sign} = cond do
      a > b ->
        {{ly,lm,ld},_} = :calendar.gregorian_seconds_to_datetime(div(a, 1_000*1_000))
        {{ey,em,ed},_} = :calendar.gregorian_seconds_to_datetime(div(b, 1_000*1_000))
        {ly,lm,ld,ey,em,ed,1}
      :else ->
        {{ey,em,ed},_} = :calendar.gregorian_seconds_to_datetime(div(a, 1_000*1_000))
        {{ly,lm,ld},_} = :calendar.gregorian_seconds_to_datetime(div(b, 1_000*1_000))
        {ly,lm,ld,ey,em,ed,-1}
    end
    x = cond do
      ld >= ed -> 0
      :else -> -1
    end
    y = ly - ey
    z = lm - em
    (x+y*12+z)*sign
  end
  defp do_diff(a, b, :years) do
    div(do_diff(a, b, :months), 12)
  end
  defp do_diff(_, _, granularity) when not granularity in @units,
    do: {:error, {:invalid_granularity, granularity}}

  defp zero(:duration), do: Duration.zero
  defp zero(_type), do: 0

end
