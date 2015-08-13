defmodule Timex.Format.Time.Formatters.Default do
  @moduledoc """
  Handles formatting timestamp values as ISO 8601 durations as described below.

  Durations are represented by the format P[n]Y[n]M[n]DT[n]H[n]M[n]S.
  In this representation, the [n] is replaced by the value for each of the
  date and time elements that follow the [n]. Leading zeros are not required,
  but the maximum number of digits for each element should be agreed to by the
  communicating parties. The capital letters P, Y, M, W, D, T, H, M, and S are
  designators for each of the date and time elements and are not replaced.

  - P is the duration designator (historically called "period") placed at the start of the duration representation.
  - Y is the year designator that follows the value for the number of years.
  - M is the month designator that follows the value for the number of months.
  - D is the day designator that follows the value for the number of days.
  - T is the time designator that precedes the time components of the representation.
  - H is the hour designator that follows the value for the number of hours.
  - M is the minute designator that follows the value for the number of minutes.
  - S is the second designator that follows the value for the number of seconds.
  """
  use Timex.Format.Time.Formatter

  @minute 60
  @hour   @minute * 60
  @day    @hour * 24
  @week   @day * 7
  @month  @day * 30
  @year   @day * 365

  @doc """
  Return a human readable string representing the time interval.

  ## Examples

      iex> {1435, 180354, 590264} |> #{__MODULE__}.format
      "P45Y6M5DT21H12M34.590264S"
      iex> {0, 65, 0} |> #{__MODULE__}.format
      "PT1M5S"

  """
  @spec format(Date.timestamp) :: String.t
  def format({_,_,_} = timestamp), do: timestamp |> deconstruct |> do_format

  defp do_format(components), do: do_format(components, <<?P>>)
  defp do_format([], str),    do: str
  defp do_format([{unit,_} = component|rest], str) do
    cond do
      unit in [:hours, :minutes, :seconds] && String.contains?(str, "T") ->
        do_format(rest, format_component(component, str))
      unit in [:hours, :minutes, :seconds] ->
        do_format(rest, format_component(component, str <> "T"))
      true ->
        do_format(rest, format_component(component, str))
    end
  end
  defp format_component({_, 0}, str),        do: str
  defp format_component({:years, y}, str),   do: str <> "#{y}Y"
  defp format_component({:months, m}, str),  do: str <> "#{m}M"
  defp format_component({:days, d}, str),    do: str <> "#{d}D"
  defp format_component({:hours, h}, str),   do: str <> "#{h}H"
  defp format_component({:minutes, m}, str), do: str <> "#{m}M"
  defp format_component({:seconds, s}, str), do: str <> "#{s}S"

  defp deconstruct({_, _, micro} = ts), do: deconstruct({ts |> Time.to_secs |> trunc, micro}, [])
  defp deconstruct({0, 0}, components), do: components |> Enum.reverse
  defp deconstruct({seconds, us}, components) when seconds > 0 do
    cond do
      seconds >= @year   -> deconstruct({rem(seconds, @year), us}, [{:years, div(seconds, @year)} | components])
      seconds >= @month  -> deconstruct({rem(seconds, @month), us}, [{:months, div(seconds, @month)} | components])
      seconds >= @day    -> deconstruct({rem(seconds, @day), us}, [{:days, div(seconds, @day)} | components])
      seconds >= @hour   -> deconstruct({rem(seconds, @hour), us}, [{:hours, div(seconds, @hour)} | components])
      seconds >= @minute -> deconstruct({rem(seconds, @minute), us}, [{:minutes, div(seconds, @minute)} | components])
      true -> get_fractional_seconds(seconds, us, components)
    end
  end
  defp deconstruct({seconds, us}, components) do
    get_fractional_seconds(seconds, us, components)
  end
  defp get_fractional_seconds(seconds, 0, components), do: deconstruct({0, 0}, [{:seconds, seconds} | components])
  defp get_fractional_seconds(seconds, micro, components) when micro > 0 do
    msecs = {0, 0, micro} |> Time.abs |> Time.to_msecs
    cond do
      msecs >= 1.0 -> deconstruct({0, 0}, [{:seconds, seconds + (msecs * :math.pow(10, -3))} | components])
      true         -> deconstruct({0, 0}, [{:seconds, seconds + (micro * :math.pow(10, -6))} | components])
    end
  end
end
