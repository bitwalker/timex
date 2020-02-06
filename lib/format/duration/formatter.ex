defmodule Timex.Format.Duration.Formatter do
  @moduledoc """
  This module defines the behaviour for custom Time formatters
  """
  use Timex
  alias Timex.Translator
  alias Timex.Duration
  alias Timex.Format.Duration.Formatters.Default
  alias Timex.Format.Duration.Formatters.Humanized

  defmacro __using__(_) do
    quote do
      alias Timex.Duration
      @behaviour Timex.Format.Duration.Formatter
    end
  end

  @callback format(Duration.t()) :: String.t() | {:error, term}
  @callback lformat(Duration.t(), locale :: String.t()) :: String.t() | {:error, term}

  @doc """
  Formats a Duration as a string, using the provided
  formatter. If a formatter is not provided, the formatter used is
  `Timex.Format.Duration.Formatters.Default`. As a handy shortcut, you can reference
  the other built-in formatter (Humanized) via the :humanized atom as shown below.

  # Examples

      iex> d = Timex.Duration.from_erl({1435, 180354, 590264})
      ...> #{__MODULE__}.format(d)
      "P45Y6M5DT21H12M34.590264S"
  """
  @spec format(Duration.t()) :: String.t() | {:error, term}
  def format(duration), do: lformat(duration, Translator.current_locale(), Default)

  @doc """
  Same as format/1, but takes a formatter name as an argument

  ## Examples

      iex> d = Timex.Duration.from_erl({1435, 180354, 590264})
      ...> #{__MODULE__}.format(d, :humanized)
      "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds"
  """
  @spec format(Duration.t(), atom) :: String.t() | {:error, term}
  def format(duration, formatter), do: lformat(duration, Translator.current_locale(), formatter)

  @doc """
  Same as format/1, but takes a locale name as an argument, and translates the format string,
  if the locale has translations.
  """
  @spec lformat(Duration.t(), String.t()) :: String.t() | {:error, term}
  def lformat(duration, locale), do: lformat(duration, locale, Default)

  @doc """
  Same as lformat/2, but takes a formatter as an argument
  """
  @spec lformat(Duration.t(), String.t(), atom) :: String.t() | {:error, term}
  def lformat(%Duration{} = duration, locale, formatter)
      when is_binary(locale) and is_atom(formatter) do
    case formatter do
      :humanized -> Humanized.lformat(duration, locale)
      _ -> formatter.lformat(duration, locale)
    end
  end

  def lformat(_, _, _), do: {:error, :invalid_duration}
end
