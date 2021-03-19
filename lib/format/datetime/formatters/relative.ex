defmodule Timex.Format.DateTime.Formatters.Relative do
  @moduledoc """
  Relative time, based on Moment.js

  Uses localized strings.

  The format string should contain {relative}, which is where the phrase will be injected.

  | Range	                     | Sample Output
  ---------------------------------------------------------------------
  | 0 seconds                  | now
  | 1 to 45 seconds	           | a few seconds ago
  | 45 to 90 seconds	         | a minute ago
  | 90 seconds to 45 minutes	 | 2 minutes ago ... 45 minutes ago
  | 45 to 90 minutes	         | an hour ago
  | 90 minutes to 22 hours	   | 2 hours ago ... 22 hours ago
  | 22 to 36 hours	           | a day ago
  | 36 hours to 25 days	       | 2 days ago ... 25 days ago
  | 25 to 45 days	             | a month ago
  | 45 to 345 days	           | 2 months ago ... 11 months ago
  | 345 to 545 days (1.5 years)  | a year ago
  | 546 days+	                 | 2 years ago ... 20 years ago
  """
  use Timex.Format.DateTime.Formatter
  use Combine
  alias Timex.Format.FormatError
  alias Timex.{Types, Translator}

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
  Formats a date/time as a relative time formatted string

  ## Examples

      iex> #{__MODULE__}.format(Timex.shift(Timex.now, minutes: -1), "{relative}")
      {:ok, "1 minute ago"}
  """
  @spec format(Types.calendar_types(), String.t()) :: {:ok, String.t()} | {:error, term}
  def format(date, format_string), do: lformat(date, format_string, Translator.current_locale())

  @spec format!(Types.calendar_types(), String.t()) :: String.t() | no_return
  def format!(date, format_string), do: lformat!(date, format_string, Translator.current_locale())

  @spec lformat(Types.calendar_types(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, term}
  def lformat(date, format_string, locale) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}

      {:ok, dirs} when is_list(dirs) ->
        do_format(
          locale,
          Timex.to_naive_datetime(date),
          Timex.Protocol.NaiveDateTime.now(),
          dirs,
          <<>>
        )

      {:error, reason} ->
        {:error, {:format, reason}}
    end
  end

  @spec lformat!(Types.calendar_types(), String.t(), String.t()) :: String.t() | no_return
  def lformat!(date, format_string, locale) do
    case lformat(date, format_string, locale) do
      {:ok, result} -> result
      {:error, reason} -> raise FormatError, message: reason
    end
  end

  def relative_to(date, relative_to, format_string) do
    relative_to(date, relative_to, format_string, Translator.current_locale())
  end

  def relative_to(date, relative_to, format_string, locale) do
    case tokenize(format_string) do
      {:ok, []} ->
        {:error, "There were no formatting directives in the provided string."}

      {:ok, dirs} when is_list(dirs) ->
        do_format(
          locale,
          Timex.to_naive_datetime(date),
          Timex.to_naive_datetime(relative_to),
          dirs,
          <<>>
        )

      {:error, reason} ->
        {:error, {:format, reason}}
    end
  end

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

  defp do_format(locale, date, relative, [%Directive{type: :relative} | dirs], result) do
    diff = Timex.diff(date, relative, :seconds)

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

    do_format(locale, date, relative, dirs, <<result::binary, phrase::binary>>)
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
