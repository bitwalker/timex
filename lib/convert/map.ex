defimpl Timex.Convertable, for: Map do
  alias Timex.DateTime
  alias Timex.AmbiguousDateTime
  import Timex.Macros

  def to_gregorian(map),         do: try_convert(map, &Convertable.to_gregorian/1)
  def to_gregorian_seconds(map), do: try_convert(map, &Convertable.to_gregorian_seconds/1)
  def to_erlang_datetime(map),   do: try_convert(map, &Convertable.to_erlang_datetime/1)

  def to_date(map),      do: try_convert(map, &Convertable.to_date/1)
  def to_datetime(map),  do: try_convert(map, &Convertable.to_datetime/1)
  def to_unix(map),      do: try_convert(map, &Convertable.to_unix/1)
  def to_timestamp(map), do: try_convert(map, &Convertable.to_timestamp/1)

  defp try_convert(%{"year" => y, "month" => m, "day" => d, "hour" => h, "minute" => mm, "second" => s}, fun) do
    try_convert(%{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s}, fun)
  end
  defp try_convert(%{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s} = datetime, fun)
    when is_datetime(y,m,d,h,mm,s)
    do
    ms = case Map.get(datetime, :millisecond) do
           ms when is_positive_integer(ms) -> ms
           _ ->
             case Map.get(datetime, :ms) do
               ms when is_positive_integer(ms) -> ms
               _ -> 0
             end
         end
    case Convertable.to_datetime({{y,m,d}, {h,mm,s,ms}}) do
      {:error, _} = err ->
        err
      %DateTime{} = datetime ->
        fun.(datetime)
      %AmbiguousDateTime{} = ambiguous ->
        {:error, {:ambiguous_datetime, ambiguous}}
    end
  end
  defp try_convert(%{"year" => y, "month" => m, "day" => d}, fun) when is_date(y,m,d) do
    try_convert(%{:year => y, :month => m, :day => d}, fun)
  end
  defp try_convert(%{:year => y, :month => m, :day => d}, fun) when is_date(y,m,d) do
    case Convertable.to_datetime({y,m,d}) do
      {:error, _} = err ->
        err
      %DateTime{} = datetime ->
        fun.(datetime)
      %AmbiguousDateTime{} = ambiguous ->
        {:error, {:ambiguous_datetime, ambiguous}}
    end
  end
  def try_convert(_), do: {:error, :invalid_date}
end
