defimpl Timex.Convertable, for: Map do
  alias Timex.Convertable

  def to_gregorian(map),         do: try_convert(map, &Convertable.to_gregorian/1)
  def to_julian(map),            do: try_convert(map, &Convertable.to_julian/1)
  def to_gregorian_seconds(map), do: try_convert(map, &Convertable.to_gregorian_seconds/1)
  def to_erlang_datetime(map),   do: try_convert(map, &Convertable.to_erlang_datetime/1)

  def to_date(map),      do: try_convert(map, &Convertable.to_date/1)
  def to_datetime(map),  do: try_convert(map, &Convertable.to_datetime/1)
  def to_unix(map),      do: try_convert(map, &Convertable.to_unix/1)
  def to_timestamp(map), do: try_convert(map, &Convertable.to_timestamp/1)

  defp try_convert(%{"year" => _, "month" => _, "day" => _} = map, fun) do
    case convert_keys(map) do
      {:error, _} = err ->
        err
      datetime_map when is_map(datetime_map) ->
        year  = Map.get(datetime_map, :year)
        month = Map.get(datetime_map, :month)
        day   = Map.get(datetime_map, :day)
        case Map.get(datetime_map, :hour) do
          nil ->
            case Convertable.to_date({year, month, day}) do
              {:error, _} = err -> err
              date -> fun.(date)
            end
          hour ->
            minute = Map.get(datetime_map, :minute, 0)
            second = Map.get(datetime_map, :second, 0)
            ms     = Map.get(datetime_map, :millisecond, 0)
            tz     = Map.get(datetime_map, :timezone, "UTC")
            tz = case tz do
              %{"full_name" => tzname} when is_binary(tzname) -> tzname
              tzname when is_binary(tzname) -> tzname
              _ -> "UTC"
            end
            case Timex.datetime({{year, month, day}, {hour, minute, second, ms}}, tz) do
              {:error, _} = err -> err
              datetime -> fun.(datetime)
            end
        end
    end
  end
  def try_convert(_), do: {:error, :invalid_date}

  @allowed_keys_atom [
    :year, :month, :day,
    :hour, :minute, :min, :mins, :second, :sec, :secs,
    :milliseconds, :millisecond, :ms
  ]
  @allowed_keys Enum.concat(@allowed_keys_atom, Enum.map(@allowed_keys_atom, &Atom.to_string/1))
  @valid_keys_map %{
    :min          => :minute,
    :mins         => :minute,
    :secs         => :second,
    :sec          => :second,
    :milliseconds => :millisecond,
    :ms           => :millisecond,
    :tz           => :timezone,
    :timezone     => :timezone
  }

  def convert_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {_, _}, {:error, _} = err -> err
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
      {k, v}, acc when k in [:tz, :timezone, "tz", "timezone"] ->
        Map.put(acc, :timezone, v)
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
