defmodule Timex.TimeFormatter do
  @moduledoc """
  Handles formatting timestamp values as human readable strings.
  For formatting timestamps as points in time rather than intervals,
  use `DateFormat`
  """
  alias Timex.Time

  @minute 60
  @hour   @minute * 60
  @day    @hour * 24
  @week   @day * 7
  @month  @day * 30
  @year   @day * 365

  @doc """
  Return a human readable string representing the time interval.

  # Example

    iex> {1435, 180354, 590264} |> TimeFormatter.format
    "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds"


  """
  @spec format(Date.timestamp) :: String.t
  def format({_,_,_} = timestamp), do: timestamp |> deconstruct |> do_format

  defp do_format(components), do: do_format(components, <<>>)
  defp do_format([], str),    do: str
  defp do_format([{unit, value}|rest], str) do
    case str do
      <<>> -> do_format(rest, "#{value} #{Atom.to_string(unit)}")
      _    -> do_format(rest, str <> ", #{value} #{Atom.to_string(unit)}")
    end
  end

  defp deconstruct({_, _, _} = ts), do: deconstruct(ts |> Time.to_secs |> trunc, [])
  defp deconstruct(seconds, components) when seconds > 0 do
    cond do
      seconds >= @year  -> deconstruct(rem(seconds, @year), [{:years, div(seconds, @year)} | components])
      seconds >= @month -> deconstruct(rem(seconds, @month), [{:months, div(seconds, @month)} | components])
      seconds >= @week  -> deconstruct(rem(seconds, @week), [{:weeks, div(seconds, @week)} | components])
      seconds >= @day   -> deconstruct(rem(seconds, @day), [{:days, div(seconds, @day)} | components])
      seconds >= @hour  -> deconstruct(rem(seconds, @hour), [{:hours, div(seconds, @hour)} | components])
      seconds >= @minute -> deconstruct(rem(seconds, @minute), [{:minutes, div(seconds, @minute)} | components])
      true -> deconstruct(0, [{:seconds, seconds} | components])
    end
  end
  defp deconstruct(seconds, components) when seconds < 0, do: deconstruct(seconds * -1, components)
  defp deconstruct(0, components), do: components |> Enum.reverse
end
