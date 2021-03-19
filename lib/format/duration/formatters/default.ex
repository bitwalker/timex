defmodule Timex.Format.Duration.Formatters.Default do
  @moduledoc """
  Handles formatting Duration values as ISO 8601 durations as described below.

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
  use Timex.Format.Duration.Formatter
  alias Timex.Translator

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @month @day * 30
  @year @day * 365

  @microsecond 1_000_000

  @doc """
  Return a human readable string representing the absolute value of duration (i.e. would
  return the same output for both negative and positive representations of a given duration)

  ## Examples

      iex> use Timex
      ...> Duration.from_erl({0, 1, 1_000_000}) |> #{__MODULE__}.format
      "PT2S"

      iex> use Timex
      ...> Duration.from_erl({0, 1, 1_000_100}) |> #{__MODULE__}.format
      "PT2.0001S"

      iex> use Timex
      ...> Duration.from_erl({0, 65, 0}) |> #{__MODULE__}.format
      "PT1M5S"

      iex> use Timex
      ...> Duration.from_erl({0, -65, 0}) |> #{__MODULE__}.format
      "PT1M5S"

      iex> use Timex
      ...> Duration.from_erl({1435, 180354, 590264}) |> #{__MODULE__}.format
      "P45Y6M5DT21H12M34.590264S"

      iex> use Timex
      ...> Duration.from_erl({0, 0, 0}) |> #{__MODULE__}.format
      "PT0S"

  """
  @spec format(Duration.t()) :: String.t() | {:error, term}
  def format(%Duration{} = duration), do: lformat(duration, Translator.current_locale())
  def format(_), do: {:error, :invalid_timestamp}

  def lformat(%Duration{} = duration, _locale) do
    duration
    |> deconstruct
    |> do_format
  end

  def lformat(_, _locale), do: {:error, :invalid_duration}

  defp do_format(components), do: do_format(components, <<?P>>)
  defp do_format([], "P"), do: "PT0S"
  defp do_format([], str), do: str

  defp do_format([{unit, _} = component | rest], str) do
    cond do
      unit in [:hours, :minutes, :seconds] && String.contains?(str, "T") ->
        do_format(rest, format_component(component, str))

      unit in [:hours, :minutes, :seconds] ->
        do_format(rest, format_component(component, str <> "T"))

      true ->
        do_format(rest, format_component(component, str))
    end
  end

  defp format_component({_, 0}, str), do: str
  defp format_component({:years, y}, str), do: str <> "#{y}Y"
  defp format_component({:months, m}, str), do: str <> "#{m}M"
  defp format_component({:days, d}, str), do: str <> "#{d}D"
  defp format_component({:hours, h}, str), do: str <> "#{h}H"
  defp format_component({:minutes, m}, str), do: str <> "#{m}M"
  defp format_component({:seconds, s}, str), do: str <> "#{s}S"

  defp deconstruct(duration) do
    micros = Duration.to_microseconds(duration) |> abs
    deconstruct({div(micros, @microsecond), rem(micros, @microsecond)}, [])
  end

  defp deconstruct({0, 0}, components),
    do: Enum.reverse(components)

  defp deconstruct({seconds, us}, components) do
    cond do
      seconds >= @year ->
        deconstruct({rem(seconds, @year), us}, [{:years, div(seconds, @year)} | components])

      seconds >= @month ->
        deconstruct({rem(seconds, @month), us}, [{:months, div(seconds, @month)} | components])

      seconds >= @day ->
        deconstruct({rem(seconds, @day), us}, [{:days, div(seconds, @day)} | components])

      seconds >= @hour ->
        deconstruct({rem(seconds, @hour), us}, [{:hours, div(seconds, @hour)} | components])

      seconds >= @minute ->
        deconstruct({rem(seconds, @minute), us}, [{:minutes, div(seconds, @minute)} | components])

      true ->
        get_fractional_seconds(seconds, us, components)
    end
  end

  defp get_fractional_seconds(seconds, 0, components),
    do: deconstruct({0, 0}, [{:seconds, seconds} | components])

  defp get_fractional_seconds(seconds, micro, components) do
    millis =
      micro
      |> Duration.from_microseconds()
      |> Duration.to_milliseconds()

    cond do
      millis >= 1.0 ->
        deconstruct({0, 0}, [{:seconds, seconds + millis * :math.pow(10, -3)} | components])

      true ->
        deconstruct({0, 0}, [{:seconds, seconds + micro * :math.pow(10, -6)} | components])
    end
  end
end
