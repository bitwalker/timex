defmodule Timex.Convert do
  @moduledoc false

  @doc """
  Converts a map to a Date, NaiveDateTime or DateTime, depending on the amount
  of date/time information in the map.
  """
  @spec convert_map(Map.t) :: Date.t | DateTime.t | NaiveDateTime.t | {:error, term}
  def convert_map(map) when is_map(map) do
    case convert_keys(map) do
      {:error, _} = err ->
        err
      datetime_map when is_map(datetime_map) ->
        year  = Map.get(datetime_map, :year)
        month = Map.get(datetime_map, :month)
        day   = Map.get(datetime_map, :day)
        cond do
          not(is_nil(year)) and not(is_nil(month)) and not(is_nil(day)) ->
            case Map.get(datetime_map, :hour) do
              nil ->
                Date.new(year, month, day)
              hour ->
                minute = Map.get(datetime_map, :minute, 0)
                second = Map.get(datetime_map, :second, 0)
                us     = Map.get(datetime_map, :microsecond, {0, 6})
                tz     = Map.get(datetime_map, :time_zone, nil)
                case tz do
                  s when is_binary(s) ->
                    Timex.DateTime.Helpers.construct({{year,month,day},{hour,minute,second,us}}, tz)
                  nil ->
                    {:ok, nd} = NaiveDateTime.new(year, month, day, minute, second, us)
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
    :year, :month, :day,
    :hour, :minute, :min, :mins, :second, :sec, :secs,
    :milliseconds, :millisecond, :ms,
    :microsecond
  ]
  @allowed_keys Enum.concat(@allowed_keys_atom, Enum.map(@allowed_keys_atom, &Atom.to_string/1))
  @valid_keys_map %{
    :min          => :minute,
    :mins         => :minute,
    :secs         => :second,
    :sec          => :second,
    :milliseconds => :millisecond,
    :ms           => :millisecond,
    :microsecond  => :microsecond,
    :tz           => :time_zone,
    :timezone     => :time_zone,
    :time_zone    => :time_zone
  }

  def convert_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {_, _}, {:error, _} = err -> err
      {k, v}, acc when k in [:microsecond, "microsecond"] ->
        case v do
          {us, pr} when is_integer(us) and pr >= 0 and pr <= 6 ->
            Map.put(acc, :microsecond, {us, pr})
          us when is_integer(us) ->
            Map.put(acc, :microsecond, {us, 6})
          _ -> acc
        end
      {k, v}, acc when k in [:milliseconds, "milliseconds", :ms, "ms", :millisecond, "millisecond"] ->
        case Integer.parse(v) do
          {n, _} ->
            Map.put(acc, :microsecond, {n*1_000, 6})
          :error ->
            {:error, {:expected_integer, for: k, got: v}}
        end
      {k, v}, acc when k in [:tz, "tz", :timezone, "timezone", :time_zone, "time_zone"] ->
        case v do
          s when is_binary(s) -> Map.put(acc, :time_zone, s)
          %{"full_name" => s} -> Map.put(acc, :time_zone, s)
          _ -> acc
        end
      {k, v}, acc when k in @allowed_keys and is_atom(k) and is_integer(v) ->
        case Map.get(@valid_keys_map, k) do
          nil -> Map.put(acc, k, v)
          vk  -> Map.put(acc, vk, v)
        end
      {k, v}, acc when k in @allowed_keys and is_integer(v) ->
        ak = String.to_atom(k)
        case Map.get(@valid_keys_map, ak) do
          nil -> Map.put(acc, ak, v)
          vk  -> Map.put(acc, vk, v)
        end
      {k, v}, acc when k in @allowed_keys and is_atom(k) and is_binary(v) ->
        case Integer.parse(v) do
          {n, _} ->
            case Map.get(@valid_keys_map, k) do
              nil -> Map.put(acc, k, n)
              vk  -> Map.put(acc, vk, n)
            end
          :error ->
            {:error, {:expected_integer, for: k, got: v}}
        end
      {k, v}, acc when k in @allowed_keys and is_binary(v) ->
        case Integer.parse(v) do
          {n, _} ->
            ak = String.to_atom(k)
            case Map.get(@valid_keys_map, ak) do
              nil -> Map.put(acc, ak, n)
              vk  -> Map.put(acc, vk, n)
            end
          :error ->
            {:error, {:expected_integer, for: k, got: v}}
        end
      {_, _}, acc -> acc
    end)
  end
end
