defmodule Timex.Convert do
  @moduledoc false

  @doc """
  Converts a map to a Date, NaiveDateTime or DateTime, depending on the amount
  of date/time information in the map.
  """
  @spec convert_map(map) :: Date.t() | DateTime.t() | NaiveDateTime.t() | {:error, term}
  def convert_map(%{__struct__: _} = struct) do
    convert_map(Map.from_struct(struct))
  end

  def convert_map(map) when is_map(map) do
    case convert_keys(map) do
      {:error, _} = err ->
        err

      datetime_map when is_map(datetime_map) ->
        year = Map.get(datetime_map, :year)
        month = Map.get(datetime_map, :month)
        day = Map.get(datetime_map, :day)

        cond do
          not is_nil(year) and not is_nil(month) and not is_nil(day) ->
            case Map.get(datetime_map, :hour) do
              nil ->
                with {:ok, date} <- Date.new(year, month, day), do: date

              hour ->
                minute = Map.get(datetime_map, :minute, 0)
                second = Map.get(datetime_map, :second, 0)
                us = Map.get(datetime_map, :microsecond, {0, 0})
                tz = Map.get(datetime_map, :time_zone, nil)

                {us, precision} =
                  case us do
                    {_us, _precision} = val ->
                      val

                    us when is_integer(us) ->
                      Timex.DateTime.Helpers.construct_microseconds(us, -1)
                  end

                case tz do
                  s when is_binary(s) ->
                    Timex.DateTime.Helpers.construct(
                      {{year, month, day}, {hour, minute, second, us}},
                      precision,
                      tz
                    )

                  nil ->
                    {:ok, nd} =
                      NaiveDateTime.new(year, month, day, hour, minute, second, {us, precision})

                    nd
                end
            end

          :else ->
            {:error, :insufficient_date_information}
        end
    end
  end

  def try_convert(_), do: {:error, :invalid_date}

  @allowed_keys_atom [
    :year,
    :month,
    :day,
    :hour,
    :minute,
    :min,
    :mins,
    :second,
    :sec,
    :secs,
    :milliseconds,
    :millisecond,
    :ms,
    :microsecond
  ]
  @allowed_keys Enum.concat(@allowed_keys_atom, Enum.map(@allowed_keys_atom, &Atom.to_string/1))
  @valid_keys_map %{
    :min => :minute,
    :mins => :minute,
    :secs => :second,
    :sec => :second,
    :milliseconds => :millisecond,
    :ms => :millisecond,
    :microsecond => :microsecond,
    :tz => :time_zone,
    :timezone => :time_zone,
    :time_zone => :time_zone
  }

  def convert_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {_, _}, {:error, _} = err ->
        err

      {k, v}, acc when k in [:microsecond, "microsecond"] ->
        case v do
          {us, pr} when is_integer(us) and pr >= 0 and pr <= 6 ->
            Map.put(acc, :microsecond, {us, pr})

          us when is_integer(us) ->
            Map.put(acc, :microsecond, {us, 6})

          _ ->
            acc
        end

      {k, v}, acc
      when k in [:milliseconds, "milliseconds", :ms, "ms", :millisecond, "millisecond"] ->
        case v do
          n when is_integer(n) ->
            us = Timex.DateTime.Helpers.construct_microseconds(n * 1_000, -1)
            Map.put(acc, :microsecond, us)

          :error ->
            {:error, {:expected_integer, for: k, got: v}}
        end

      {k, v}, acc when k in [:tz, "tz", :timezone, "timezone", :time_zone, "time_zone"] ->
        case v do
          s when is_binary(s) -> Map.put(acc, :time_zone, s)
          %{"full_name" => s} -> Map.put(acc, :time_zone, s)
          _ -> acc
        end

      {k, v}, acc when k in @allowed_keys and is_integer(v) ->
        Map.put(acc, get_valid_key(k), v)

      {k, v}, acc when k in @allowed_keys and is_binary(v) ->
        case Integer.parse(v) do
          {n, _} ->
            Map.put(acc, get_valid_key(k), n)

          :error ->
            {:error, {:expected_integer, for: k, got: v}}
        end

      {_, _}, acc ->
        acc
    end)
  end

  defp get_valid_key(key) when is_atom(key),
    do: Map.get(@valid_keys_map, key, key)

  defp get_valid_key(key),
    do: key |> String.to_atom() |> get_valid_key()
end
