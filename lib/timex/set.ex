defmodule Timex.Set do
  @moduledoc false

  alias Timex.{AmbiguousDateTime, AmbiguousTimezoneInfo, Timezone, TimezoneInfo}

  def set(date, options, error_name \\ :bad_option) do
    validate? = Keyword.get(options, :validate, true)

    with result when is_map(result) <-
           Enum.reduce(options, date, &replace(&2, &1, validate?, error_name)),
         result when is_map(result) <- if(validate?, do: normalize(result), else: result) do
      resolve_timezone(result, date, options, validate?)
    end
  end

  defp replace({:error, _} = error, _option, _validate?, _error_name), do: error
  defp replace(date, {:validate, _}, _validate?, _error_name), do: date
  defp replace(date, {:timezone, _}, _validate?, _error_name), do: date

  defp replace(date, {:datetime, {day, time}}, validate?, error_name) do
    date
    |> replace({:date, day}, validate?, error_name)
    |> replace({:time, time}, validate?, error_name)
  end

  defp replace(date, {:date, %Date{year: y, month: m, day: d}}, validate?, error_name),
    do: replace(date, {:date, {y, m, d}}, validate?, error_name)

  defp replace(date, {:date, {y, m, d}}, _validate?, _error_name),
    do: %{date | year: y, month: m, day: d}

  defp replace(%Date{} = date, {name, _}, _validate?, _error_name)
       when name in [:time, :hour, :minute, :second, :microsecond],
       do: date

  defp replace(date, {:time, %Time{} = time}, validate?, error_name),
    do:
      replace(
        date,
        {:time, {time.hour, time.minute, time.second, time.microsecond}},
        validate?,
        error_name
      )

  defp replace(date, {:time, {h, m, s}}, _validate?, _error_name),
    do: %{date | hour: h, minute: m, second: s}

  defp replace(date, {:time, {h, m, s, us}}, validate?, error_name) do
    %{date | hour: h, minute: m, second: s}
    |> replace({:microsecond, us}, validate?, error_name)
  end

  defp replace(date, {:microsecond, us}, true, _error_name),
    do: %{date | microsecond: Timex.normalize(:microsecond, us)}

  defp replace(date, {name, value}, _validate?, _error_name)
       when name in [:year, :month, :day, :hour, :minute, :second, :microsecond],
       do: Map.put(date, name, value)

  defp replace(_date, {name, _value}, _validate?, error_name),
    do: {:error, {error_name, name}}

  defp normalize(date) do
    with {year, month, day} <- Timex.normalize(:date, {date.year, date.month, date.day}) do
      date = %{date | year: year, month: month, day: day}

      case date do
        %Date{} ->
          date

        _ ->
          {hour, minute, second} = Timex.normalize(:time, {date.hour, date.minute, date.second})
          %{date | hour: hour, minute: minute, second: second}
      end
    end
  end

  defp resolve_timezone(%DateTime{} = result, original, options, validate?) do
    timezone =
      Enum.reduce(options, original.time_zone, fn
        {:timezone, timezone}, _ -> timezone
        _, timezone -> timezone
      end)

    cond do
      result == original and not Keyword.has_key?(options, :timezone) ->
        result

      validate? ->
        result |> DateTime.to_naive() |> Timezone.convert(timezone)

      Keyword.has_key?(options, :timezone) ->
        info =
          if is_struct(timezone, TimezoneInfo), do: timezone, else: Timezone.get(timezone, result)

        put_timezone(result, info)

      true ->
        result
    end
  end

  defp resolve_timezone(result, _original, _options, _validate?), do: result

  defp put_timezone(date, %TimezoneInfo{} = timezone) do
    %{
      date
      | time_zone: timezone.full_name,
        zone_abbr: timezone.abbreviation,
        utc_offset: timezone.offset_utc,
        std_offset: timezone.offset_std
    }
  end

  defp put_timezone(date, %AmbiguousTimezoneInfo{before: before, after: after_timezone}),
    do: %AmbiguousDateTime{
      before: put_timezone(date, before),
      after: put_timezone(date, after_timezone)
    }

  defp put_timezone(_date, {:error, _} = error), do: error
end
