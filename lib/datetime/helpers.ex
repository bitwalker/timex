defmodule Timex.DateTime.Helpers do
  @moduledoc false

  alias Timex.{Types, Timezone, TimezoneInfo, AmbiguousDateTime, AmbiguousTimezoneInfo}

  @doc """
  Constructs an empty DateTime, for internal use only
  """
  def empty() do
    %DateTime{year: 0, month: 1, day: 1,
              hour: 0, minute: 0, second: 0,
              microsecond: {0,0},
              time_zone: nil,
              zone_abbr: nil,
              utc_offset: 0, std_offset: 0}
  end

  @doc """
  Constructs a DateTime from an Erlang date or datetime tuple and a timezone.

  Intended for internal use only.
  """
  @spec construct(Types.date, Types.valid_timezone) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  @spec construct(Types.datetime, Types.valid_timezone) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  def construct({_, _, _} = date, timezone) do
    construct({date, {0,0,0,0}}, timezone)
  end
  def construct({{_,_,_} = date, {h,mm,s}}, timezone) do
    construct({date,{h,mm,s,0}}, timezone)
  end
  def construct({{y,m,d}, {h,mm,s,us}} = datetime, timezone) do
    seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds(datetime)
    case Timezone.name_of(timezone) do
      {:error, _} = err -> err
      tzname ->
        case Timezone.resolve(tzname, seconds_from_zeroyear) do
          {:error, _} = err -> err
          %TimezoneInfo{} = tz ->
            %DateTime{:year => y, :month => m, :day => d,
                      :hour => h, :minute => mm, :second => s,
                      :microsecond => construct_microseconds(us),
                      :time_zone => tz.full_name, :zone_abbr => tz.abbreviation,
                      :utc_offset => tz.offset_utc, :std_offset => tz.offset_std}
          %AmbiguousTimezoneInfo{before: b, after: a} ->
            bd = %DateTime{:year => y, :month => m, :day => d,
                           :hour => h, :minute => mm, :second => s,
                           :microsecond => construct_microseconds(us),
                           :time_zone => b.full_name, :zone_abbr => b.abbreviation,
                           :utc_offset => b.offset_utc, :std_offset => b.offset_std}
            ad = %DateTime{:year => y, :month => m, :day => d,
                           :hour => h, :minute => mm, :second => s,
                           :microsecond => construct_microseconds(us),
                           :time_zone => a.full_name, :zone_abbr => a.abbreviation,
                           :utc_offset => a.offset_utc, :std_offset => a.offset_std}
            %AmbiguousDateTime{before: bd, after: ad}
        end
    end
  end

  def construct_microseconds(0), do: {0,0}
  def construct_microseconds(n) when n < 10, do: {n,1}
  def construct_microseconds(n) when n < 100, do: {n,2}
  def construct_microseconds(n) when n < 1_000, do: {n,3}
  def construct_microseconds(n) when n < 10_000, do: {n,4}
  def construct_microseconds(n) when n < 100_000, do: {n,5}
  def construct_microseconds(n) when n < 1_000_000, do: {n,6}
end
