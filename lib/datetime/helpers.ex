defmodule Timex.DateTime.Helpers do
  @moduledoc false

  alias Timex.{Types, Timezone, TimezoneInfo, AmbiguousDateTime, AmbiguousTimezoneInfo}

  @type precision :: -1 | 0..6

  @doc """
  Constructs an empty NaiveDateTime, for internal use only
  """
  def empty(), do: Timex.NaiveDateTime.new!(0, 1, 1, 0, 0, 0)

  @doc """
  Constructs a DateTime from an Erlang date or datetime tuple and a timezone.

  Intended for internal use only.
  """
  @spec construct(Types.date(), Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  @spec construct(Types.datetime(), Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  @spec construct(Types.microsecond_datetime(), Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  @spec construct(Types.microsecond_datetime(), precision, Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}
  def construct({_, _, _} = date, timezone) do
    construct({date, {0, 0, 0, 0}}, 0, timezone)
  end

  def construct({{_, _, _} = date, {h, mm, s}}, timezone) do
    construct({date, {h, mm, s, 0}}, 0, timezone)
  end

  def construct({{_, _, _} = date, {_, _, _, _} = time}, timezone) do
    construct({date, time}, -1, timezone)
  end

  def construct({{_, _, _} = date, {_, _, _, _} = time}, precision, timezone) do
    construct({date, time}, precision, timezone, :wall)
  end

  def construct({{y, m, d} = date, {h, mm, s, us}}, precision, timezone, utc_or_wall) do
    seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds({date, {h, mm, s}})

    case Timezone.name_of(timezone) do
      {:error, _} = err ->
        err

      tzname ->
        case Timezone.resolve(tzname, seconds_from_zeroyear, utc_or_wall) do
          {:error, _} = err ->
            err

          %TimezoneInfo{} = tz ->
            %DateTime{
              :year => y,
              :month => m,
              :day => d,
              :hour => h,
              :minute => mm,
              :second => s,
              :microsecond => construct_microseconds(us, precision),
              :time_zone => tz.full_name,
              :zone_abbr => tz.abbreviation,
              :utc_offset => tz.offset_utc,
              :std_offset => tz.offset_std
            }

          %AmbiguousTimezoneInfo{before: b, after: a} ->
            bd = %DateTime{
              :year => y,
              :month => m,
              :day => d,
              :hour => h,
              :minute => mm,
              :second => s,
              :microsecond => construct_microseconds(us, precision),
              :time_zone => b.full_name,
              :zone_abbr => b.abbreviation,
              :utc_offset => b.offset_utc,
              :std_offset => b.offset_std
            }

            ad = %DateTime{
              :year => y,
              :month => m,
              :day => d,
              :hour => h,
              :minute => mm,
              :second => s,
              :microsecond => construct_microseconds(us, precision),
              :time_zone => a.full_name,
              :zone_abbr => a.abbreviation,
              :utc_offset => a.offset_utc,
              :std_offset => a.offset_std
            }

            %AmbiguousDateTime{before: bd, after: ad}
        end
    end
  end

  def construct_microseconds({us, p}) when is_integer(us) and is_integer(p) do
    construct_microseconds(us, p)
  end

  def construct_microseconds(us) when is_integer(us) do
    construct_microseconds(us, -1)
  end

  # Input precision of -1 means it should be recalculated based on the value
  def construct_microseconds(0, -1), do: {0, 0}
  def construct_microseconds(0, p), do: {0, p}
  def construct_microseconds(n, -1), do: {n, precision(n)}
  def construct_microseconds(n, p), do: {to_precision(n, p), p}

  def to_precision(0, _p), do: 0

  def to_precision(_, 0), do: 0

  def to_precision(us, p) do
    case precision(us) do
      detected_p when detected_p > p ->
        # Convert to lower precision
        pow = trunc(:math.pow(10, detected_p - p))
        Integer.floor_div(us, pow) * pow

      _detected_p ->
        # Already correct precision or less precise
        us
    end
  end

  def precision(0), do: 0

  def precision(n) when is_integer(n) do
    ns = Integer.to_string(n)
    n_width = byte_size(ns)
    trimmed = byte_size(String.trim_trailing(ns, "0"))
    new_p = 6 - (n_width - trimmed)

    if new_p >= 6 do
      6
    else
      new_p
    end
  end
end
