defmodule Timex.Format.DateTime.Formatter do
  @moduledoc """
  This module defines the behaviour for custom DateTime formatters.
  """
  use Behaviour

  alias Timex.Date
  alias Timex.DateTime
  alias Timex.Time
  alias Timex.Timezone
  alias Timex.Convertable
  alias Timex.Translator
  alias Timex.Format.FormatError
  alias Timex.Format.DateTime.Formatters.Default
  alias Timex.Format.DateTime.Formatters.Strftime
  alias Timex.Format.DateTime.Formatters.Relative
  alias Timex.Parse.DateTime.Tokenizers.Directive

  defcallback tokenize(format_string :: String.t) :: {:ok, [Directive.t]} | {:error, term}
  defcallback format(date :: DateTime.t, format_string :: String.t)  :: {:ok, String.t} | {:error, term}
  defcallback format!(date :: DateTime.t, format_string :: String.t) :: String.t | no_return
  defcallback lformat(date :: DateTime.t, format_string :: String.t, locale :: String.t) :: {:ok, String.t} | {:error, term}
  defcallback lformat!(date :: DateTime.t, format_string :: String.t, locale :: String.t) :: String.t | no_return

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Timex.Format.DateTime.Formatter

      alias Timex.Parse.DateTime.Tokenizers.Directive
      import Timex.Format.DateTime.Formatter, only: [format_token: 5, format_token: 6]
    end
  end

  @doc """
  Formats a Convertable (using to_datetime) as a string, using the provided format string,
  locale, and formatter. If the locale does not have translations, "en" will be used by
  default. If a formatter is not provided, the formatter used is `Timex.Format.DateTime.Formatters.DefaultFormatter`

  If an error is encountered during formatting, `lformat!` will raise
  """
  @spec lformat!(Convertable.t, String.t, String.t, atom | nil) :: String.t | no_return
  def lformat!(date, format_string, locale, formatter \\ Default)

  def lformat!(datetime, format_string, locale, :strftime),
    do: lformat!(datetime, format_string, locale, Strftime)
  def lformat!(datetime, format_string, locale, :relative),
    do: lformat!(datetime, format_string, locale, Relative)
  def lformat!(%DateTime{} = date, format_string, locale, formatter)
    when is_binary(format_string) and is_binary(locale) and is_atom(formatter)
    do
      case lformat(date, format_string, locale, formatter) do
        {:ok, result}    -> result
        {:error, reason} -> raise FormatError, message: reason
      end
  end
  def lformat!(datetime, format_string, locale, formatter)
    when is_binary(format_string) and is_binary(locale) and is_atom(formatter)
    do
    case Convertable.to_datetime(datetime) do
      {:error, reason} ->
        raise "unable to convert datetime value in lformat!/4: #{inspect reason}"
      %DateTime{} = d ->
        lformat!(d, format_string, locale, formatter)
    end
  end
  def lformat!(a,b,c, d),
    do: raise "invalid argument(s) to lformat!/4: #{inspect a}, #{inspect b}, #{inspect c}, #{inspect d}"

  @doc """
  Formats a Convertable (using to_datetime) as a string, using the provided format string,
  locale, and formatter. If the locale provided does not have translations, "en" is used by
  default. If a formatter is not provided, the formatter used is `Timex.Format.DateTime.Formatters.DefaultFormatter`
  """
  @spec lformat(Convertable.t, String.t, String.t, atom | nil) :: {:ok, String.t} | {:error, term}
  def lformat(date, format_string, locale, formatter \\ Default)
  def lformat(datetime, format_string, locale, :strftime),
    do: lformat(datetime, format_string, locale, Strftime)
  def lformat(datetime, format_string, locale, :relative),
    do: lformat(datetime, format_string, locale, Relative)
  def lformat(%DateTime{} = date, format_string, locale, formatter)
    when is_binary(format_string) and is_binary(locale) and is_atom(formatter) do
      formatter.lformat(date, format_string, locale)
  end
  def lformat(datetime, format_string, locale, formatter)
    when is_binary(format_string) and is_binary(locale) and is_atom(formatter)
    do
    case Convertable.to_datetime(datetime) do
      {:error, _} = err -> err
      %DateTime{} = d ->
        lformat(d, format_string, locale, formatter)
    end
  end
  def lformat(_, _, _, _),
    do: {:error, :badarg}


  @doc """
  Formats a Convertable (using to_datetime) as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.Format.DateTime.Formatters.DefaultFormatter`.

  Formatting will use the configured default locale, "en" if no other default is given.

  If an error is encountered during formatting, `format!` will raise.
  """
  @spec format!(Convertable.t, String.t, atom | nil) :: String.t | no_return
  def format!(date, format_string, formatter \\ Default)

  def format!(date, format_string, formatter),
    do: lformat!(date, format_string, Translator.default_locale, formatter)

  @doc """
  Formats a Convertable (using to_datetime) as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.Format.DateTime.Formatters.DefaultFormatter`.

  Formatting will use the configured default locale, "en" if no other default is given.
  """
  @spec format(Convertable.t, String.t, atom | nil) :: {:ok, String.t} | {:error, term}
  def format(date, format_string, formatter \\ Default)

  def format(datetime, format_string, :strftime),
    do: lformat(datetime, format_string, Translator.default_locale, Strftime)
  def format(datetime, format_string, :relative),
    do: lformat(datetime, format_string, Translator.default_locale, Relative)
  def format(datetime, format_string, formatter),
    do: lformat(datetime, format_string, Translator.default_locale, formatter)

  @doc """
  Validates the provided format string, using the provided formatter,
  or if none is provided, the default formatter. Returns `:ok` when valid,
  or `{:error, reason}` if not valid.
  """
  @spec validate(String.t, atom | nil) :: :ok | {:error, term}
  def validate(format_string, formatter \\ Default)
  def validate(format_string, formatter) when is_binary(format_string) and is_atom(formatter) do
    try do
      formatter = case formatter do
                    :strftime -> Strftime
                    :relative -> Relative
                    _         -> formatter
                  end
      case formatter.tokenize(format_string) do
        {:error, _} = error -> error
        {:ok, []} -> {:error, "There were no formatting directives in the provided string."}
        {:ok, directives} when is_list(directives)-> :ok
      end
    rescue
      x -> {:error, x}
    end
  end
  def validate(_, _), do: {:error, :badarg}

  @doc """
  Given a token (as found in `Timex.Parsers.Directive`), and a DateTime struct,
  produce a string representation of the token using values from the struct, using the default locale.
  """
  @spec format_token(atom, Date.t | DateTime.t, list(), list(), list()) :: String.t | {:error, term}
  def format_token(token, date, modifiers, flags, width) do
    format_token(Translator.default_locale, token, date, modifiers, flags, width)
  end

  @doc """
  Given a token (as found in `Timex.Parsers.Directive`), and a DateTime struct,
  produce a string representation of the token using values from the struct.
  """
  @spec format_token(String.t, atom, Date.t | DateTime.t, list(), list(), list()) :: String.t | {:error, term}
  def format_token(locale, token, date, modifiers, flags, width)

  # Formats
  def format_token(locale, token, %Date{} = date, modifiers, flags, width),
    do: format_token(locale, token, Timex.to_datetime(date), modifiers, flags, width)
  def format_token(locale, :iso_date, %DateTime{} = date, modifiers, _flags, _width) do
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    "#{year}-#{month}-#{day}"
  end
  def format_token(locale, :iso_time, %DateTime{} = date, modifiers, _flags, _width) do
    flags  = [padding: :zeroes]
    hour   = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    minute = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec    = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms     = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    "#{hour}:#{minute}:#{sec}#{ms}"
  end
  # NOTE: iso_8601 is deprecated in favor of iso_8601_extended
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:iso_8601, :iso_8601z] do
    date  = case token do
      :iso_8601  -> date
      :iso_8601z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms    = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :iso_8601 ->
        tz = format_token(locale, :zoffs_colon, date, modifiers, flags, width_spec(-1, nil))
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
      :iso_8601z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:iso_8601_extended, :iso_8601_extended_z] do
    date  = case token do
      :iso_8601_extended  -> date
      :iso_8601_extended_z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms    = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :iso_8601_extended ->
        tz = format_token(locale, :zoffs_colon, date, modifiers, flags, width_spec(-1, nil))
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
      :iso_8601_extended_z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:iso_8601_basic, :iso_8601_basic_z] do
    date  = case token do
      :iso_8601_basic  -> date
      :iso_8601_basic_z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms    = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :iso_8601_basic ->
        tz = format_token(locale, :zoffs, date, modifiers, flags, width_spec(-1, nil))
        "#{year}#{month}#{day}T#{hour}#{min}#{sec}#{ms}#{tz}"
      :iso_8601_basic_z ->
        "#{year}#{month}#{day}T#{hour}#{min}#{sec}#{ms}Z"
    end
  end
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:rfc_822, :rfc_822z] do
    # Mon, 05 Jun 14 23:20:59 +0200
    date = case token do
      :rfc_822  -> date
      :rfc_822z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(locale, :year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    wday  = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :rfc_822 ->
        tz = format_token(locale, :zoffs, date, modifiers, flags, width_spec(-1, nil))
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} #{tz}"
      :rfc_822z ->
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} Z"
    end
  end
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:rfc_1123, :rfc_1123z] do
    # `Tue, 05 Mar 2013 23:25:19 GMT`
    date = case token do
      :rfc_1123  -> date
      :rfc_1123z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    wday  = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :rfc_1123 ->
        tz = format_token(locale, :zoffs, date, modifiers, flags, width_spec(-1, nil))
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} #{tz}"
      :rfc_1123z ->
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} Z"
    end
  end
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:rfc_3339, :rfc_3339z] do
    # `2013-03-05T23:25:19+02:00`
    date  = case token do
      :rfc_3339  -> date
      :rfc_3339z -> Timezone.convert(date, "UTC")
    end
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms    = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    case token do
      :rfc_3339 ->
        tz = format_token(locale, :zoffs_colon, date, modifiers, flags, width_spec(-1, nil))
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
      :rfc_3339z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end
  def format_token(locale, :unix, %DateTime{} = date, modifiers, _flags, _width) do
    # Tue Mar  5 23:25:19 PST 2013`
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, [padding: :spaces], width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(locale, :day, date, modifiers, [padding: :spaces], width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    wday  = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))
    tz    = format_token(locale, :zabbr, date, modifiers, flags, width_spec(-1, nil))
    "#{wday} #{month} #{day} #{hour}:#{min}:#{sec} #{tz} #{year}"
  end
  def format_token(locale, :ansic, %DateTime{} = date, modifiers, flags, _width) do
    # Tue Mar  5 23:25:19 2013`
    year  = format_token(locale, :year4, date, modifiers, [padding: :spaces], width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(locale, :day, date, modifiers, [padding: :spaces], width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    wday  = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))
    "#{wday} #{month} #{day} #{hour}:#{min}:#{sec} #{year}"
  end
  def format_token(locale, :asn1_utc_time, %DateTime{} = date, modifiers, _flags, _width) do
    # `130305232519Z`
    date = Timezone.convert(date, "UTC")
    flags = [padding: :zeroes]
    year  = format_token(locale, :year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    "#{year}#{month}#{day}#{hour}#{min}#{sec}Z"
  end
  def format_token(locale, :asn1_generalized_time, %DateTime{} = date, modifiers, _flags, _width) do
    # `130305232519`
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    "#{year}#{month}#{day}#{hour}#{min}#{sec}"
  end
  def format_token(locale, :asn1_generalized_time_z, %DateTime{} = date, modifiers, flags, width) do
    # `130305232519Z`
    date = Timezone.convert(date, "UTC")
    base = format_token(locale, :asn1_generalized_time, date, modifiers, flags, width)
    base <> "Z"
  end
  def format_token(locale, :asn1_generalized_time_tz, %DateTime{} = date, modifiers, flags, width) do
    # `130305232519-0500`
    offset = format_token(locale, :zoffs, date, modifiers, flags, width)
    base = format_token(locale, :asn1_generalized_time, date, modifiers, flags, width)
    base <> offset
  end
  def format_token(locale, :kitchen, %DateTime{} = date, modifiers, _flags, _width) do
    # `3:25PM`
    hour  = format_token(locale, :hour12, date, modifiers, [], width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    ampm  = format_token(locale, :AM, date, modifiers, [], width_spec(-1, nil))
    "#{hour}:#{min}#{ampm}"
  end
  def format_token(locale, :slashed, %DateTime{} = date, modifiers, _flags, _width) do
    # `04/12/1987`
    flags = [padding: :zeroes]
    year  = format_token(locale, :year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day   = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    "#{month}/#{day}/#{year}"
  end
  def format_token(locale, token, %DateTime{} = date, modifiers, _flags, _width)
    when token in [:strftime_iso_clock, :strftime_iso_clock_full] do
    # `23:30:05`
    flags = [padding: :zeroes]
    hour  = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    case token do
      :strftime_iso_clock -> "#{hour}:#{min}"
      :strftime_iso_clock_full ->
        sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
        "#{hour}:#{min}:#{sec}"
    end
  end
  def format_token(locale, :strftime_kitchen, %DateTime{} = date, modifiers, _flags, _width) do
    # `04:30:01 PM`
    hour  = format_token(locale, :hour12, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min   = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec   = format_token(locale, :sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    ampm  = format_token(locale, :AM, date, modifiers, [], width_spec(-1, nil))
    "#{hour}:#{min}:#{sec} #{ampm}"
  end
  def format_token(locale, :strftime_iso_shortdate, %DateTime{} = date, modifiers, _flags, _width) do
    # ` 5-Jan-2014`
    flags = [padding: :zeroes]
    year  = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day   = format_token(locale, :day, date, modifiers, [padding: :spaces], width_spec(2..2))
    "#{day}-#{month}-#{year}"
  end
  def format_token(locale, :iso_week, %DateTime{} = date, modifiers, _flags, _width) do
    # 2015-W04
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    week = format_token(locale, :iso_weeknum, date, modifiers, flags, width_spec(2..2))
    "#{year}-W#{week}"
  end
  def format_token(locale, :iso_weekday, %DateTime{} = date, modifiers, _flags, _width) do
    # 2015-W04-1
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    week = format_token(locale, :iso_weeknum, date, modifiers, flags, width_spec(2..2))
    day  = format_token(locale, :wday_mon, date, modifiers, flags, width_spec(1, 1))
    "#{year}-W#{week}-#{day}"
  end
  def format_token(locale, :iso_ordinal, %DateTime{} = date, modifiers, _flags, _width) do
    # 2015-180
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    day  = format_token(locale, :oday, date, modifiers, flags, width_spec(3..3))
    "#{year}-#{day}"
  end

  # Years
  def format_token(_locale, :year4, %DateTime{year: year}, _modifiers, flags, width),   do: "#{pad_numeric(year, flags, width)}"
  def format_token(_locale, :year2, %DateTime{year: year}, _modifiers, flags, width),   do: "#{pad_numeric(rem(year, 100), flags, width)}"
  def format_token(_locale, :century, %DateTime{year: year}, _modifiers, flags, width), do: "#{pad_numeric(div(year, 100), flags, width)}"
  def format_token(_locale, :iso_year4,  %DateTime{} = date, _modifiers, flags, width) do
    {iso_year, _} = Timex.iso_week(date)
    "#{pad_numeric(iso_year, flags, width)}"
  end
  def format_token(_locale, :iso_year2,  %DateTime{} = date, _modifiers, flags, width) do
    {iso_year, _} = Timex.iso_week(date)
    "#{pad_numeric(rem(iso_year, 100), flags, width)}"
  end
  # Months
  def format_token(_locale, :month, %DateTime{month: month}, _modifiers, flags, width),
    do: "#{pad_numeric(month, flags, width)}"
  def format_token(locale, :mshort, %DateTime{month: month}, _, _, _) do
    months = Translator.get_months_abbreviated(locale)
    Map.get(months, month)
  end
  def format_token(locale, :mfull, %DateTime{month: month}, _, _, _)  do
    months = Translator.get_months(locale)
    Map.get(months, month)
  end
  # Days
  def format_token(_locale, :day, %DateTime{day: day}, _modifiers, flags, width), do: "#{pad_numeric(day, flags, width)}"
  def format_token(_locale, :oday, %DateTime{} = date, _modifiers, flags, width), do: "#{pad_numeric(Timex.day(date), flags, width)}"
  # Weeks
  def format_token(_locale, :iso_weeknum, %DateTime{} = date, _modifiers, flags, width) do
    {_, week} = Timex.iso_week(date)
    "#{pad_numeric(week, flags, width)}"
  end
  def format_token(_locale, :week_mon, %DateTime{} = date, _modifiers, flags, width) do
    {_, week} = Timex.iso_week(date)
    "#{pad_numeric(week, flags, width)}"
  end
  def format_token(_locale, :week_sun, %DateTime{year: year} = date, _modifiers, flags, width) do
    weeks_in_year = case Timex.iso_week({year, 12, 31}) do
      {^year, 53} -> 53
      _           -> 52
    end
    ordinal = Timex.day(date)
    weekday = case Timex.weekday(date) do # shift back one since our week starts with Sunday instead of Monday
      7 -> 0
      x -> x
    end
    week = div(ordinal - weekday + 10, 7)
    week = cond do
      week < 1  -> 52
      week < 53 -> week
      week > 52 && weeks_in_year == 52 -> 1
      true -> 53
    end
    "#{pad_numeric(week, flags, width)}"
  end
  def format_token(_locale, :wday_mon, %DateTime{} = date, _modifiers, flags, width),
    do: "#{Timex.weekday(date) |> pad_numeric(flags, width)}"
  def format_token(_locale, :wday_sun, %DateTime{} = date, _modifiers, flags, width) do
    # from 1..7 to 0..6
    weekday = case Timex.weekday(date) do
      7   -> 0
      day -> day
    end
    "#{pad_numeric(weekday, flags, width)}"
  end
  def format_token(locale, :wdshort, %DateTime{} = date, _modifiers, _flags, _width) do
    day = Timex.weekday(date)
    day_names = Translator.get_weekdays_abbreviated(locale)
    Map.get(day_names, day)
  end
  def format_token(locale, :wdfull, %DateTime{} = date, _modifiers, _flags, _width) do
    day = Timex.weekday(date)
    day_names = Translator.get_weekdays(locale)
    Map.get(day_names, day)
  end
  # Hours
  def format_token(_locale, :hour24, %DateTime{hour: hour}, _modifiers, flags, width), do: "#{pad_numeric(hour, flags, width)}"
  def format_token(_locale, :hour12, %DateTime{hour: hour}, _modifiers, flags, width) do
    {h, _} = Time.to_12hour_clock(hour)
    "#{pad_numeric(h, flags, width)}"
  end
  def format_token(_locale, :min, %DateTime{minute: min}, _modifiers, flags, width), do: "#{pad_numeric(min, flags, width)}"
  def format_token(_locale, :sec, %DateTime{second: sec}, _modifiers, flags, width), do: "#{pad_numeric(sec, flags, width)}"
  def format_token(_locale, :sec_fractional, %DateTime{millisecond: 0}, _modifiers, _flags, _width), do: <<>>
  def format_token(_locale, :sec_fractional, %DateTime{millisecond: ms}, _modifiers, _flags, _width)
    when ms < 10, do: ".00#{trunc(ms)}"
  def format_token(_locale, :sec_fractional, %DateTime{millisecond: ms}, _modifiers, _flags, _width)
    when ms < 100, do: ".0#{trunc(ms)}"
  def format_token(_locale, :sec_fractional, %DateTime{millisecond: ms}, _modifiers, _flags, _width),
    do: ".#{trunc(ms)}"

  def format_token(_locale, :sec_epoch, %DateTime{} = date, _modifiers, flags, width) do
    case get_in(flags, [:padding]) do
      padding when padding in [:zeroes, :spaces] ->
        {:error, {:formatter, "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}
      _ ->
        "#{DateTime.to_seconds(date, :epoch) |> pad_numeric(flags, width)}"
    end
  end
  def format_token(_locale, :us, %DateTime{millisecond: ms}, _modifiers, flags, width) do
    "#{pad_numeric(ms, flags, width)}000"
  end
  def format_token(locale, :am, %DateTime{hour: hour}, _modifiers, _flags, _width) do
    day_periods = Translator.get_day_periods(locale)
    {_, am_pm} = Time.to_12hour_clock(hour)
    Map.get(day_periods, am_pm)
  end
  def format_token(locale, :AM, %DateTime{hour: hour}, _modifiers, _flags, _width) do
    day_periods = Translator.get_day_periods(locale)
    case Time.to_12hour_clock(hour) do
      {_, :am} ->
        day_period = Map.get(day_periods, :AM)
      {_, :pm} ->
        day_period = Map.get(day_periods, :PM)
    end
  end
  # Timezones
  def format_token(_locale, :zname, %DateTime{timezone: tz}, _modifiers, _flags, _width),
    do: tz.full_name
  def format_token(_locale, :zabbr, %DateTime{timezone: tz}, _modifiers, _flags, _width),
    do: tz.abbreviation
  def format_token(_locale, :zoffs, %DateTime{timezone: tz}, _modifiers, flags, _width) do
    case get_in(flags, [:padding]) do
      padding when padding in [:spaces, :none] ->
        {:error, {:formatter, "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}}
      _ ->
        offset_hours = div(Timezone.total_offset(tz), 60)
        offset_mins  = rem(Timezone.total_offset(tz), 60)
        hour  = "#{pad_numeric(offset_hours, [padding: :zeroes], width_spec(2..2))}"
        min   = "#{pad_numeric(offset_mins, [padding: :zeroes], width_spec(2..2))}"
        cond do
          (offset_hours + offset_mins) >= 0 -> "+#{hour}#{min}"
          true -> "#{hour}#{min}"
        end
    end
  end
  def format_token(locale, :zoffs_colon, %DateTime{} = date, modifiers, flags, width) do
    case format_token(locale, :zoffs, date, modifiers, flags, width) do
      {:error, _} = err -> err
      offset ->
        [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] = offset |> String.split("", [trim: true, parts: 2])
        <<qualifier::binary, hour::binary, ?:, min::binary>>
    end
  end
  def format_token(locale, :zoffs_sec, %DateTime{} = date, modifiers, flags, width) do
    case format_token(locale, :zoffs, date, modifiers, flags, width) do
      {:error,_} = err -> err
      offset ->
        [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] = offset |> String.split("", [trim: true, parts: 2])
        <<qualifier::binary, hour::binary, ?:, min::binary, ?:, ?0, ?0>>
    end
  end
  def format_token(_locale, token, _, _, _, _) do
    {:error, {:formatter, :unsupported_token, token}}
  end

  defp pad_numeric(number, flags, width) when is_integer(number), do: pad_numeric("#{number}", flags, width)
  defp pad_numeric(number_str, [], _width), do: number_str
  defp pad_numeric(<<?-, number_str::binary>>, flags, width) do
    res = pad_numeric(number_str, flags, width)
    <<?-, res::binary>>
  end
  defp pad_numeric(number_str, flags, [min: min_width, max: max_width]) do
    case get_in(flags, [:padding]) do
      pad_type when pad_type in [nil, :none] -> number_str
      pad_type ->
        len       = String.length(number_str)
        cond do
          min_width == -1 && max_width == nil  -> number_str
          len < min_width && max_width == nil  -> String.duplicate(pad_char(pad_type), min_width - len) <> number_str
          max_width != nil && len < max_width -> String.duplicate(pad_char(pad_type), max_width - len) <> number_str
          true                                 -> number_str
        end
    end
  end
  defp pad_char(:zeroes), do: <<?0>>
  defp pad_char(:spaces), do: <<32>>

  defp width_spec(min..max), do: [min: min, max: max]
  defp width_spec(min, max), do: [min: min, max: max]
end
