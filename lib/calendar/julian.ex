defmodule Timex.Calendar.Julian do
  @moduledoc """
  This module contains functions for working with dates in the Julian calendar.
  """
  require Bitwise
  import Timex.Macros
  alias Timex.Types

  @doc """
  Returns the Julian day number for the given Erlang date (gregorian)

  The Julian date (JD) is a continuous count of days from 1 January 4713 BC (= -4712 January 1),
  Greenwich mean noon (= 12h UT). For example, AD 1978 January 1, 0h UT is JD 2443509.5
  and AD 1978 July 21, 15h UT, is JD 2443711.125.

  This algorithm assumes a proleptic Gregorian calendar (i.e. dates back to year 0),
  unlike the NASA or US Naval Observatory algorithm - however they align perfectly
  for dates back to October 15th, 1582, which is where it starts to differ, which is
  due to the fact that their algorithm assumes there is no Gregorian calendar before that
  date.
  """
  @spec julian_date(Types.date()) :: integer
  def julian_date({year, month, day}),
    do: julian_date(year, month, day)

  # Same as julian_date/1, except takes an Erlang datetime, and returns a more precise Julian date number
  @spec julian_date(Types.datetime()) :: integer
  def julian_date({{year, month, day}, {hour, minute, second}}) do
    julian_date(year, month, day, hour, minute, second)
  end

  def julian_date(_), do: {:error, :invalid_date}

  @doc """
  Same as julian_date/1, except takes year/month/day as distinct arguments
  """
  @spec julian_date(Types.year(), Types.month(), Types.day()) :: integer
  def julian_date(year, month, day) when is_date(year, month, day) do
    a = div(14 - month, 12)
    y = year + 4800 - a
    m = month + 12 * a - 3

    jdn =
      day + trunc((153 * m + 2) / 5) +
        365 * y +
        div(y, 4) - div(y, 100) + div(y, 400) -
        32045

    jdn
  end

  def julian_date(_, _, _), do: {:error, :invalid_date}

  @doc """
  Same as julian_date/1, except takes year/month/day/hour/minute/second as distinct arguments
  """
  @spec julian_date(
          Types.year(),
          Types.month(),
          Types.day(),
          Types.hour(),
          Types.minute(),
          Types.second()
        ) :: float
  def julian_date(year, month, day, hour, minute, second)
      when is_datetime(year, month, day, hour, minute, second) do
    jdn = julian_date(year, month, day)
    jdn + (hour - 12) / 24 + minute / 1440 + second / 86400
  end

  def julian_date(_, _, _, _, _, _), do: {:error, :invalid_datetime}

  @doc """
  Given a Julian day of year, and a year, this function returns the
  `Date` which that day falls on.

  If no options are provided, leap days are disregarded, and the valid range for
  the day provided is 1-365, i.e. there is no representation
  for Feb 29.

  To allow representing leap days, you may pass `leaps: true`, which in
  turn expands the range of the day provided to 0-365.

  NOTE: This is internally used for POSIX-TZ support, but may be useful
  to others, so it is being made public.
  """
  def date_for_day_of_year(day, year, opts \\ [])
      when is_integer(day) and day >= 0 and day <= 365 do
    leaps? = Keyword.get(opts, :leaps, false)

    day = if leaps?, do: day + 1, else: day

    days =
      if leaps? and :calendar.is_leap_year(year) do
        [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
      else
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
      end

    {month, day} =
      Enum.reduce_while(days, {1, 0}, fn eom, {last_month, jd} ->
        next = eom + jd

        cond do
          day > next ->
            {:cont, {last_month + 1, next}}

          day == next ->
            {:halt, {last_month, eom}}

          day < next ->
            {:halt, {last_month, day - jd}}
        end
      end)

    Timex.Date.new!(year, month, day)
  end

  @doc """
  Returns the day of the week, starting with 0 for Sunday, or 1 for Monday
  """
  @spec day_of_week(Types.date(), :sun | :mon) :: Types.weekday()
  def day_of_week({year, month, day}, weekstart),
    do: day_of_week(year, month, day, weekstart)

  @doc """
  Same as day_of_week/1, except takes year/month/day as distinct arguments
  """
  @spec day_of_week(Types.year(), Types.month(), Types.day(), :sun | :mon) :: Types.weekday()
  def day_of_week(year, month, day, weekstart)
      when is_date(year, month, day) and weekstart in [:sun, :mon] do
    cardinal = mod(trunc(julian_date(year, month, day)) + 1, 7)

    case weekstart do
      :sun -> cardinal
      :mon -> mod(cardinal + 6, 7) + 1
    end
  end

  def day_of_week(_, _, _, weekstart) do
    case weekstart in [:sun, :mon] do
      true -> {:error, :invalid_date}
      false -> {:error, {:bad_weekstart_value, expected: [:sun, :mon], got: weekstart}}
    end
  end

  defp mod(a, b), do: rem(rem(a, b) + b, b)
end
