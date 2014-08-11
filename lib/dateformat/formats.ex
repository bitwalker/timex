defmodule Timex.DateFormat.Formats do
  @moduledoc """
  This module defines all known (by timex) common date/time formats, in macro form.

  Each format is returned as the following structure:

    [tokenizer: <module this format string will be tokenized with (expects a tokenize/1 def)>,
     format:    <format as a (binary) string value>]

  These formats are consumed by the datetime string parsers, by first tokenizing the chosen
  format, then parsing the datetime string using those tokens.
  """
  alias Timex.Parsers.DateFormat.Tokenizers.Default

  # For now, all preformatted strings will be tokenized using the Default tokenizer.
  @tokenizer {:tokenizer, Default}

  @doc """
  ISO 8601 date/time format with timezone information.
  Example: `2007-08-13T16:48:01 +0300`
  """
  defmacro iso_8601 do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{ISOdate}T{ISOtime}{Z}"]
    end
  end
  @doc """
  ISO 8601 date/time format, assumes UTC/Zulu timezone.
  Example: `2007-08-13T13:48:01Z`
  """
  defmacro iso_8601z do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{ISOdate}T{ISOtime}Z"]
    end
  end
  @doc """
  ISO-standardized year/month/day format.
  Example: `2013-02-29`
  """
  defmacro iso_date do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{YYYY}-{0M}-{0D}"]
    end
  end
  @doc """
  ISO-standardized hour/minute/second format.
  Example: `23:05:45`
  """
  defmacro iso_time do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{0h24}:{0m}:{0s}"]
    end
  end
  @doc """
  ISO year, followed by ISO week number
  Example: `2007-W09`
  """
  defmacro iso_week do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{YYYY}-W{Wiso}"]
    end
  end
  @doc """
  ISO year, followed by ISO week number, and ISO week day number
  Example: `2007-W09-1`
  """
  defmacro iso_weekday do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{YYYY}-W{Wiso}-{WDmon}"]
    end
  end
  @doc """
  ISO year, followed by ISO ordinal day
  Example: `2007-113`
  """
  defmacro iso_ordinal do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{YYYY}-{Dord}"]
    end
  end
  @doc """
  RFC 1123 date/time format with timezone information.
  Example: `Tue, 05 Mar 2013 23:25:19 GMT`
  """
  defmacro rfc_1123 do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{WDshort}, {0D} {Mshort} {YYYY} {ISOtime} {Zname}"]
    end
  end
  @doc """
  RFC 1123 date/time format, assumes UTC/Zulu timezone.
  Example: `Tue, 05 Mar 2013 23:25:19 +0200`
  """
  defmacro rfc_1123z do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{WDshort}, {0D} {Mshort} {YYYY} {ISOtime} {Z}"]
    end
  end
  @doc """
  RFC 3339 date/time format with timezone information.
  Example: `2013-03-05T23:25:19+02:00`
  """
  defmacro rfc_3339 do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{ISOdate}T{ISOtime}{Z:}"]
    end
  end
  @doc """
  RFC 3339 date/time format, assumes UTC/Zulu timezone.
  Example: `2013-03-05T23:25:19Z`
  """
  defmacro rfc_3339z do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{ISOdate}T{ISOtime}Z"]
    end
  end
  @doc """
  ANSI C standard date/time format.
  Example: `Tue Mar  5 23:25:19 2013`
  """
  defmacro ansic do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{WDshort} {Mshort} {_D} {ISOtime} {YYYY}"]
    end
  end
  @doc """
  UNIX standard date/time format.
  Example: `Tue Mar  5 23:25:19 PST 2013`
  """
  defmacro unix do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{WDshort} {Mshort} {_D} {ISOtime} {Zname} {YYYY}"]
    end
  end
  @doc """
  Kitchen clock time format.
  Example: `3:25PM`
  """
  defmacro kitchen do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{h12}:{0m}{AM}"]
    end
  end
end