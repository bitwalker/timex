defmodule Timex.Format.Time.Formatter do
  @moduledoc """
  This module defines the behaviour for custom Time formatters
  """
  use Behaviour
  use Timex
  import Timex.Macros
  alias Timex.Translator
  alias Timex.Format.Time.Formatters.Default
  alias Timex.Format.Time.Formatters.Humanized

  defmacro __using__(_) do
    quote do
      alias Timex.Time
      @behaviour Timex.Format.Time.Formatter
    end
  end

  defcallback format(timestamp :: Types.timestamp) :: String.t | {:error, term}
  defcallback lformat(timestamp :: Types.timestamp, locale :: String.t) :: String.t | {:error, term}

  @doc """
  Formats a Time tuple/Erlang timestamp, as a string, using the provided
  formatter. If a formatter is not provided, the formatter used is
  `Timex.Format.Time.Formatters.Default`. As a handy shortcut, you can reference
  the other built-in formatter (Humanized) via the :humanized atom as shown below.

  # Examples

      iex> #{__MODULE__}.format({1435, 180354, 590264})
      "P45Y6M5DT21H12M34.590264S"
  """
  @spec format(Types.timestamp) :: String.t | {:error, term}
  def format(timestamp), do: lformat(timestamp, Translator.default_locale, Default)

  @doc """
  Same as format/1, but takes a formatter name as an argument

  ## Examples

    iex> #{__MODULE__}.format({1435, 180354, 590264}, :humanized)
    "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds"
  """
  @spec format(Types.timestamp, atom) :: String.t | {:error, term}
  def format(timestamp, formatter), do: lformat(timestamp, Translator.default_locale, formatter)

  @doc """
  Same as format/1, but takes a locale name as an argument, and translates the format string,
  if the locale has translations.
  """
  @spec lformat(Types.timestamp, String.t) :: String.t | {:error, term}
  def lformat(timestamp, locale), do: lformat(timestamp, locale, Default)

  @doc """
  Same as lformat/2, but takes a formatter as an argument
  """
  @spec lformat(Types.timestamp, String.t, atom) :: String.t | {:error, term}
  def lformat({mega,s,micro} = timestamp, locale, formatter)
    when is_timestamp(mega,s,micro) and is_binary(locale) and is_atom(formatter) do
      case formatter do
        :humanized -> Humanized.lformat(timestamp, locale)
        _          -> formatter.lformat(timestamp, locale)
      end
  end
  def lformat(_, _, _), do: {:error, :invalid_timestamp}

end
