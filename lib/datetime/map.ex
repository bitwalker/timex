defimpl Timex.Protocol, for: Map do
  @moduledoc """
  This is an implementation of Timex.Protocol for plain maps,
  which allows working directly with deserialized date/times
  via the Timex API. It accepts date/time maps with either atom
  or string keys, as long as those keys match current Calendar
  types. It also accepts a few legacy variations for types which
  may have been serialized with older versions of Timex.
  """

  defmacro convert!(map, function, args \\ []) when is_list(args) do
    quote do
      case Timex.Convert.convert_map(unquote(map)) do
        {:error, _} = err -> raise Timex.ConvertError, err
        converted -> Timex.Protocol.unquote(function)(converted, unquote_splicing(args))
      end
    end
  end

  defmacro convert(map, function, args \\ []) when is_list(args) do
    quote do
      case Timex.Convert.convert_map(unquote(map)) do
        {:error, _} = err -> err
        converted -> Timex.Protocol.unquote(function)(converted, unquote_splicing(args))
      end
    end
  end

  def to_julian(map), do: convert!(map, :to_julian)
  def to_gregorian_seconds(map), do: convert!(map, :to_gregorian_seconds)
  def to_gregorian_microseconds(map), do: convert!(map, :to_gregorian_microseconds)
  def to_unix(map), do: convert!(map, :to_unix)
  def to_date(map), do: convert!(map, :to_date)
  def to_datetime(map, timezone), do: convert(map, :to_datetime, [timezone])
  def to_naive_datetime(map), do: convert(map, :to_naive_datetime)
  def to_erl(map), do: convert(map, :to_erl)
  def century(map), do: convert!(map, :century)
  def is_leap?(map), do: convert!(map, :is_leap?)
  def shift(map, options), do: convert(map, :shift, [options])
  def set(map, options), do: convert(map, :set, [options])
  def beginning_of_day(map), do: convert!(map, :beginning_of_day)
  def end_of_day(map), do: convert!(map, :end_of_day)
  def beginning_of_week(map, start), do: convert(map, :beginning_of_week, [start])
  def end_of_week(map, start), do: convert(map, :end_of_week, [start])
  def beginning_of_year(map), do: convert!(map, :beginning_of_year)
  def end_of_year(map), do: convert!(map, :end_of_year)
  def beginning_of_quarter(map), do: convert!(map, :beginning_of_quarter)
  def end_of_quarter(map), do: convert!(map, :end_of_quarter)
  def beginning_of_month(map), do: convert!(map, :beginning_of_month)
  def end_of_month(map), do: convert!(map, :end_of_month)
  def quarter(map), do: convert!(map, :quarter)
  def days_in_month(map), do: convert!(map, :days_in_month)
  def week_of_month(map), do: convert!(map, :week_of_month)
  def weekday(map), do: convert!(map, :weekday)
  def weekday(map, weekstart), do: convert!(map, :weekday, [weekstart])
  def day(map), do: convert!(map, :day)
  def is_valid?(map), do: convert!(map, :is_valid?)
  def iso_week(map), do: convert!(map, :iso_week)
  def from_iso_day(map, day), do: convert(map, :from_iso_day, [day])
end
