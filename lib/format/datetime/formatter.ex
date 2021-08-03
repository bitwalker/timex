defmodule Timex.Format.DateTime.Formatter do
  @moduledoc """
  This module defines the behaviour for custom DateTime formatters.
  """

  alias Timex.{Timezone, Translator, Types}
  alias Timex.Translator
  alias Timex.Format.FormatError
  alias Timex.Format.DateTime.Formatters.{Default, Strftime, Relative}
  alias Timex.Parse.DateTime.Tokenizers.Directive

  @callback tokenize(format_string :: String.t()) ::
              {:ok, [Directive.t()]} | {:error, term}
  @callback format(date :: Types.calendar_types(), format_string :: String.t()) ::
              {:ok, String.t()} | {:error, term}
  @callback format!(date :: Types.calendar_types(), format_string :: String.t()) ::
              String.t() | no_return
  @callback lformat(
              date :: Types.calendar_types(),
              format_string :: String.t(),
              locale :: String.t()
            ) ::
              {:ok, String.t()} | {:error, term}
  @callback lformat!(
              date :: Types.calendar_types(),
              format_string :: String.t(),
              locale :: String.t()
            ) ::
              String.t() | no_return

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Timex.Format.DateTime.Formatter

      alias Timex.Parse.DateTime.Tokenizers.Directive
      import Timex.Format.DateTime.Formatter, only: [format_token: 5, format_token: 6]
    end
  end

  @doc """
  Formats a Date, DateTime, or NaiveDateTime as a string, using the provided format string,
  locale, and formatter. If the locale does not have translations, "en" will be used by
  default.

  If a formatter is not provided, the formatter used is `Timex.Format.DateTime.Formatters.DefaultFormatter`

  If an error is encountered during formatting, `lformat!` will raise
  """
  @spec lformat!(Types.valid_datetime(), String.t(), String.t(), atom | nil) ::
          String.t() | no_return
  def lformat!(date, format_string, locale, formatter \\ Default)

  def lformat!({:error, reason}, _format_string, _locale, _formatter),
    do: raise(ArgumentError, to_string(reason))

  def lformat!(date, format_string, locale, formatter) do
    with {:ok, formatted} <- lformat(date, format_string, locale, formatter) do
      formatted
    else
      {:error, :invalid_date} ->
        raise ArgumentError, "invalid_date"

      {:error, {:format, reason}} ->
        raise FormatError, message: to_string(reason)

      {:error, reason} ->
        raise FormatError, message: to_string(reason)
    end
  end

  @doc """
  Formats a Date, DateTime, or NaiveDateTime as a string, using the provided format string,
  locale, and formatter.

  If the locale provided does not have translations, "en" is used by default.

  If a formatter is not provided, the formatter used is `Timex.Format.DateTime.Formatters.DefaultFormatter`
  """
  @spec lformat(Types.valid_datetime(), String.t(), String.t(), atom | nil) ::
          {:ok, String.t()} | {:error, term}
  def lformat(date, format_string, locale, formatter \\ Default)

  def lformat({:error, _} = err, _format_string, _locale, _formatter),
    do: err

  def lformat(datetime, format_string, locale, :strftime),
    do: lformat(datetime, format_string, locale, Strftime)

  def lformat(datetime, format_string, locale, :relative),
    do: lformat(datetime, format_string, locale, Relative)

  def lformat(%{__struct__: struct} = date, format_string, locale, formatter)
      when struct in [Date, DateTime, NaiveDateTime, Time] and is_binary(format_string) and
             is_binary(locale) and is_atom(formatter) do
    formatter.lformat(date, format_string, locale)
  end

  def lformat(date, format_string, locale, formatter)
      when is_binary(format_string) and is_binary(locale) and is_atom(formatter) do
    with %NaiveDateTime{} = datetime <- Timex.to_naive_datetime(date) do
      formatter.lformat(datetime, format_string, locale)
    end
  end

  @doc """
  Formats a Date, DateTime, or NaiveDateTime as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.Format.DateTime.Formatters.DefaultFormatter`.

  Formatting will use the configured default locale, "en" if no other default is given.

  If an error is encountered during formatting, `format!` will raise.
  """
  @spec format!(Types.valid_datetime(), String.t(), atom | nil) :: String.t() | no_return
  def format!(date, format_string, formatter \\ Default)

  def format!(date, format_string, formatter),
    do: lformat!(date, format_string, Translator.current_locale(), formatter)

  @doc """
  Formats a Date, DateTime, or NaiveDateTime as a string, using the provided format
  string and formatter. If a formatter is not provided, the formatter
  used is `Timex.Format.DateTime.Formatters.DefaultFormatter`.

  Formatting will use the configured default locale, "en" if no other default is given.
  """
  @spec format(Types.valid_datetime(), String.t(), atom | nil) ::
          {:ok, String.t()} | {:error, term}
  def format(date, format_string, formatter \\ Default)

  def format(datetime, format_string, :strftime),
    do: lformat(datetime, format_string, Translator.current_locale(), Strftime)

  def format(datetime, format_string, :relative),
    do: lformat(datetime, format_string, Translator.current_locale(), Relative)

  def format(datetime, format_string, formatter),
    do: lformat(datetime, format_string, Translator.current_locale(), formatter)

  @doc """
  Validates the provided format string, using the provided formatter,
  or if none is provided, the default formatter. Returns `:ok` when valid,
  or `{:error, reason}` if not valid.
  """
  @spec validate(String.t(), atom | nil) :: :ok | {:error, term}
  def validate(format_string, formatter \\ Default)

  def validate(format_string, formatter) when is_binary(format_string) and is_atom(formatter) do
    formatter =
      case formatter do
        :strftime -> Strftime
        :relative -> Relative
        _ -> formatter
      end

    case formatter.tokenize(format_string) do
      {:error, _} = error ->
        error

      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}

      {:ok, directives} when is_list(directives) ->
        :ok
    end
  end

  @doc """
  Given a token (as found in `Timex.Parsers.Directive`), and a Date, DateTime, or NaiveDateTime struct,
  produce a string representation of the token using values from the struct, using the default locale.
  """
  @spec format_token(atom, Types.calendar_types(), list(), list(), list()) ::
          String.t() | {:error, term}
  def format_token(token, date, modifiers, flags, width) do
    format_token(Translator.current_locale(), token, date, modifiers, flags, width)
  end

  @doc """
  Given a token (as found in `Timex.Parsers.Directive`), and a Date, DateTime, or NaiveDateTime struct,
  produce a string representation of the token using values from the struct.
  """
  @spec format_token(String.t(), atom, Types.calendar_types(), list(), list(), list()) ::
          String.t() | {:error, term}
  def format_token(locale, token, date, modifiers, flags, width)

  # Formats
  def format_token(locale, :iso_date, date, modifiers, _flags, _width) do
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    "#{year}-#{month}-#{day}"
  end

  def format_token(locale, :iso_time, date, modifiers, _flags, _width) do
    flags = [padding: :zeroes]
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    minute = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    "#{hour}:#{minute}:#{sec}#{ms}"
  end

  def format_token(locale, token, date, modifiers, _flags, _width)
      when token in [:iso_8601_extended, :iso_8601_extended_z] do
    date =
      case token do
        :iso_8601_extended -> date
        :iso_8601_extended_z -> Timezone.convert(date, "UTC")
      end

    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))

    case token do
      :iso_8601_extended ->
        case format_token(locale, :zoffs_colon, date, modifiers, flags, width_spec(-1, nil)) do
          "" ->
            {:error, {:missing_timezone_information, date}}

          tz ->
            "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
        end

      :iso_8601_extended_z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end

  def format_token(locale, token, date, modifiers, _flags, _width)
      when token in [:iso_8601_basic, :iso_8601_basic_z] do
    date =
      case token do
        :iso_8601_basic -> date
        :iso_8601_basic_z -> Timezone.convert(date, "UTC")
      end

    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))

    case token do
      :iso_8601_basic ->
        case format_token(locale, :zoffs, date, modifiers, flags, width_spec(-1, nil)) do
          "" ->
            {:error, {:missing_timezone_information, date}}

          tz ->
            "#{year}#{month}#{day}T#{hour}#{min}#{sec}#{ms}#{tz}"
        end

      :iso_8601_basic_z ->
        "#{year}#{month}#{day}T#{hour}#{min}#{sec}#{ms}Z"
    end
  end

  def format_token(locale, token, date, modifiers, _flags, _width)
      when token in [:rfc_822, :rfc_822z] do
    # Mon, 05 Jun 14 23:20:59 +0200
    date =
      case token do
        :rfc_822 -> date
        :rfc_822z -> Timezone.convert(date, "UTC")
      end

    flags = [padding: :zeroes]
    year = format_token(locale, :year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    wday = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))

    case token do
      :rfc_822 ->
        case format_token(locale, :zoffs, date, modifiers, flags, width_spec(-1, nil)) do
          "" ->
            {:error, {:missing_timezone_information, date}}

          tz ->
            "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} #{tz}"
        end

      :rfc_822z ->
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} Z"
    end
  end

  def format_token(locale, token, date, modifiers, _flags, _width)
      when token in [:rfc_1123, :rfc_1123z] do
    # `Tue, 05 Mar 2013 23:25:19 GMT`
    date =
      case token do
        :rfc_1123 -> date
        :rfc_1123z -> Timezone.convert(date, "UTC")
      end

    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    wday = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))

    case token do
      :rfc_1123 ->
        case format_token(locale, :zoffs, date, modifiers, flags, width_spec(-1, nil)) do
          "" ->
            {:error, {:missing_timezone_information, date}}

          tz ->
            "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} #{tz}"
        end

      :rfc_1123z ->
        "#{wday}, #{day} #{month} #{year} #{hour}:#{min}:#{sec} Z"
    end
  end

  def format_token(locale, token, date, modifiers, _flags, _width)
      when token in [:rfc_3339, :rfc_3339z] do
    # `2013-03-05T23:25:19+02:00`
    date =
      case token do
        :rfc_3339 -> date
        :rfc_3339z -> Timezone.convert(date, "UTC")
      end

    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))

    case token do
      :rfc_3339 ->
        case format_token(locale, :zoffs_colon, date, modifiers, flags, width_spec(-1, nil)) do
          "" ->
            {:error, {:missing_timezone_information, date}}

          tz ->
            "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}#{tz}"
        end

      :rfc_3339z ->
        "#{year}-#{month}-#{day}T#{hour}:#{min}:#{sec}#{ms}Z"
    end
  end

  def format_token(locale, :unix, date, modifiers, _flags, _width) do
    # Tue Mar  5 23:25:19 PST 2013`
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, [padding: :spaces], width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day = format_token(locale, :day, date, modifiers, [padding: :spaces], width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    wday = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))
    tz = format_token(locale, :zabbr, date, modifiers, flags, width_spec(-1, nil))
    "#{wday} #{month} #{day} #{hour}:#{min}:#{sec} #{tz} #{year}"
  end

  def format_token(locale, :ansic, date, modifiers, flags, _width) do
    # Tue Mar  5 23:25:19 2013`
    year = format_token(locale, :year4, date, modifiers, [padding: :spaces], width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day = format_token(locale, :day, date, modifiers, [padding: :spaces], width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    wday = format_token(locale, :wdshort, date, modifiers, flags, width_spec(-1, nil))
    "#{wday} #{month} #{day} #{hour}:#{min}:#{sec} #{year}"
  end

  def format_token(locale, :asn1_utc_time, date, modifiers, _flags, _width) do
    # `130305232519Z`
    date = Timezone.convert(date, "UTC")
    flags = [padding: :zeroes]
    year = format_token(locale, :year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    "#{year}#{month}#{day}#{hour}#{min}#{sec}Z"
  end

  def format_token(locale, :asn1_generalized_time, date, modifiers, _flags, _width) do
    # `130305232519`
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
    ms = format_token(locale, :sec_fractional, date, modifiers, flags, width_spec(-1, nil))
    "#{year}#{month}#{day}#{hour}#{min}#{sec}#{ms}"
  end

  def format_token(locale, :asn1_generalized_time_z, date, modifiers, flags, width) do
    # `130305232519Z`
    date = Timezone.convert(date, "UTC")
    base = format_token(locale, :asn1_generalized_time, date, modifiers, flags, width)
    base <> "Z"
  end

  def format_token(locale, :asn1_generalized_time_tz, date, modifiers, flags, width) do
    # `130305232519-0500`
    offset = format_token(locale, :zoffs, date, modifiers, flags, width)
    base = format_token(locale, :asn1_generalized_time, date, modifiers, flags, width)
    base <> offset
  end

  def format_token(locale, :kitchen, date, modifiers, _flags, _width) do
    # `3:25PM`
    hour = format_token(locale, :hour12, date, modifiers, [], width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    ampm = format_token(locale, :AM, date, modifiers, [], width_spec(-1, nil))
    "#{hour}:#{min}#{ampm}"
  end

  def format_token(locale, :slashed, date, modifiers, _flags, _width) do
    # `04/12/1987`
    flags = [padding: :zeroes]
    year = format_token(locale, :year2, date, modifiers, flags, width_spec(2..2))
    month = format_token(locale, :month, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :day, date, modifiers, flags, width_spec(2..2))
    "#{month}/#{day}/#{year}"
  end

  def format_token(locale, token, date, modifiers, _flags, _width)
      when token in [:strftime_iso_clock, :strftime_iso_clock_full] do
    # `23:30:05`
    flags = [padding: :zeroes]
    hour = format_token(locale, :hour24, date, modifiers, flags, width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, flags, width_spec(2..2))

    case token do
      :strftime_iso_clock ->
        "#{hour}:#{min}"

      :strftime_iso_clock_full ->
        sec = format_token(locale, :sec, date, modifiers, flags, width_spec(2..2))
        "#{hour}:#{min}:#{sec}"
    end
  end

  def format_token(locale, :strftime_kitchen, date, modifiers, _flags, _width) do
    # `04:30:01 PM`
    hour = format_token(locale, :hour12, date, modifiers, [padding: :zeroes], width_spec(2..2))
    min = format_token(locale, :min, date, modifiers, [padding: :zeroes], width_spec(2..2))
    sec = format_token(locale, :sec, date, modifiers, [padding: :zeroes], width_spec(2..2))
    ampm = format_token(locale, :AM, date, modifiers, [], width_spec(-1, nil))
    "#{hour}:#{min}:#{sec} #{ampm}"
  end

  def format_token(locale, :strftime_iso_shortdate, date, modifiers, _flags, _width) do
    # ` 5-Jan-2014`
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    month = format_token(locale, :mshort, date, modifiers, flags, width_spec(-1, nil))
    day = format_token(locale, :day, date, modifiers, [padding: :spaces], width_spec(2..2))
    "#{day}-#{month}-#{year}"
  end

  def format_token(locale, :iso_week, date, modifiers, _flags, _width) do
    # 2015-W04
    flags = [padding: :zeroes]
    year = format_token(locale, :iso_year4, date, modifiers, flags, width_spec(4..4))
    week = format_token(locale, :iso_weeknum, date, modifiers, flags, width_spec(2..2))
    "#{year}-W#{week}"
  end

  def format_token(locale, :iso_weekday, date, modifiers, _flags, _width) do
    # 2015-W04-1
    flags = [padding: :zeroes]
    year = format_token(locale, :iso_year4, date, modifiers, flags, width_spec(4..4))
    week = format_token(locale, :iso_weeknum, date, modifiers, flags, width_spec(2..2))
    day = format_token(locale, :wday_mon, date, modifiers, flags, width_spec(1, 1))
    "#{year}-W#{week}-#{day}"
  end

  def format_token(locale, :iso_ordinal, date, modifiers, _flags, _width) do
    # 2015-180
    flags = [padding: :zeroes]
    year = format_token(locale, :year4, date, modifiers, flags, width_spec(4..4))
    day = format_token(locale, :oday, date, modifiers, flags, width_spec(3..3))
    "#{year}-#{day}"
  end

  # Years
  def format_token(_locale, :year4, date, _modifiers, flags, width),
    do: pad_numeric(date.year, flags, width)

  def format_token(_locale, :year2, date, _modifiers, flags, width),
    do: pad_numeric(rem(date.year, 100), flags, width)

  def format_token(_locale, :century, date, _modifiers, flags, width),
    do: pad_numeric(div(date.year, 100), flags, width)

  def format_token(_locale, :iso_year4, date, _modifiers, flags, width) do
    {iso_year, _} = Timex.iso_week(date)
    pad_numeric(iso_year, flags, width)
  end

  def format_token(_locale, :iso_year2, date, _modifiers, flags, width) do
    {iso_year, _} = Timex.iso_week(date)
    pad_numeric(rem(iso_year, 100), flags, width)
  end

  # Months
  def format_token(_locale, :month, date, _modifiers, flags, width),
    do: pad_numeric(date.month, flags, width)

  def format_token(locale, :mshort, date, _, _, _) do
    months = Translator.get_months_abbreviated(locale)
    Map.get(months, date.month)
  end

  def format_token(locale, :mfull, date, _, _, _) do
    months = Translator.get_months(locale)
    Map.get(months, date.month)
  end

  # Days
  def format_token(_locale, :day, date, _modifiers, flags, width),
    do: pad_numeric(date.day, flags, width)

  def format_token(_locale, :oday, date, _modifiers, flags, width),
    do: pad_numeric(Timex.day(date), flags, width)

  # Weeks
  def format_token(_locale, :iso_weeknum, date, _modifiers, flags, width) do
    {_, week} = Timex.iso_week(date)
    pad_numeric(week, flags, width)
  end

  def format_token(_locale, :week_mon, %{:year => year} = date, _modifiers, flags, width) do
    new_year = Timex.Date.new!(year, 1, 1)
    week_start = Timex.Date.beginning_of_week(new_year, :monday)

    # This date can be calculated by taking the day number of the year,
    # shifting the day number of the year down by the number of days which
    # occurred in the previous year, then dividing by 7
    day_num =
      if Date.compare(week_start, new_year) == :lt do
        prev_year_day_start = Date.day_of_year(week_start)
        prev_year_day_end = Date.day_of_year(Timex.Date.new!(week_start.year, 12, 31))
        shift = prev_year_day_end - prev_year_day_start
        shift + Date.day_of_year(Timex.Date.new!(year, date.month, date.day))
      else
        Date.day_of_year(Timex.Date.new!(year, date.month, date.day))
      end

    div(day_num, 7)
    |> pad_numeric(flags, width)
  end

  def format_token(_locale, :week_sun, %{:year => year} = date, _modifiers, flags, width) do
    new_year = Timex.Date.new!(year, 1, 1)
    week_start = Timex.Date.beginning_of_week(new_year, :sunday)

    # This date can be calculated by taking the day number of the year,
    # shifting the day number of the year down by the number of days which
    # occurred in the previous year, then dividing by 7
    day_num =
      if Date.compare(week_start, new_year) == :lt do
        prev_year_day_start = Date.day_of_year(week_start)
        prev_year_day_end = Date.day_of_year(Timex.Date.new!(week_start.year, 12, 31))
        shift = prev_year_day_end - prev_year_day_start
        shift + Date.day_of_year(Timex.Date.new!(year, date.month, date.day))
      else
        Date.day_of_year(Timex.Date.new!(year, date.month, date.day))
      end

    div(day_num, 7)
    |> pad_numeric(flags, width)
  end

  def format_token(_locale, :wday_mon, date, _modifiers, flags, width),
    do: pad_numeric(Timex.weekday!(date, :monday), flags, width)

  def format_token(_locale, :wday_sun, date, _modifiers, flags, width),
    do: pad_numeric(Timex.weekday!(date, :sunday) - 1, flags, width)

  def format_token(locale, :wdshort, date, _modifiers, _flags, _width) do
    day = Timex.weekday(date)
    day_names = Translator.get_weekdays_abbreviated(locale)
    Map.get(day_names, day)
  end

  def format_token(locale, :wdfull, date, _modifiers, _flags, _width) do
    day = Timex.weekday(date)
    day_names = Translator.get_weekdays(locale)
    Map.get(day_names, day)
  end

  # Hours
  def format_token(_locale, :hour24, %{:hour => hour}, _modifiers, flags, width),
    do: pad_numeric(hour, flags, width)

  def format_token(_locale, :hour24, _date, _modifiers, flags, width),
    do: pad_numeric(0, flags, width)

  def format_token(_locale, :hour12, %{:hour => hour}, _modifiers, flags, width) do
    {h, _} = Timex.Time.to_12hour_clock(hour)
    pad_numeric(h, flags, width)
  end

  def format_token(_locale, :hour12, _date, _modifiers, flags, width) do
    {h, _} = Timex.Time.to_12hour_clock(0)
    pad_numeric(h, flags, width)
  end

  def format_token(_locale, :min, %{:minute => min}, _modifiers, flags, width),
    do: pad_numeric(min, flags, width)

  def format_token(_locale, :min, _date, _modifiers, flags, width),
    do: pad_numeric(0, flags, width)

  def format_token(_locale, :sec, %{:second => sec}, _modifiers, flags, width),
    do: pad_numeric(sec, flags, width)

  def format_token(_locale, :sec, _date, _modifiers, flags, width),
    do: pad_numeric(0, flags, width)

  def format_token(
        _locale,
        :sec_fractional,
        %{microsecond: {us, precision}},
        _modifiers,
        _flags,
        width
      )
      when precision > 0 do
    min_width =
      case Keyword.get(width, :min) do
        nil -> precision
        n when n < 0 -> precision
        n -> n
      end

    max_width =
      case Keyword.get(width, :max) do
        nil -> precision
        n when n < min_width -> min_width
        n -> n
      end

    us_str = "#{us}"
    padded_us_str = String.duplicate(pad_char(:zeroes), 6 - byte_size(us_str)) <> us_str
    padded = pad_numeric(padded_us_str, [padding: :zeroes], width_spec(min_width..max_width))
    ".#{padded}"
  end

  def format_token(_locale, :sec_fractional, _date, _modifiers, _flags, width) do
    case Keyword.get(width, :min) do
      n when is_integer(n) and n > 0 ->
        padded = pad_numeric(0, [padding: :zeroes], width_spec(n..n))
        ".#{padded}"

      _ ->
        ""
    end
  end

  def format_token(_locale, :sec_epoch, date, _modifiers, flags, width) do
    case get_in(flags, [:padding]) do
      padding when padding in [:zeroes, :spaces] ->
        {:error,
         {:formatter,
          "Invalid directive flag: Cannot pad seconds from epoch, as it is not a fixed width integer."}}

      _ ->
        pad_numeric(Timex.to_unix(date), flags, width)
    end
  end

  def format_token(_locale, :us, %{microsecond: {us, _precision}}, _modifiers, flags, width) do
    min =
      case Keyword.get(width, :min) do
        nil -> 6
        n when n < 0 -> 6
        n -> n
      end

    max =
      case Keyword.get(width, :max) do
        nil -> 6
        n when n > 6 -> n
        _ -> 6
      end

    pad_numeric(us, flags, width_spec(min..max))
  end

  def format_token(_locale, :us, _date, _modifiers, flags, width) do
    pad_numeric(0, flags, width)
  end

  def format_token(
        _locale,
        :ms,
        _date = %{microsecond: {us, _precision}},
        _modifiers,
        flags,
        _width
      ),
      do: pad_numeric(Kernel.round(us / 1000), flags, width_spec(3..3))

  def format_token(_locale, :ms, _date, _modifiers, flags, width),
    do: pad_numeric(0, flags, width)

  def format_token(locale, :am, %{hour: hour}, _modifiers, _flags, _width) do
    day_periods = Translator.get_day_periods(locale)
    {_, am_pm} = Timex.Time.to_12hour_clock(hour)
    Map.get(day_periods, am_pm)
  end

  def format_token(locale, :am, _date, _modifiers, _flags, _width) do
    day_periods = Translator.get_day_periods(locale)
    {_, am_pm} = Timex.Time.to_12hour_clock(0)
    Map.get(day_periods, am_pm)
  end

  def format_token(locale, :AM, %{hour: hour}, _modifiers, _flags, _width) do
    day_periods = Translator.get_day_periods(locale)

    case Timex.Time.to_12hour_clock(hour) do
      {_, :am} ->
        Map.get(day_periods, :AM)

      {_, :pm} ->
        Map.get(day_periods, :PM)
    end
  end

  def format_token(locale, :AM, _date, _modifiers, _flags, _width) do
    day_periods = Translator.get_day_periods(locale)

    case Timex.Time.to_12hour_clock(0) do
      {_, :am} ->
        Map.get(day_periods, :AM)

      {_, :pm} ->
        Map.get(day_periods, :PM)
    end
  end

  # Timezones
  def format_token(_locale, :zname, %{time_zone: tz}, _modifiers, _flags, _width),
    do: tz

  def format_token(_locale, :zname, _date, _modifiers, _flags, _width),
    do: ""

  def format_token(_locale, :zabbr, %{zone_abbr: abbr}, _modifiers, _flags, _width),
    do: abbr

  def format_token(_locale, :zabbr, _date, _modifiers, _flags, _width),
    do: ""

  def format_token(
        _locale,
        :zoffs,
        %{std_offset: std, utc_offset: utc},
        _modifiers,
        flags,
        _width
      ) do
    case get_in(flags, [:padding]) do
      padding when padding in [:spaces, :none] ->
        {:error,
         {:formatter,
          "Invalid directive flag: Timezone offsets require 0-padding to remain unambiguous."}}

      _ ->
        total_offset = Timezone.total_offset(std, utc)
        offset_hours = div(total_offset, 60 * 60)
        offset_mins = div(rem(total_offset, 60 * 60), 60)
        hour = pad_numeric(offset_hours, [padding: :zeroes], width_spec(2..2))
        min = pad_numeric(offset_mins, [padding: :zeroes], width_spec(2..2))

        cond do
          offset_hours + offset_mins >= 0 -> "+#{hour}#{min}"
          true -> "#{hour}#{min}"
        end
    end
  end

  def format_token(_locale, :zoffs, _date, _modifiers, _flags, _width),
    do: ""

  def format_token(locale, :zoffs_colon, date, modifiers, flags, width) do
    case format_token(locale, :zoffs, date, modifiers, flags, width) do
      {:error, _} = err ->
        err

      "" ->
        ""

      offset ->
        case String.split(offset, "", trim: true, parts: 2) do
          [qualifier, <<hour::binary-size(2), min::binary-size(2)>>] ->
            <<qualifier::binary, hour::binary, ?:, min::binary>>

          [qualifier, <<hour::binary-size(2), "-", min::binary-size(2)>>] ->
            <<qualifier::binary, hour::binary, ?:, min::binary>>
        end
    end
  end

  def format_token(
        locale,
        :zoffs_sec,
        %{std_offset: std, utc_offset: utc} = date,
        modifiers,
        flags,
        width
      ) do
    case format_token(locale, :zoffs_colon, date, modifiers, flags, width) do
      {:error, _} = err ->
        err

      "" ->
        ""

      offset ->
        total_offset = Timezone.total_offset(std, utc)
        offset_secs = rem(rem(total_offset, 60 * 60), 60)
        "#{offset}:#{pad_numeric(offset_secs, [padding: :zeroes], width_spec(2..2))}"
    end
  end

  def format_token(_locale, :zoffs_sec, _date, _modifiers, _flags, _width),
    do: ""

  def format_token(_locale, token, _, _, _, _) do
    {:error, {:formatter, :unsupported_token, token}}
  end

  defp pad_numeric(number, flags, width) when is_integer(number),
    do: pad_numeric("#{number}", flags, width)

  defp pad_numeric(number_str, [], _width), do: number_str

  defp pad_numeric(<<?-, number_str::binary>>, flags, width) do
    res = pad_numeric(number_str, flags, width)
    <<?-, res::binary>>
  end

  defp pad_numeric(number_str, flags, min: min_width, max: max_width) do
    case get_in(flags, [:padding]) do
      pad_type when pad_type in [nil, :none] ->
        number_str

      pad_type ->
        len = byte_size(number_str)

        cond do
          len == min_width -> number_str
          min_width == -1 && max_width == nil -> number_str
          len < min_width -> String.duplicate(pad_char(pad_type), min_width - len) <> number_str
          len > min_width && len > max_width -> binary_part(number_str, 0, max_width)
          len > min_width -> number_str
        end
    end
  end

  defp pad_char(:zeroes), do: <<?0>>
  defp pad_char(:spaces), do: <<32>>

  defp width_spec(min..max), do: [min: min, max: max]
  defp width_spec(min, max), do: [min: min, max: max]
end
