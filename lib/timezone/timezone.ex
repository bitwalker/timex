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
  alias Timex.DateTime
  alias Timex.AmbiguousDateTime
  alias Timex.TimezoneInfo
  alias Timex.AmbiguousTimezoneInfo
  alias Timex.Timezone.Local, as: Local
  alias Timex.Parse.Timezones.Posix
  alias Timex.Parse.Timezones.Posix.PosixTimezone, as: PosixTz
  import Timex.Macros

  @doc """
  Determines if a given zone name exists
  """
  @spec exists?(String.t) :: boolean
  def exists?(zone) when is_binary(zone) do
    case Tzdata.zone_exists?(zone) do
      true ->
        true
      false ->
        case lookup_posix(zone) do
          tz when is_binary(tz) -> true
          _ -> false
        end
    end
  end

  @doc """
  Gets the local timezone configuration for the current date and time.
  """
  @spec local() :: TimezoneInfo.t | AmbiguousTimezoneInfo.t | {:error, term}
  def local(), do: local(DateTime.now)

  @doc """
  Gets the local timezone configuration for the provided date and time.
  The provided date and time can either be an Erlang datetime tuple, or a DateTime struct.
  """
  @spec local(Types.datetime | DateTime.t) :: TimezoneInfo.t | AmbiguousTimezoneInfo.t | {:error, term}
  def local(date)

  def local({{y,m,d}, {h,min,s}}) when is_datetime(y,m,d,h,min,s),
    do: local(%DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, timezone: %TimezoneInfo{}})
  def local({{y,m,d}, {h,min,s,ms}}) when is_datetime(y,m,d,h,min,s,ms),
    do: local(%DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, millisecond: ms, timezone: %TimezoneInfo{}})
  def local(%DateTime{} = date),
    do: get(Local.lookup(date), date)
  def local(_),
    do: {:error, :invalid_datetime}

  @doc """
  This function takes one of the varying timezone representations (atoms, offset integers, shortcut names),
  and resolves the full name of the timezone if it's able.

  If a string is provided which isn't recognized, it is returned untouched, only when `get/2` is called will
  the timezone lookup fail.
  """
  @spec name_of(Types.valid_timezone) :: String.t | {:error, {:invalid_timezone, term}}
  def name_of(%TimezoneInfo{:full_name => name}), do: name
  def name_of(:utc),   do: "UTC"
  def name_of(:local), do: local(DateTime.now) |> name_of
  def name_of(0),      do: "UTC"
  def name_of("A"),    do: name_of(1)
  def name_of("M"),    do: name_of(12)
  def name_of("N"),    do: name_of(-1)
  def name_of("Y"),    do: name_of(-12)
  def name_of("Z"),    do: "UTC"
  def name_of("UT"),   do: "UTC"
  def name_of(offset) when is_integer(offset) do
    if offset > 0 do
      "Etc/GMT-#{offset}"
    else
      "Etc/GMT+#{offset * -1}"
    end
  end
  def name_of(<<?+, offset :: binary>> = tz) do
    case Integer.parse(offset) do
      {num, _} ->
        cond do
          num >= 100 -> name_of(trunc(num/100))
          true      ->  name_of(num)
        end
      :error ->
        {:error, {:no_such_zone, tz}}
    end
  end
  def name_of(<<?-, offset :: binary>> = tz) do
    case Integer.parse(offset) do
      {num, _} ->
        cond do
          num >= 100 -> name_of(trunc(num/100) * -1)
          true       -> name_of(num * -1)
        end
      :error ->
        {:error, {:no_such_zone, tz}}
    end
  end
  def name_of(<<"GMT", ?+, offset::binary>>), do: "Etc/GMT+#{offset}"
  def name_of(<<"GMT", ?-, offset::binary>>), do: "Etc/GMT-#{offset}"
  def name_of(tz) when is_binary(tz) do
    case Tzdata.zone_exists?(tz) do
      true -> tz
      false ->
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
  @spec get(Types.valid_timezone, Types.datetime | DateTime.t | nil) :: TimezoneInfo.t | AmbiguousTimezoneInfo.t | {:error, term}
  def get(tz, datetime \\ DateTime.now)

  def get(:utc, _datetime),  do: %TimezoneInfo{}
  def get(:local, datetime), do: local(datetime)
  def get(tz, datetime) do
    case name_of(tz) do
      {:error, _} = err ->
        err
      "UTC" ->
        %TimezoneInfo{}
      name ->
        do_get(name, datetime)
    end
  end

  defp do_get(timezone, datetime, utc_or_wall \\ :wall)

  # Gets a timezone for an Erlang datetime tuple
  defp do_get(timezone, {{_,_,_}, {_,_,_}} = datetime, utc_or_wall) do
    name = name_of(timezone)
    case Tzdata.zone_exists?(name) do
      false ->
        # Lookup the real timezone for this abbreviation and date
        seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds(datetime)
        lookup_timezone_by_abbreviation(name, seconds_from_zeroyear, utc_or_wall)
      true  ->
        seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds(datetime)
        resolve(name, seconds_from_zeroyear, utc_or_wall)
    end
  end

  # Gets a timezone for a DateTime struct
  defp do_get(timezone, %DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s}, utc_or_wall) do
    name = name_of(timezone)
    case Tzdata.zone_exists?(name) do
      false ->
        seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}})
        lookup_timezone_by_abbreviation(name, seconds_from_zeroyear, utc_or_wall)
      true  ->
        seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds({{y,m,d},{h,mm,s}})
        resolve(name, seconds_from_zeroyear, utc_or_wall)
    end
  end

  def total_offset(%TimezoneInfo{offset_std: std, offset_utc: utc}) do
    utc + std
  end

  @doc """
  Given a timezone name as a string, and a date/time in the form of the number of seconds since year zero,
  attempt to resolve a TimezoneInfo for that date/time. If the time is ambiguous, AmbiguousTimezoneInfo will
  be returned. If the time doesn't exist, the clock will shift forward an hour, and try again, and if no result
  is found, an error will be returned.

  If an invalid zone name is provided, an error will be returned
  """
  @spec resolve(String.t, non_neg_integer, :utc | :wall) :: TimezoneInfo.t | AmbiguousTimezoneInfo.t | {:error, term}
  def resolve(tzname, datetime, utc_or_wall \\ :wall)

  def resolve(name, seconds_from_zeroyear, utc_or_wall)
    when is_binary(name) and is_integer(seconds_from_zeroyear) and utc_or_wall in [:utc, :wall] do
    case Tzdata.periods_for_time(name, seconds_from_zeroyear, utc_or_wall) do
      [] ->
        # Shift forward an hour, try again
        case Tzdata.periods_for_time(name, seconds_from_zeroyear + (60 * 60), utc_or_wall) do
          # Do not try again, something is wrong
          [] ->
            {:error, {:could_not_resolve_timezone, name, seconds_from_zeroyear, utc_or_wall}}
          # Resolved
          [period] ->
            tzdata_to_timezone(period, name)
          # Ambiguous
          [before_period, after_period] ->
            before_tz = tzdata_to_timezone(before_period, name)
            after_tz  = tzdata_to_timezone(after_period, name)
            AmbiguousTimezoneInfo.new(before_tz, after_tz)
        end
      # Resolved
      [period] ->
        tzdata_to_timezone(period, name)
      # Ambiguous
      [before_period, after_period] ->
        before_tz = tzdata_to_timezone(before_period, name)
        after_tz  = tzdata_to_timezone(after_period, name)
        AmbiguousTimezoneInfo.new(before_tz, after_tz)
    end
  end

  @doc """
  This version of resolve/3 takes a timezone name as a string, and an Erlang datetime tuple,
  and attempts to resolve the date and time in that timezone. Unlike the previous clause of resolve/2,
  this one will return either an error, a DateTime struct, or an AmbiguousDateTime struct.
  """
  @spec resolve(Types.valid_timezone, Types.datetime, :utc | :wall) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  # These are shorthand for specific time zones
  def resolve(tzname, {{y,m,d},{h,mm,s}} = datetime, utc_or_wall)
    when is_binary(tzname) and is_datetime(y,m,d,h,mm,s) and utc_or_wall in [:utc, :wall] do
    secs_from_zero = :calendar.datetime_to_gregorian_seconds(datetime)
    case resolve(tzname, secs_from_zero, utc_or_wall) do
      {:error, _} = err ->
        err
      %TimezoneInfo{} = tz ->
        case Tzdata.periods_for_time(tz.full_name, secs_from_zero, utc_or_wall) do
          [] ->
            # We need to shift to the beginning of `tz`
            {_weekday, {{y,m,d}, {h,mm,s}}} = tz.from
            %DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s, :timezone => tz}
          _ ->
            # We're good
            %DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s, :timezone => tz}
        end
      %AmbiguousTimezoneInfo{:before => before_tz, :after => after_tz} ->
        before_dt = %DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s, :timezone => before_tz}
        after_dt  = %DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm, :second => s, :timezone => after_tz}
        %AmbiguousDateTime{:before => before_dt, :after => after_dt}
    end
  end
  def resolve(tzname, {{y,m,d},{h,mm,s,ms}}, utc_or_wall)
    when is_binary(tzname) and is_datetime(y,m,d,h,mm,s,ms) and utc_or_wall in [:utc, :wall] do
      case resolve(tzname, {{y,m,d},{h,mm,s}}, utc_or_wall) do
        {:error, _} = err ->
          err
        %DateTime{} = datetime ->
          %{datetime | :millisecond => ms}
        %AmbiguousDateTime{:before => before_dt, :after => after_dt} ->
          %AmbiguousDateTime{:before => %{before_dt | :millisecond => ms},
                            :after  => %{after_dt | :millisecond => ms}}
      end
  end

  @doc """
  Convert a date to the given timezone (either TimezoneInfo or a timezone name)
  """
  @spec convert(date :: DateTime.t, tz :: AmbiguousTimezoneInfo.t) :: AmbiguousDateTime.t | {:error, term}
  @spec convert(date :: DateTime.t, tz :: TimezoneInfo.t | String.t) :: DateTime.t | AmbiguousDateTime.t | {:error, term}

  def convert(%DateTime{} = date, %AmbiguousTimezoneInfo{} = tz) do
    before_date = convert(date, tz.before)
    after_date  = convert(date, tz.after)
    %AmbiguousDateTime{:before => before_date, :after => after_date}
  end
  def convert(%DateTime{} = date, %TimezoneInfo{full_name: name} = tz) do
    # Calculate the difference between `date`'s timezone, and the provided timezone
    difference = diff(date, tz)
    # Offset the provided date's time by the difference
    {seconds_from_zeroyear, millis} = do_shift(date, :minutes, difference)
    case resolve(name, seconds_from_zeroyear) do
      {:error, _} = err -> err
      ^tz ->
        {{y,m,d},{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(seconds_from_zeroyear)
        %DateTime{:year => y, :month => m, :day => d,
                  :hour => h, :minute => mm, :second => s, :millisecond => millis,
                  :timezone => tz}
      %TimezoneInfo{} = new_zone ->
        difference = diff(tz, new_zone)
        {shifted, millis} = do_shift(seconds_from_zeroyear, millis, :minutes, difference)
        {{y,m,d},{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(shifted)
        %DateTime{:year => y, :month => m, :day => d,
                  :hour => h, :minute => mm, :second => s, :millisecond => millis,
                  :timezone => new_zone}
      %AmbiguousTimezoneInfo{:before => before_tz, :after => after_tz} ->
        before_diff = diff(tz, before_tz)
        {before_shifted, before_millis} = do_shift(seconds_from_zeroyear, millis, :minutes, before_diff)
        after_diff = diff(tz, after_tz)
        {after_shifted, after_millis} = do_shift(seconds_from_zeroyear, millis, :minutes, after_diff)
        {{y,m,d},{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(before_shifted)
        before_dt = %DateTime{:year => y, :month => m, :day => d,
                              :hour => h, :minute => mm, :second => s, :millisecond => before_millis,
                              :timezone => before_tz}
        {{y,m,d},{h,mm,s}} = :calendar.gregorian_seconds_to_datetime(after_shifted)
        after_dt = %DateTime{:year => y, :month => m, :day => d,
                             :hour => h, :minute => mm, :second => s, :millisecond => after_millis,
                             :timezone => after_tz}
        %AmbiguousDateTime{:before => before_dt, :after => after_dt}
    end
  end

  def convert(date, tz) do
    case do_get(tz, date, :utc) do
      {:error, _} = err -> err
      timezone    -> convert(date, timezone)
    end
  end

  defp do_shift(%DateTime{:millisecond => ms} = datetime, unit, value) do
    secs_from_zero = :calendar.datetime_to_gregorian_seconds({
      {datetime.year,datetime.month,datetime.day},
      {datetime.hour,datetime.minute,datetime.second}
    })
    do_shift(secs_from_zero, ms, unit, value)
  end
  defp do_shift(secs_from_zero, ms, unit, value) when is_integer(secs_from_zero) do
    shift_by = case unit do
      :milliseconds -> div(value + ms, 1_000)
      :seconds      -> value
      :minutes      -> value * 60
      :hours        -> value * 60 * 60
      :days         -> value * 60 * 60 * 24
      :weeks        -> value * 60 * 60 * 24 * 7
      _ ->
        raise "unknown shift unit provided to do_shift"
    end
    case shift_by do
      0 when unit in [:milliseconds] ->
        total_ms = rem(value + ms, 1_000)
        {secs_from_zero, total_ms}
      0 ->
        {secs_from_zero, ms}
      _ ->
        new_secs_from_zero = secs_from_zero + shift_by
        cond do
          new_secs_from_zero <= 0 ->
            raise "cannot shift a datetime before the beginning of the gregorian calendar!"
          :else ->
            {new_secs_from_zero, ms}
        end
    end
  end

  @doc """
  Determine what offset is required to convert a date into a target timezone
  """
  @spec diff(date :: DateTime.t, tz :: TimezoneInfo.t) :: integer | {:error, term}
  def diff(%DateTime{:timezone => origin}, %TimezoneInfo{} = dest) do
    diff(origin, dest)
  end

  def diff(%TimezoneInfo{} = origin, %TimezoneInfo{} = dest) do
    total_offset(dest) - total_offset(origin)
  end

  @spec tzdata_to_timezone(Map.t, String.t) :: TimezoneInfo.t
  def tzdata_to_timezone(%{from: %{wall: from}, std_off: std_off_secs, until: %{wall: until}, utc_off: utc_off_secs, zone_abbr: abbr} = _tzdata, zone) do
    start_bound = boundary_to_erlang_datetime(from)
    end_bound   = boundary_to_erlang_datetime(until)
    %TimezoneInfo{
      full_name:     zone,
      abbreviation:  abbr,
      offset_std:    trunc(std_off_secs / 60),
      offset_utc:    trunc(utc_off_secs / 60),
      from:          start_bound |> erlang_datetime_to_boundary_date,
      until:         end_bound |> erlang_datetime_to_boundary_date
    }
  end

  # Fetches the first timezone period which matches the abbreviation and is
  # valid for the given moment in time (secs from :zero)
  @spec lookup_timezone_by_abbreviation(String.t, integer, :utc | :wall) :: String.t | {:error, term}
  defp lookup_timezone_by_abbreviation(abbr, secs, utc_or_wall) do
    case lookup_posix(abbr) do
      full_name when is_binary(full_name) ->
        resolve(full_name, secs, utc_or_wall)
      nil ->
        {:error, {:invalid_timezone, abbr}}
    end
  end

  @spec boundary_to_erlang_datetime(:min | :max | integer) :: :min | :max | Types.datetime
  defp boundary_to_erlang_datetime(:min), do: :min
  defp boundary_to_erlang_datetime(:max), do: :max
  defp boundary_to_erlang_datetime(secs), do: :calendar.gregorian_seconds_to_datetime(trunc(secs))

  @spec erlang_datetime_to_boundary_date(:min | :max | Types.datetime) :: :min | :max | {Types.weekday_name}
  defp erlang_datetime_to_boundary_date(:min), do: :min
  defp erlang_datetime_to_boundary_date(:max), do: :max
  defp erlang_datetime_to_boundary_date({{y, m, d}, _} = date) do
    dow = case :calendar.day_of_the_week({y, m, d}) do
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

  @spec lookup_posix(String.t) :: String.t | nil
  defp lookup_posix(timezone) when is_binary(timezone) do
    Tzdata.zone_list
    # Filter out zones which definitely don't match
    |> Enum.filter(&String.contains?(&1, timezone))
    # For each candidate, attempt to parse as POSIX
    # if the parse succeeds, and the timezone name requested
    # is one of the parts, then that's our zone, otherwise, keep searching
    |> Enum.find(fn probable_zone ->
      case Posix.parse(probable_zone) do
        {:ok, %PosixTz{:std_name => ^timezone}} -> true
        {:ok, %PosixTz{:dst_name => ^timezone}} -> true
        {:ok, %PosixTz{}}                       -> false
        {:error, _reason} ->
          false
      end
    end)
  end
  defp lookup_posix(_), do: nil

end
