defmodule Timex.Format.Time.Formatters.Humanized do
  @moduledoc """
  Handles formatting timestamp values as human readable strings.
  For formatting timestamps as points in time rather than intervals,
  use `DateFormat`
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
      "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds"
      iex> {0, 65, 0} |> #{__MODULE__}.format
      "1 minutes, 5 seconds"

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

  defp deconstruct({_, _, micro} = ts), do: deconstruct({ts |> Time.to_secs |> trunc, micro}, [])
  defp deconstruct({0, 0}, components), do: components |> Enum.reverse
  defp deconstruct({seconds, us}, components) when seconds > 0 do
    cond do
      seconds >= @year   -> deconstruct({rem(seconds, @year), us}, [{:years, div(seconds, @year)} | components])
      seconds >= @month  -> deconstruct({rem(seconds, @month), us}, [{:months, div(seconds, @month)} | components])
      seconds >= @week   -> deconstruct({rem(seconds, @week), us}, [{:weeks, div(seconds, @week)} | components])
      seconds >= @day    -> deconstruct({rem(seconds, @day), us}, [{:days, div(seconds, @day)} | components])
      seconds >= @hour   -> deconstruct({rem(seconds, @hour), us}, [{:hours, div(seconds, @hour)} | components])
      seconds >= @minute -> deconstruct({rem(seconds, @minute), us}, [{:minutes, div(seconds, @minute)} | components])
      true -> deconstruct({0, us}, [{:seconds, seconds} | components])
    end
  end
  defp deconstruct({seconds, micro}, components) when seconds < 0, do: deconstruct({seconds * -1, micro}, components)
  defp deconstruct({0, micro}, components) when micro > 0 do
    msecs = {0, 0, micro} |> Time.abs |> Time.to_msecs
    cond do
      msecs >= 1.0 -> deconstruct({0, 0}, [{:milliseconds, msecs} | components])
      true         -> deconstruct({0, 0}, [{:microseconds, micro} | components])
    end
  end
end
