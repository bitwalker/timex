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
  alias Timex.Parsers.DateFormat.Tokenizers.Strftime

  # For now, all preformatted strings will be tokenized using the Default tokenizer.
  @tokenizer {:tokenizer, Default}
  @strftime  {:tokenizer, Strftime}

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
      [tokenizer, format: "{000YYYY}-{0M}-{0D}"]
    end
  end
  @doc """
  ISO-standardized hour/minute/second format.
  Example: `23:05:45`
  """
  defmacro iso_time do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{0h24}:{0m}:{0s}{ss}"]
    end
  end
  @doc """
  ISO year, followed by ISO week number
  Example: `2007-W09`
  """
  defmacro iso_week do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{000YYYY}-W{Wiso}"]
    end
  end
  @doc """
  ISO year, followed by ISO week number, and ISO week day number
  Example: `2007-W09-1`
  """
  defmacro iso_weekday do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{000YYYY}-W{Wiso}-{WDmon}"]
    end
  end
  @doc """
  ISO year, followed by ISO ordinal day
  Example: `2007-113`
  """
  defmacro iso_ordinal do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{000YYYY}-{Dord}"]
    end
  end
  @doc """
  RFC 822 date/time format with timezone information.
  Examples: `Mon, 05 Jun 14 23:20:59 Y`

  ## From the specification (RE: timezones):

  Time zone may be indicated in several ways.  "UT" is Univer-
  sal  Time  (formerly called "Greenwich Mean Time"); "GMT" is per-
  mitted as a reference to Universal Time.  The  military  standard
  uses  a  single  character for each zone.  "Z" is Universal Time.
  "A" indicates one hour earlier, and "M" indicates 12  hours  ear-
  lier;  "N"  is  one  hour  later, and "Y" is 12 hours later.  The
  letter "J" is not used.  The other remaining two forms are  taken
  from ANSI standard X3.51-1975.  One allows explicit indication of
  the amount of offset from UT; the other uses  common  3-character
  strings for indicating time zones in North America.
  """
  defmacro rfc_822 do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{WDshort}, {0D} {Mshort} {YY} {ISOtime} {Zname}"]
    end
  end
  @doc """
  Same as `rfc_822`, but locked to universal time.
  """
  defmacro rfc_822z do
    quote bind_quoted: [tokenizer: @tokenizer] do
      [tokenizer, format: "{WDshort}, {0D} {Mshort} {YY} {ISOtime} UT"]
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
  @doc """
  Month, day, and year, in slashed style.
  Example: `04/12/1987`
  """
  defmacro slashed_date do
    quote bind_quoted: [tokenizer: @strftime] do
      [tokenizer, format: "%m/%d/%y"]
    end
  end
  @doc """
  ISO date, in strftime format.
  Example: `1987-04-12`
  """
  defmacro strftime_iso_date do
    quote bind_quoted: [tokenizer: @strftime] do
      [tokenizer, format: "%Y-%m-%d"]
    end
  end
  @doc """
  Wall clock in strftime format.
  Example: `23:30`
  """
  defmacro strftime_clock do
    quote bind_quoted: [tokenizer: @strftime] do
      [tokenizer, format: "%H:%M"]
    end
  end
  @doc """
  Kitchen clock in strftime format.
  Example: `4:30:01 PM`
  """
  defmacro strftime_kitchen do
    quote bind_quoted: [tokenizer: @strftime] do
      [tokenizer, format: "%I:%M:%S %p"]
    end
  end
  @doc """
  Friendly short date format. Uses spaces for padding on the day.
  Example: ` 5-Jan-2014`
  """
  defmacro strftime_shortdate do
    quote bind_quoted: [tokenizer: @strftime] do
      [tokenizer, format: "%e-%b-%Y"]
    end
  end
end