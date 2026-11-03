defmodule Timex.Format.Duration.Formatters.Humanized do
  @moduledoc """
  Handles formatting timestamp values as human readable strings.
  For formatting timestamps as points in time rather than intervals,
  use `Timex.format`
  """
  use Timex.Format.Duration.Formatter
  alias Timex.Translator
  alias Timex.Types

  @minute 60
  @hour @minute * 60
  @day @hour * 24
  @week @day * 7
  @month @day * 30
  @year @day * 365

  @microsecond 1_000_000

  @doc """
  Return a human readable string representing the absolute value of duration (i.e. would

  return the same output for both negative and positive representations of a given duration)

  ## Examples

      iex> use Timex
      ...> Duration.from_erl({0, 1, 1_000_000}) |> #{__MODULE__}.format
      "2 seconds"

      iex> use Timex
      ...> Duration.from_erl({0, 1, 1_000_100}) |> #{__MODULE__}.format
      "2 seconds, 100 microseconds"

      iex> use Timex
      ...> Duration.from_erl({0, 65, 0}) |> #{__MODULE__}.format
      "1 minute, 5 seconds"

      iex> use Timex
      ...> Duration.from_erl({0, -65, 0}) |> #{__MODULE__}.format
      "1 minute, 5 seconds"

      iex> use Timex
      ...> Duration.from_erl({1435, 180354, 590264}) |> #{__MODULE__}.format
      "45 years, 6 months, 5 days, 21 hours, 12 minutes, 34 seconds, 590.264 milliseconds"

  """
  @spec format(Duration.t()) :: String.t() | {:error, term}
  def format(%Duration{} = duration), do: lformat(duration, Translator.current_locale())
  def format(_), do: {:error, :invalid_duration}

  @doc """
  Return a human readable string representing the calendar distance between two
  datetimes, computing years/months from actual calendar arithmetic rather than
  fixed 365/30-day buckets.

  Naively bucketing the raw elapsed duration (as `format/1` does) misattributes
  any UTC offset change that occurs between `start` and `finish` (a DST
  transition, or a timezone's UTC offset changing permanently, as happened for
  `Pacific/Norfolk` on October 4, 2015) as spurious trailing hours/minutes. This
  function avoids that by first advancing `start` by the exact number of
  calendar years and months, and only converting the true remainder to a
  duration.

  ## Examples

      iex> use Timex
      ...> start = Timex.to_datetime({{2015, 1, 15}, {0, 0, 0}}, "Pacific/Norfolk")
      ...> finish = Timex.to_datetime({{2016, 3, 15}, {0, 0, 0}}, "Pacific/Norfolk")
      ...> #{__MODULE__}.format(start, finish)
      "1 year, 2 months"

  """
  @spec format(Types.valid_datetime(), Types.valid_datetime()) :: String.t() | {:error, term}
  def format(start, finish), do: lformat(start, finish, Translator.current_locale())

  @doc """
  Return a human readable string representing the time interval, translated to the given locale

  ## Examples

      iex> use Timex
      ...> Duration.from_erl({0, 65, 0}) |> #{__MODULE__}.lformat("ru")
      "1 минута, 5 секунд"

      iex> use Timex
      ...> Duration.from_erl({1435, 180354, 590264}) |> #{__MODULE__}.lformat("ru")
      "45 лет, 6 месяцев, 5 дней, 21 час, 12 минут, 34 секунды, 590.264 миллисекунд"

  """
  @spec lformat(Duration.t(), String.t()) :: String.t() | {:error, term}
  def lformat(%Duration{} = duration, locale) do
    duration
    |> deconstruct
    |> do_format(locale)
  end

  def lformat(_, _locale), do: {:error, :invalid_duration}

  @doc """
  Same as `format/2`, except it also accepts a locale to translate to.

  ## Examples

      iex> use Timex
      ...> start = Timex.to_datetime({{2015, 1, 15}, {0, 0, 0}}, "Pacific/Norfolk")
      ...> finish = Timex.to_datetime({{2016, 3, 15}, {0, 0, 0}}, "Pacific/Norfolk")
      ...> #{__MODULE__}.lformat(start, finish, "ru")
      "1 год, 2 месяца"

  """
  @spec lformat(Types.valid_datetime(), Types.valid_datetime(), String.t()) ::
          String.t() | {:error, term}
  def lformat(start, finish, locale) do
    with {:ok, years} <- to_int(Timex.diff(finish, start, :years)),
         {:ok, after_years} <- shifted(start, years: years),
         {:ok, months} <- to_int(Timex.diff(finish, after_years, :months)),
         {:ok, after_months} <- shifted(after_years, months: months),
         {:ok, remainder_us} <- to_int(Timex.diff(finish, after_months, :microseconds)) do
      calendar_components = for {unit, count} <- [year: years, month: months], count != 0, do: {unit, count}

      remainder_components =
        Duration.from_microseconds(remainder_us)
        |> deconstruct()
        |> Enum.reject(fn {_unit, count} -> count == 0 end)

      case calendar_components ++ remainder_components do
        [] -> do_format([{:microsecond, 0}], locale)
        components -> do_format(components, locale)
      end
    else
      {:error, _} = err -> err
    end
  end

  defp to_int(n) when is_integer(n), do: {:ok, n}
  defp to_int({:error, _} = err), do: err

  defp shifted(datetime, [{_unit, 0}]), do: {:ok, datetime}

  defp shifted(datetime, opts) do
    case Timex.shift(datetime, opts) do
      {:error, _} = err -> err
      shifted -> {:ok, shifted}
    end
  end

  defp do_format(components, locale),
    do: do_format(components, <<>>, locale)

  defp do_format([], str, _locale),
    do: str

  defp do_format([{unit, value} | rest], str, locale) do
    unit = Atom.to_string(unit)
    count = trunc(value)

    unit_with_value =
      Translator.translate_plural(locale, "units", "%{count} #{unit}", "%{count} #{unit}s", count)
      |> String.replace(to_string(count), to_string(value))

    separator = Translator.translate(locale, "symbols", ",")

    case str do
      <<>> -> do_format(rest, "#{unit_with_value}", locale)
      _ -> do_format(rest, str <> "#{separator} #{unit_with_value}", locale)
    end
  end

  defp deconstruct(duration) do
    micros = Duration.to_microseconds(duration) |> abs
    deconstruct({div(micros, @microsecond), rem(micros, @microsecond)}, [])
  end

  defp deconstruct({0, 0}, []),
    do: deconstruct({0, 0}, microsecond: 0)

  defp deconstruct({0, 0}, components),
    do: Enum.reverse(components)

  defp deconstruct({seconds, us}, components) when seconds > 0 do
    cond do
      seconds >= @year ->
        deconstruct({rem(seconds, @year), us}, [{:year, div(seconds, @year)} | components])

      seconds >= @month ->
        deconstruct({rem(seconds, @month), us}, [{:month, div(seconds, @month)} | components])

      seconds >= @week ->
        deconstruct({rem(seconds, @week), us}, [{:week, div(seconds, @week)} | components])

      seconds >= @day ->
        deconstruct({rem(seconds, @day), us}, [{:day, div(seconds, @day)} | components])

      seconds >= @hour ->
        deconstruct({rem(seconds, @hour), us}, [{:hour, div(seconds, @hour)} | components])

      seconds >= @minute ->
        deconstruct({rem(seconds, @minute), us}, [{:minute, div(seconds, @minute)} | components])

      true ->
        deconstruct({0, us}, [{:second, seconds} | components])
    end
  end

  defp deconstruct({0, micro}, components) do
    millis =
      micro
      |> Duration.from_microseconds()
      |> Duration.to_milliseconds()

    cond do
      millis >= 1 -> deconstruct({0, 0}, [{:millisecond, millis} | components])
      true -> deconstruct({0, 0}, [{:microsecond, micro} | components])
    end
  end
end
