defmodule Timex.Format.Time.Formatter do
  @moduledoc """
  This module defines the behaviour for custom Time formatters
  """
  use Behaviour
  use Timex
  import Timex.Macros
  alias Timex.Format.Time.Formatters.Default
  alias Timex.Format.Time.Formatters.Humanized

  defmacro __using__(_) do
    quote do
      alias Timex.Time
      @behaviour Timex.Format.Time.Formatter
    end
  end

  defcallback format(timestamp :: Types.timestamp) :: String.t | {:error, term}

  @doc """
  Formats a Time tuple/Erlang timestamp, as a string, using the provided
  formatter. If a formatter is not provided, the formatter used is
  `Timex.Format.Time.Formatters.Default`. As a handy shortcut, you can reference
  the other built-in formatter (Humanized) via the :humanized atom as shown below.

  # Examples

      iex> #{__MODULE__}.format({1435, 180354, 590264})
      "P45Y6M5DT21H12M34.590264S"
      iex> #{__MODULE__}.format({1435, 180354, 590264}, :humanized)
      "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds"
  """
  @spec format(Types.timestamp, atom) :: String.t | {:error, term}
  def format(timestamp, formatter \\ Default)

  def format({mega,s,micro} = timestamp, formatter) when is_timestamp(mega,s,micro) and is_atom(formatter) do
    case formatter do
      :humanized -> Humanized.format(timestamp)
      _          -> formatter.format(timestamp)
    end
  end
  def format(_, _), do: {:error, :invalid_timestamp}
end
