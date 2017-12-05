defmodule Timex.Parse.DateTime.Helpers do
  @moduledoc false
  import Combine.Parsers.Base
  import Combine.Parsers.Text, except: [integer: 0, integer: 1]
  alias Combine.Parsers.Text
  alias Timex.Translator
  use Timex.Constants

  @locales [
    "da",
    "de",
    "en",
    "es",
    "fr",
    "id",
    "it",
    "ja",
    "ko",
    "nb_NO",
    "nl",
    "pl",
    "pt",
    "pt_BR",
    "ro",
    "ru",
    "sv",
    "zh_CN"
  ]



  Enum.each(@locales, fn locale ->
    months = Translator.get_months(locale)

    Enum.each(months, fn {index, month} ->
      abbreviation = Translator.get_months_abbreviated(locale) |> Map.get(index)
      def abbreviate_month(unquote(month), unquote(locale)), do: unquote(abbreviation)
    end)
  end)

  Enum.each(@locales, fn locale ->
    months = Translator.get_months(locale) |> Map.values
    def months(unquote(locale)), do: unquote(months)
  end)

  def to_month(month) when is_integer(month), do: [month: month]

  Enum.each(@locales, fn locale ->
    fulls = Translator.get_months(locale)
    Enum.each(fulls, fn {index, name} ->
      def to_month_num(unquote(name), unquote(locale)), do: to_month(unquote(index))
    end)

    abbrs = Translator.get_months_abbreviated(locale)
    Enum.each(abbrs, fn {index, name} ->
      def to_month_num(unquote(name), unquote(locale)), do: to_month(unquote(index))
    end)
  end)

  Enum.each(@locales, fn locale ->
    weekday_names_lower = Translator.get_weekdays(locale)
    |> Map.values
    |> Enum.map(&String.downcase/1)

    weekday_abbrs_lower = Translator.get_weekdays_abbreviated(locale)
    |> Map.values
    |> Enum.map(&String.downcase/1)


    def is_weekday(name, unquote(locale)) do
      n = String.downcase(name)
      cond do
        n in unquote(weekday_abbrs_lower) -> true
        n in unquote(weekday_names_lower) -> true
        true                              -> false
      end
    end
  end)

  Enum.each(@locales, fn locale ->
    fulls = Translator.get_weekdays(locale)
    Enum.each(fulls, fn {index, full} ->
      defp to_weekday_lower(unquote(String.downcase(full)), unquote(locale)), do: unquote(index)
    end)

    abbrs = Translator.get_weekdays_abbreviated(locale)
    Enum.each(abbrs, fn {index, abbrev} ->
      defp to_weekday_lower(unquote(String.downcase(abbrev)), unquote(locale)), do: unquote(index)
    end)
  end)

  def to_weekday(name, locale), do: to_weekday_lower(String.downcase(name), locale)


  def to_sec_ms(fraction) do
    precision = byte_size(fraction)
    n = String.to_integer(fraction)
    n = n * div(1_000_000, trunc(:math.pow(10, precision)))
    case n do
      0 -> [sec_fractional: {0,0}]
      _ -> [sec_fractional: {n, precision}]
    end
  end

  def parse_milliseconds(ms) do
    n = ms |> String.trim_leading("0")
    n = if n == "", do: 0, else: String.to_integer(n)
    n = n * 1_000
    [sec_fractional: Timex.DateTime.Helpers.construct_microseconds(n)]
  end
  def parse_microseconds(us) do
    n_width = byte_size(us)
    trailing = n_width - byte_size(String.trim_trailing(us, "0"))
    cond do
      n_width == trailing ->
        [sec_fractional: {0, n_width}]
      :else ->
        p = n_width - trailing
        p = if p > 6, do: 6, else: p
        n = us |> String.trim("0") |> String.to_integer
        [sec_fractional: {n * trunc(:math.pow(10, 6-p)), p}]
    end
  end

  def periods_upper(locale), do: Translator.get_day_periods(locale) |> Map.take([:AM, :PM]) |> Map.values
  def periods_lower(locale), do: Translator.get_day_periods(locale) |> Map.take([:am, :pm]) |> Map.values
  def periods(locale), do: Translator.get_day_periods(locale) |> Map.values

  Enum.each(@locales, fn locale ->
    periods = Translator.get_day_periods(locale)

    Enum.each(periods, fn {key, value} ->
      label = case key do
        :am -> :am
        :AM -> :AM
        :pm -> :am
        :PM -> :AM
      end

      def to_ampm(unquote(value), unquote(locale)), do: [{unquote(label), unquote(value)}]
    end)
  end)

  def integer(opts \\ []) do
    min_width = get_in(opts, [:min]) || 1
    max_width = get_in(opts, [:max])
    padding   = get_in(opts, [:padding])
    case {padding, min_width, max_width} do
      {:zeroes, _, nil}   -> Text.integer
      {:zeroes, min, max} -> choice(Enum.map(max..min, &(fixed_integer(&1))))
      {:spaces, -1, nil}  -> skip(spaces()) |> Text.integer
      {:spaces, min, nil} -> skip(spaces()) |> fixed_integer(min)
      {:spaces, _, max}   -> skip(spaces()) |> choice(Enum.map(max..1, &(fixed_integer(&1))))
      {_, -1, nil}        -> Text.integer
      {_, min, nil}       -> fixed_integer(min)
      {_, min, max}       -> choice(Enum.map(max..min, &(fixed_integer(&1))))
    end
  end
end
