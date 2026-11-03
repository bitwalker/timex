defmodule Timex.Format.DateTime.Formatters.Relative do
  @moduledoc """
  Localized relative date and time formatting.

  The format string must contain `{relative}`. Date targets compare calendar
  days; datetime targets compare elapsed time after conversion to UTC.

  Elapsed values truncate to whole seconds toward zero, then to whole units
  within the following ranges. The same thresholds apply in both directions.
  A month is an approximate 30 days and a year is 360 days in this formatter.

  | Absolute elapsed time | Past output | Future output |
  | --- | --- | --- |
  | 0 whole seconds | now | now |
  | 1–45 seconds | N seconds ago | in N seconds |
  | 46 seconds to <2 minutes | 1 minute ago | in 1 minute |
  | 2 minutes to <1 hour | N minutes ago | in N minutes |
  | 1 hour to <2 hours | 1 hour ago | in 1 hour |
  | 2 hours to <24 hours | N hours ago | in N hours |
  | 24 hours to <48 hours | yesterday | tomorrow |
  | 48 hours to <30 days | N days ago | in N days |
  | 30 days to <60 days | 1 month ago | in 1 month |
  | 60 days to <360 days | N months ago | in N months |
  | 360 days to <720 days | 1 year ago | in 1 year |
  | 720 days or more | N years ago | in N years |

  `Timex.from_now/1` samples the clock when formatting. A target computed as
  two days after an earlier clock sample can therefore be less than 48 hours
  away and render as "tomorrow". Pass the same reference to `Timex.from_now/2`
  or `relative_to/3` for deterministic boundaries. Use Date targets when the
  intended comparison is calendar days rather than elapsed hours.
  """
  use Timex.Format.DateTime.Formatter
  use Combine
  alias Timex.Format.FormatError
  alias Timex.{Types, Translator}

  @type relative_date ::
          Date.t()
          | NaiveDateTime.t()
          | DateTime.t()
          | Types.date()
          | Types.datetime()
          | Types.microsecond_datetime()

  @spec tokenize(String.t()) :: {:ok, [Directive.t()]} | {:error, term}
  def tokenize(format_string) do
    case Combine.parse(format_string, relative_parser()) do
      results when is_list(results) ->
        directives = results |> List.flatten() |> Enum.filter(fn x -> x !== nil end)

        case Enum.any?(directives, fn %Directive{type: type} -> type != :literal end) do
          false -> {:error, "Invalid format string, must contain at least one directive."}
          true -> {:ok, directives}
        end

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Formats a date/time as a relative time formatted string.

  Date targets (including Erlang date tuples) compare calendar days with today's
  UTC date. Datetime targets compare elapsed time. Time-only targets are unsupported.

  ## Examples

      iex> #{__MODULE__}.format(Timex.shift(Timex.now, minutes: -1), "{relative}")
      {:ok, "1 minute ago"}
  """
  @spec format(relative_date(), String.t()) :: {:ok, String.t()} | {:error, term}
  def format(date, format_string), do: lformat(date, format_string, Translator.current_locale())

  @spec format!(relative_date(), String.t()) :: String.t() | no_return
  def format!(date, format_string), do: lformat!(date, format_string, Translator.current_locale())

  @spec lformat(relative_date(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, term}
  def lformat(date, format_string, locale) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}

      {:ok, dirs} when is_list(dirs) ->
        format_relative(locale, date, Timex.Protocol.NaiveDateTime.now(), dirs)

      {:error, reason} ->
        {:error, {:format, reason}}
    end
  end

  @spec lformat!(relative_date(), String.t(), String.t()) :: String.t() | no_return
  def lformat!(date, format_string, locale) do
    case lformat(date, format_string, locale) do
      {:ok, result} -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  @doc """
  Formats a target relative to an explicit reference.

  A Date target compares calendar dates, ignoring the reference's time of day.
  An aware reference is first converted to UTC, so its UTC date is used. Datetime
  targets compare elapsed time, treating naive values as UTC and date references
  as midnight. Use Date targets for calendar-day labels such as "tomorrow".
  """
  def relative_to(date, relative_to, format_string) do
    relative_to(date, relative_to, format_string, Translator.current_locale())
  end

  def relative_to(date, relative_to, format_string, locale) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}

      {:ok, dirs} when is_list(dirs) ->
        format_relative(locale, date, relative_to, dirs)

      {:error, reason} ->
        {:error, {:format, reason}}
    end
  end

  defp format_relative(locale, date, reference, dirs) do
    calendar_days? = match?(%Date{}, date) or (is_tuple(date) and tuple_size(date) == 3)

    with %NaiveDateTime{} = date <- normalize_datetime(date),
         %NaiveDateTime{} = reference <- normalize_datetime(reference),
         reference = if(calendar_days?, do: midnight(reference), else: reference),
         diff when is_integer(diff) <- Timex.diff(date, reference, :seconds) do
      do_format(locale, date, diff, dirs, <<>>)
    end
  end

  defp midnight(date), do: %{date | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

  defp normalize_datetime({year, month, day}) do
    valid_naive(year, month, day, 0, 0, 0, {0, 0}, Calendar.ISO)
  end

  defp normalize_datetime({{year, month, day}, {hour, minute, second}}) do
    valid_naive(year, month, day, hour, minute, second, {0, 0}, Calendar.ISO)
  end

  defp normalize_datetime({{year, month, day}, {hour, minute, second, us}})
       when is_integer(us) and us >= 0 and us <= 999_999 do
    normalize_datetime(
      {{year, month, day},
       {hour, minute, second, Timex.DateTime.Helpers.construct_microseconds(us)}}
    )
  end

  defp normalize_datetime({{year, month, day}, {hour, minute, second, us}}) do
    valid_naive(year, month, day, hour, minute, second, us, Calendar.ISO)
  end

  defp normalize_datetime(%Date{} = date) do
    valid_naive(date.year, date.month, date.day, 0, 0, 0, {0, 0}, date.calendar)
  end

  defp normalize_datetime(%DateTime{utc_offset: utc, std_offset: std} = date)
       when is_integer(utc) and is_integer(std) do
    with %NaiveDateTime{} <- normalize_datetime(DateTime.to_naive(date)),
         do: Timex.to_naive_datetime(date)
  end

  defp normalize_datetime(%DateTime{}), do: {:error, :invalid_date}

  defp normalize_datetime(date) do
    with %NaiveDateTime{} = naive <- Timex.to_naive_datetime(date) do
      valid_naive(
        naive.year,
        naive.month,
        naive.day,
        naive.hour,
        naive.minute,
        naive.second,
        naive.microsecond,
        naive.calendar
      )
    end
  end

  defp valid_naive(year, month, day, hour, minute, second, {us, precision}, calendar)
       when is_integer(year) and is_integer(month) and is_integer(day) and
              is_integer(hour) and is_integer(minute) and is_integer(second) and
              is_integer(us) and us >= 0 and us <= 999_999 and
              is_integer(precision) and precision >= 0 and precision <= 6 and
              calendar == Calendar.ISO do
    with {:ok, naive} <-
           NaiveDateTime.new(year, month, day, hour, minute, second, {us, precision}, calendar),
         do: naive
  end

  defp valid_naive(_, _, _, _, _, _, _, calendar) when calendar != Calendar.ISO,
    do: {:error, {:unsupported_calendar, calendar}}

  defp valid_naive(_, _, _, _, _, _, _, _), do: {:error, :invalid_date}

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @month @day * 30
  @year @month * 12

  defp do_format(_locale, _date, _relative, [], result), do: {:ok, result}

  defp do_format(locale, date, relative, [%Directive{type: :literal, value: char} | dirs], result)
       when is_binary(char) do
    do_format(locale, date, relative, dirs, <<result::binary, char::binary>>)
  end

  defp do_format(locale, date, diff, [%Directive{type: :relative} | dirs], result) do
    phrase =
      cond do
        # future
        diff == 0 ->
          Translator.translate(locale, "relative_time", "now")

        diff > 0 && diff <= 45 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} second",
            "in %{count} seconds",
            diff
          )

        diff > 45 && diff < @minute * 2 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} minute",
            "in %{count} minutes",
            1
          )

        diff >= @minute * 2 && diff < @hour ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} minute",
            "in %{count} minutes",
            div(diff, @minute)
          )

        diff >= @hour && diff < @hour * 2 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} hour",
            "in %{count} hours",
            1
          )

        diff >= @hour * 2 && diff < @day ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} hour",
            "in %{count} hours",
            div(diff, @hour)
          )

        diff >= @day && diff < @day * 2 ->
          Translator.translate(
            locale,
            "relative_time",
            "tomorrow"
          )

        diff >= @day * 2 && diff < @month ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} day",
            "in %{count} days",
            div(diff, @day)
          )

        diff >= @month && diff < @month * 2 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} month",
            "in %{count} months",
            1
          )

        diff >= @month * 2 && diff < @year ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} month",
            "in %{count} months",
            div(diff, @month)
          )

        diff >= @year && diff < @year * 2 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} year",
            "in %{count} years",
            1
          )

        diff >= @year * 2 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "in %{count} year",
            "in %{count} years",
            div(diff, @year)
          )

        # past
        diff < 0 && diff >= -45 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} second ago",
            "%{count} seconds ago",
            diff * -1
          )

        diff < -45 && diff > @minute * 2 * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} minute ago",
            "%{count} minutes ago",
            1
          )

        diff <= @minute * 2 && diff > @hour * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} minute ago",
            "%{count} minutes ago",
            div(diff * -1, @minute)
          )

        diff <= @hour && diff > @hour * 2 * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} hour ago",
            "%{count} hours ago",
            1
          )

        diff <= @hour * 2 && diff > @day * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} hour ago",
            "%{count} hours ago",
            div(diff * -1, @hour)
          )

        diff <= @day && diff > @day * 2 * -1 ->
          Translator.translate(
            locale,
            "relative_time",
            "yesterday"
          )

        diff <= @day * 2 && diff > @month * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} day ago",
            "%{count} days ago",
            div(diff * -1, @day)
          )

        diff <= @month && diff > @month * 2 * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} month ago",
            "%{count} months ago",
            1
          )

        diff <= @month * 2 && diff > @year * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} month ago",
            "%{count} months ago",
            div(diff * -1, @month)
          )

        diff <= @year && diff > @year * 2 * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} year ago",
            "%{count} years ago",
            1
          )

        diff <= @year * 2 * -1 ->
          Translator.translate_plural(
            locale,
            "relative_time",
            "%{count} year ago",
            "%{count} years ago",
            div(diff * -1, @year)
          )
      end

    do_format(locale, date, diff, dirs, <<result::binary, phrase::binary>>)
  end

  defp do_format(
         locale,
         date,
         relative,
         [%Directive{type: type, modifiers: mods, flags: flags, width: width} | dirs],
         result
       ) do
    case format_token(locale, type, date, mods, flags, width) do
      {:error, _} = err -> err
      formatted -> do_format(locale, date, relative, dirs, <<result::binary, formatted::binary>>)
    end
  end

  # Token parser
  defp relative_parser do
    many1(
      choice([
        between(char(?{), map(one_of(word(), ["relative"]), &map_directive/1), char(?})),
        map(none_of(char(), ["{", "}"]), &map_literal/1)
      ])
    )
  end

  # Gets/builds the Directives for a given token
  defp map_directive("relative"),
    do: %Directive{:type => :relative, :value => "relative"}

  # Generates directives for literal characters
  defp map_literal([]), do: nil

  defp map_literal(literals)
       when is_list(literals),
       do: Enum.map(literals, &map_literal/1)

  defp map_literal(literal), do: %Directive{type: :literal, value: literal, parser: char(literal)}
end
