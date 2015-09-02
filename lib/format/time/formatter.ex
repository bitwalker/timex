defmodule Timex.Format.Time.Formatter do
  use Behaviour
  use Timex
  alias Timex.Format.Time.Formatters.Default
  alias Timex.Format.Time.Formatters.Humanized

  defmacro __using__(_) do
    quote do
      alias Timex.Time
      alias Timex.Date
      @behaviour Timex.Format.Time.Formatter
    end
  end

  defcallback format(timestamp :: Date.timestamp) :: String.t

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
  @spec format(Date.timestamp, atom) :: String.t
  def format(timestamp, formatter \\ Default) when is_atom(formatter) do
    case formatter do
      :humanized -> Humanized.format(timestamp)
      _          -> formatter.format(timestamp)
    end
  end
end
