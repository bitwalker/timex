defmodule Timex.Timezone do
  @moduledoc """
  This module is used for looking up the timezone information for
  a given point in time, in the desired zone. Timezones are dependent
  not only on locale, but the date and time for which you are querying.
  For instance, the timezone offset from UTC for `Europe/Moscow` is different
  for March 3rd of 2015, than it was in 2013. These differences are important,
  and as such, all functions in this module are date/time sensitive, and where
  omitted, the current date/time are assumed.

  In addition to lookups, this module also does conversion of datetimes from one
  timezone period to another, and determining the difference between a date in one
  timezone period and the same date/time in another timezone period.
  """
  alias Timex.AmbiguousDateTime
  alias Timex.TimezoneInfo
  alias Timex.AmbiguousTimezoneInfo
  alias Timex.Timezone.Local, as: Local
  alias Timex.Parse.Timezones.Posix
  alias Timex.Parse.Timezones.Posix.PosixTimezone, as: PosixTz
  alias Timex.Types

  @behaviour Calendar.TimeZoneDatabase

  @doc """
  Determines if a given zone name exists
  """
  @spec exists?(String.t()) :: boolean
  def exists?(zone) when is_binary(zone) do
    if Tzdata.zone_exists?(zone) do
      true
    else
      case lookup_posix(zone) do
        tz when is_binary(tz) -> true
        _ -> false
      end
    end
  end

  @doc """
  Gets the local timezone configuration for the current date and time.
  """
  @spec local() :: TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  def local(), do: local(:calendar.universal_time())

  @doc """
  Gets the local timezone configuration for the provided date and time.
  The provided date and time can either be an Erlang datetime tuple, or a DateTime struct.
  """
  @spec local(Types.valid_datetime()) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  def local(date) do
    secs = Timex.to_gregorian_seconds(date)

    case Local.lookup() do
      {:error, _} = err ->
        err

      tz ->
        resolve(tz, secs)
    end
  end

  @doc """
  This function takes one of the varying timezone representations:

    - atoms
    - offset integers
    - shortcut names (i.e. :utc, :local, "Z", "A")

  and resolves the full name of the timezone if it's able.

  If a string is provided which isn't recognized, it is returned untouched,
  only when `get/2` is called will the timezone lookup fail.
  """
  @spec name_of(Types.valid_timezone() | TimezoneInfo.t() | AmbiguousTimezoneInfo.t()) ::
          String.t()
          | {:error, {:invalid_timezone, term}}
          | {:error, {:no_such_zone, term}}
          | {:error, term}
  def name_of(%TimezoneInfo{:full_name => name}), do: name
  def name_of(:utc), do: "Etc/UTC"

  def name_of(:local) do
    case local(DateTime.utc_now()) do
      {:error, _} = err -> err
      tz -> name_of(tz)
    end
  end

  def name_of("UTC"), do: "Etc/UTC"
  def name_of(0), do: "Etc/UTC"
  def name_of("A"), do: name_of(1)
  def name_of("M"), do: name_of(12)
  def name_of("N"), do: name_of(-1)
  def name_of("Y"), do: name_of(-12)
  def name_of("Z"), do: "Etc/UTC"
  def name_of("UT"), do: "Etc/UTC"

  def name_of(offset) when is_integer(offset) do
    if offset > 0 do
      "Etc/GMT-#{offset}"
    else
      "Etc/GMT+#{offset * -1}"
    end
  end

  def name_of(offset) when is_float(offset) do
    IO.warn(
      "use of floating point offsets is dangerous as they are not guaranteed to be precise " <>
        "it is recommended that you use either a proper Olson timezone name, or build a timezone info manually " <>
        "with Timex.Timezone.create/6"
    )

    if offset > 0 do
      "Etc/GMT-#{offset}"
    else
      "Etc/GMT+#{offset * -1}"
    end
  end

  def name_of(<<?+, ?0, ?0, ?:, ?0, ?0>>) do
    "Etc/UTC"
  end

  def name_of(<<?+, h1::utf8, h2::utf8, ?:, ?0, ?0>>) do
    "Etc/GMT-" <> <<h1::utf8, h2::utf8>>
  end

  def name_of(<<?+, h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>>) do
    "Etc/GMT-" <> <<h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>>
  end

  def name_of(<<?+, offset::binary>> = tz) do
    case Integer.parse(offset) do
      {num, _} ->
        cond do
          num >= 100 -> name_of(trunc(num / 100))
          true -> name_of(num)
        end

      :error ->
        {:error, {:no_such_zone, tz}}
    end
  end

  def name_of(<<?-, ?0, ?0, ?:, ?0, ?0>>) do
    "Etc/UTC"
  end

  def name_of(<<?-, h1::utf8, h2::utf8, ?:, ?0, ?0>>) do
    "Etc/GMT+" <> <<h1::utf8, h2::utf8>>
  end

  def name_of(<<?-, h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>>) do
    "Etc/GMT+" <> <<h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>>
  end

  def name_of(<<?-, offset::binary>> = tz) do
    case Integer.parse(offset) do
      {num, _} ->
        cond do
          num >= 100 -> name_of(trunc(num / 100) * -1)
          true -> name_of(num * -1)
        end

      :error ->
        {:error, {:no_such_zone, tz}}
    end
  end

  def name_of(<<"GMT", ?+, offset::binary>>), do: "Etc/GMT+#{offset}"
  def name_of(<<"GMT", ?-, offset::binary>>), do: "Etc/GMT-#{offset}"

  def name_of(tz) when is_binary(tz) do
    if Tzdata.zone_exists?(tz) do
      tz
    else
      case lookup_posix(tz) do
        full_name when is_binary(full_name) ->
          full_name

        nil ->
          {:error, {:invalid_timezone, tz}}
      end
    end
  end

  def name_of(tz), do: {:error, {:invalid_timezone, tz}}

  @doc """
  Gets timezone info for a given zone name and date. The date provided
  can either be an Erlang datetime tuple, or a DateTime struct, and if one
  is not provided, then the current date and time is returned.
  """
  @spec get(Types.valid_timezone()) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  @spec get(Types.valid_timezone(), Types.valid_datetime()) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  def get(tz, datetime \\ :calendar.universal_time())

  def get(:utc, _datetime), do: %TimezoneInfo{}
  def get(:local, datetime), do: local(datetime)

  def get(tz, datetime) do
    case name_of(tz) do
      {:error, _} = err ->
        err

      "Etc/UTC" ->
        %TimezoneInfo{}

      name ->
        do_get(name, datetime)
    end
  end

  defp do_get(timezone, datetime, utc_or_wall \\ :wall)

  defp do_get("Etc/GMT+" <> offset, _datetime, _utc_or_wall) do
    {suffix, offset_secs} = parse_offset(offset)

    %TimezoneInfo{
      full_name: "Etc/GMT+" <> suffix,
      abbreviation: "-" <> offset,
      offset_std: 0,
      offset_utc: offset_secs * -1,
      from: :min,
      until: :max
    }
  end

  defp do_get("Etc/GMT-" <> offset, _datetime, _utc_or_wall) do
    {suffix, offset_secs} = parse_offset(offset)

    %TimezoneInfo{
      full_name: "Etc/GMT-" <> suffix,
      abbreviation: "+" <> offset,
      offset_std: 0,
      offset_utc: offset_secs,
      from: :min,
      until: :max
    }
  end

  defp do_get(timezone, datetime, utc_or_wall) do
    name = name_of(timezone)
    seconds_from_zeroyear = Timex.to_gregorian_seconds(datetime)

    case name do
      "Etc/GMT-" <> _offset ->
        do_get(name, datetime, utc_or_wall)

      "Etc/GMT+" <> _offset ->
        do_get(name, datetime, utc_or_wall)

      _ ->
        case Tzdata.zone_exists?(name) do
          false ->
            lookup_timezone_by_abbreviation(name, seconds_from_zeroyear, utc_or_wall)

          true ->
            resolve(name, seconds_from_zeroyear, utc_or_wall)
        end
    end
  end

  defp parse_offset(<<?0, h2::utf8, ?:, m1::utf8, m2::utf8, ?:, s1::utf8, s2::utf8>>) do
    secs = String.to_integer(<<h2::utf8>>) * 60 * 60
    secs = secs + String.to_integer(<<m1::utf8, m2::utf8>>) * 60
    secs = secs + String.to_integer(<<s1::utf8, s2::utf8>>)
    {<<h2::utf8, ?:, m1::utf8, m2::utf8, ?:, s1::utf8, s2::utf8>>, secs}
  end

  defp parse_offset(
         <<h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8, ?:, s1::utf8, s2::utf8>> = suffix
       ) do
    secs = String.to_integer(<<h1::utf8, h2::utf8>>) * 60 * 60
    secs = secs + String.to_integer(<<m1::utf8, m2::utf8>>) * 60
    secs = secs + String.to_integer(<<s1::utf8, s2::utf8>>)
    {suffix, secs}
  end

  defp parse_offset(<<?0, h2::utf8, ?:, m1::utf8, m2::utf8>>) do
    secs = String.to_integer(<<h2::utf8>>) * 60 * 60
    secs = secs + String.to_integer(<<m1::utf8, m2::utf8>>) * 60
    {<<h2::utf8, ?:, m1::utf8, m2::utf8>>, secs}
  end

  defp parse_offset(<<h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>> = suffix) do
    secs = String.to_integer(<<h1::utf8, h2::utf8>>) * 60 * 60
    secs = secs + String.to_integer(<<m1::utf8, m2::utf8>>) * 60
    {suffix, secs}
  end

  defp parse_offset(<<?0, h2::utf8>>) do
    secs = String.to_integer(<<h2::utf8>>) * 60 * 60
    {<<h2::utf8>>, secs}
  end

  defp parse_offset(<<h1::utf8, h2::utf8>> = suffix) do
    secs = String.to_integer(<<h1::utf8, h2::utf8>>) * 60 * 60
    {suffix, secs}
  end

  defp parse_offset(<<h1::utf8, h2::utf8, ?., rest::binary>>) do
    hours = String.to_integer(<<h1::utf8, h2::utf8>>)
    hours = hours + String.to_float(<<?0, ?., rest::binary>>)
    secs = trunc(Float.round(hours * 60 * 60))
    mm = div(rem(secs, 60 * 60), 60)

    {m1, m2} =
      cond do
        mm > 9 ->
          <<m1::utf8, m2::utf8>> = Integer.to_string(mm)
          {m1, m2}

        :else ->
          <<m2::utf8>> = Integer.to_string(mm)
          {?0, m2}
      end

    {<<h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8>>, secs}
  end

  defp parse_offset(<<h2::utf8, ?., rest::binary>>) do
    parse_offset(<<?0, h2::utf8, ?., rest::binary>>)
  end

  defp parse_offset("0"), do: {"0", 0}

  defp parse_offset(<<h1::utf8>> = suffix),
    do: {suffix, String.to_integer(<<h1::utf8>>) * 60 * 60}

  def total_offset(%TimezoneInfo{offset_std: std, offset_utc: utc}) do
    utc + std
  end

  def total_offset(std_offset, utc_offset)
      when is_integer(std_offset) and is_integer(utc_offset) do
    utc_offset + std_offset
  end

  @doc """
  Given a timezone name as a string, and a date/time in the form of the number of seconds since year zero,
  attempt to resolve a TimezoneInfo for that date/time. If the time is ambiguous, AmbiguousTimezoneInfo will
  be returned. If no result is found, an error will be returned.

  If an invalid zone name is provided, an error will be returned
  """
  @spec resolve(String.t(), non_neg_integer, :utc | :wall) ::
          TimezoneInfo.t()
          | AmbiguousTimezoneInfo.t()
          | {:error, term}
  def resolve(tzname, datetime, utc_or_wall \\ :wall)

  def resolve(name, seconds_from_zeroyear, utc_or_wall)
      when is_binary(name) and is_integer(seconds_from_zeroyear) and utc_or_wall in [:utc, :wall] do
    case Tzdata.zone_exists?(name) do
      false ->
        # Timezone doesn't exist, so it must be either a custom timezone, or an odd offset
        case name do
          "Etc/GMT" <> _offset ->
            do_get(
              name,
              :calendar.gregorian_seconds_to_datetime(seconds_from_zeroyear),
              utc_or_wall
            )

          _ ->
            {:error, {:unknown_timezone, name}}
        end

      true ->
        case Tzdata.periods_for_time(name, seconds_from_zeroyear, utc_or_wall) do
          [] ->
            {:error, {:could_not_resolve_timezone, name, seconds_from_zeroyear, utc_or_wall}}

          # Resolved
          [period] ->
            tzdata_to_timezone(period, name)

          # This case happens when using wall clock time, we resolve it by using UTC clock time instead
          [before_period, after_period | _] ->
            case Tzdata.periods_for_time(name, seconds_from_zeroyear, :utc) do
              [] ->
                # We can't resolve it this way, I don't expect this to be possible, but we handle it
                before_tz = tzdata_to_timezone(before_period, name)
                after_tz = tzdata_to_timezone(after_period, name)
                AmbiguousTimezoneInfo.new(before_tz, after_tz)

              [period] ->
                tzdata_to_timezone(period, name)

              _ ->
                # Still ambiguous, use wall clock time for info passed back to caller
                before_tz = tzdata_to_timezone(before_period, name)
                after_tz = tzdata_to_timezone(after_period, name)
                AmbiguousTimezoneInfo.new(before_tz, after_tz)
            end
        end
    end
  end

  @doc """
  Convert a date to the given timezone (either TimezoneInfo or a timezone name)
  """
  @spec convert(date :: DateTime.t(), tz :: AmbiguousTimezoneInfo.t()) ::
          AmbiguousDateTime.t() | {:error, term}
  @spec convert(date :: DateTime.t(), tz :: TimezoneInfo.t() | Types.valid_timezone()) ::
          DateTime.t() | AmbiguousDateTime.t() | {:error, term}

  def convert(%DateTime{} = date, %AmbiguousTimezoneInfo{} = tz) do
    before_date = convert(date, tz.before)
    after_date = convert(date, tz.after)
    %AmbiguousDateTime{:before => before_date, :after => after_date}
  end

  def convert(%DateTime{time_zone: name} = date, %TimezoneInfo{full_name: name}) do
    # Do not convert date when already in destination time zone
    date
  end

  def convert(%DateTime{} = date, %TimezoneInfo{full_name: name} = tzinfo) do
    with {:ok, datetime} <- DateTime.shift_zone(date, name, Timex.tzdb()) do
      datetime
    else
      {ty, a, b} when ty in [:gap, :ambiguous] ->
        %AmbiguousDateTime{before: a, after: b, type: ty}

      {:error, :time_zone_not_found} ->
        convert_fallback(date, tzinfo)

      {:error, _} = err ->
        err
    end
  end

  def convert(%DateTime{} = date, tz) do
    case do_get(tz, date, :utc) do
      {:error, _} = err ->
        err

      timezone ->
        convert(date, timezone)
    end
  end

  def convert(date, tz) do
    case Timex.to_datetime(date, tz) do
      {:error, _} = err ->
        err

      datetime ->
        datetime
    end
  end

  defp convert_fallback(%DateTime{} = date, %TimezoneInfo{full_name: name} = tzinfo) do
    # Temporarily push the custom tzinfo into process state for our database
    Process.put(__MODULE__.Database, tzinfo)

    with {:ok, datetime} <- DateTime.shift_zone(date, name, __MODULE__) do
      datetime
    end
  end

  @impl Calendar.TimeZoneDatabase
  @doc false
  def time_zone_period_from_utc_iso_days(iso_days, time_zone) do
    # Get a NaiveDateTime for time_zone_periods_from_wall_datetime
    {year, month, day, hour, minute, second, microsecond} =
      Calendar.ISO.naive_datetime_from_iso_days(iso_days)

    with {:ok, naive} <- NaiveDateTime.new(year, month, day, hour, minute, second, microsecond) do
      time_zone_periods_from_wall_datetime(naive, time_zone)
    else
      {:error, _} ->
        {:error, :time_zone_not_found}
    end
  end

  @impl Calendar.TimeZoneDatabase
  @doc false
  def time_zone_periods_from_wall_datetime(naive, _time_zone) do
    # Pop the time zone from process state, validate the desired datetime falls
    # within the bounds of the time zone, and return its period description if so
    %TimezoneInfo{from: from, until: until} = tz = Process.put(__MODULE__.Database, nil)

    with {:ok, range_start} <- period_boundary_to_naive(from),
         {:ok, range_end} <- period_boundary_to_naive(until) do
      cond do
        range_start == :min and range_end == :max ->
          {:ok, TimezoneInfo.to_period(tz)}

        range_start == :min and NaiveDateTime.compare(naive, range_end) in [:lt, :eq] ->
          {:ok, TimezoneInfo.to_period(tz)}

        range_end == :max and NaiveDateTime.compare(naive, range_start) in [:gt, :eq] ->
          {:ok, TimezoneInfo.to_period(tz)}

        range_start != :min and range_end != :max and
          NaiveDateTime.compare(naive, range_start) in [:gt, :eq] and
            NaiveDateTime.compare(naive, range_end) in [:lt, :eq] ->
          {:ok, TimezoneInfo.to_period(tz)}

        :else ->
          {:error, :time_zone_not_found}
      end
    else
      {:error, _} ->
        {:error, :time_zone_not_found}
    end
  end

  defp period_boundary_to_naive(:min), do: {:ok, :min}
  defp period_boundary_to_naive(:max), do: {:ok, :max}

  defp period_boundary_to_naive({_, {{y, m, d}, {hh, mm, ss}}}) do
    NaiveDateTime.new(y, m, d, hh, mm, ss)
  end

  defp period_boundary_to_naive(_), do: {:error, :invalid_period}

  @doc """
  Shifts the provided DateTime to the beginning of the day in it's timezone
  """
  @spec beginning_of_day(DateTime.t()) :: DateTime.t()
  def beginning_of_day(%DateTime{time_zone: tz, microsecond: {_, precision}} = dt) do
    do_beginning_of_day(dt, tz, {{dt.year, dt.month, dt.day}, {0, 0, 0}}, precision)
  end

  defp do_beginning_of_day(%DateTime{} = dt, tz, {date, {h, _, _}} = day_start, precision) do
    abs_start = :calendar.datetime_to_gregorian_seconds(day_start)

    case Tzdata.zone_exists?(tz) do
      true ->
        case Tzdata.periods_for_time(tz, abs_start, :wall) do
          # This hour does not exist, so move ahead one and try again
          [] ->
            do_beginning_of_day(dt, tz, {date, {h + 1, 0, 0}}, precision)

          # Only one period applies
          [%{utc_off: utc_offset, std_off: std_offset, zone_abbr: abbr}] ->
            %{
              dt
              | :hour => h,
                :minute => 0,
                :second => 0,
                :microsecond => {0, precision},
                :utc_offset => utc_offset,
                :std_offset => std_offset,
                :zone_abbr => abbr
            }

          # Ambiguous, choose the earliest one in the same day which is unambiguous
          [_, _] ->
            do_beginning_of_day(dt, tz, {date, {h + 1, 0, 0}}, precision)
        end

      false ->
        %{dt | :hour => 0, :minute => 0, :second => 0, :microsecond => {0, precision}}
    end
  end

  @doc """
  Shifts the provided DateTime to the end of the day in it's timezone
  """
  @spec end_of_day(DateTime.t()) :: DateTime.t()
  def end_of_day(%DateTime{time_zone: tz, microsecond: {_, precision}} = dt) do
    do_end_of_day(dt, tz, {{dt.year, dt.month, dt.day}, {23, 59, 59}}, precision)
  end

  defp do_end_of_day(%DateTime{} = dt, tz, {date, {h, _, _}} = day_end, precision) do
    abs_end = :calendar.datetime_to_gregorian_seconds(day_end)

    case Tzdata.zone_exists?(tz) do
      true ->
        case Tzdata.periods_for_time(tz, abs_end, :wall) do
          # This hour does not exist, so move back one and try again
          [] ->
            do_end_of_day(dt, tz, {date, {h - 1, 59, 59}}, precision)

          # Only one period applies
          [%{utc_off: utc_offset, std_off: std_offset, zone_abbr: abbr}] ->
            %{
              dt
              | :hour => h,
                :minute => 59,
                :second => 59,
                :microsecond => Timex.DateTime.Helpers.construct_microseconds(999_999, precision),
                :utc_offset => utc_offset,
                :std_offset => std_offset,
                :zone_abbr => abbr
            }

          # Ambiguous, choose the earliest one in the same day which is unambiguous
          [_, _] ->
            do_beginning_of_day(dt, tz, {date, {h - 1, 59, 59}}, precision)
        end

      false ->
        us = Timex.DateTime.Helpers.construct_microseconds(999_999, precision)
        %{dt | :hour => 23, :minute => 59, :second => 59, :microsecond => us}
    end
  end

  @spec tzdata_to_timezone(map, String.t()) :: TimezoneInfo.t()
  def tzdata_to_timezone(
        %{
          from: %{wall: from},
          std_off: std_off_secs,
          until: %{wall: until},
          utc_off: utc_off_secs,
          zone_abbr: abbr
        } = _tzdata,
        zone
      ) do
    start_bound = boundary_to_erlang_datetime(from)
    end_bound = boundary_to_erlang_datetime(until)

    %TimezoneInfo{
      full_name: zone,
      abbreviation: abbr,
      offset_std: std_off_secs,
      offset_utc: utc_off_secs,
      from: erlang_datetime_to_boundary_date(start_bound),
      until: erlang_datetime_to_boundary_date(end_bound)
    }
  end

  # Fetches the first timezone period which matches the abbreviation and is
  # valid for the given moment in time (secs from :zero)
  @spec lookup_timezone_by_abbreviation(String.t(), integer, :utc | :wall) ::
          String.t() | {:error, term}
  defp lookup_timezone_by_abbreviation(abbr, secs, utc_or_wall) do
    case lookup_posix(abbr) do
      full_name when is_binary(full_name) ->
        resolve(full_name, secs, utc_or_wall)

      nil ->
        {:error, {:invalid_timezone, abbr}}
    end
  end

  @spec boundary_to_erlang_datetime(:min | :max | integer) :: :min | :max | Types.datetime()
  defp boundary_to_erlang_datetime(:min), do: :min
  defp boundary_to_erlang_datetime(:max), do: :max
  defp boundary_to_erlang_datetime(secs), do: :calendar.gregorian_seconds_to_datetime(trunc(secs))

  @spec erlang_datetime_to_boundary_date(:min | :max | Types.datetime()) ::
          :min | :max | {Types.weekday_name()}
  defp erlang_datetime_to_boundary_date(:min), do: :min
  defp erlang_datetime_to_boundary_date(:max), do: :max

  defp erlang_datetime_to_boundary_date({{y, m, d}, _} = date) do
    dow =
      case :calendar.day_of_the_week({y, m, d}) do
        1 -> :monday
        2 -> :tuesday
        3 -> :wednesday
        4 -> :thursday
        5 -> :friday
        6 -> :saturday
        7 -> :sunday
      end

    {dow, date}
  end

  @spec lookup_posix(String.t()) :: String.t() | nil
  defp lookup_posix(timezone) when is_binary(timezone) do
    Tzdata.zone_list()
    # Filter out zones which definitely don't match
    |> Enum.filter(&String.contains?(&1, timezone))
    # For each candidate, attempt to parse as POSIX
    # if the parse succeeds, and the timezone name requested
    # is one of the parts, then that's our zone, otherwise, keep searching
    |> Enum.find(fn probable_zone ->
      case Posix.parse(probable_zone) do
        {:ok, %PosixTz{:std_name => ^timezone}} ->
          true

        {:ok, %PosixTz{:dst_name => ^timezone}} ->
          true

        {:ok, %PosixTz{}} ->
          false

        {:error, _reason} ->
          false
      end
    end)
  end

  defp lookup_posix(_), do: nil
end
