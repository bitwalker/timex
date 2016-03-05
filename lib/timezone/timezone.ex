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
  Gets timezone info for a given zone name and date. The date provided
  can either be an Erlang datetime tuple, or a DateTime struct, and if one
  is not provided, then the current date and time is returned.
  """
  @spec get(Types.valid_timezone, Types.datetime | DateTime.t | nil) :: TimezoneInfo.t | AmbiguousTimezoneInfo.t | {:error, term}
  def get(tz, datetime \\ DateTime.now)

  def get(tz, datetime) when tz in ["Z", "UT", "GMT"], do: get(:utc, datetime)
  def get(:utc, _),        do: %TimezoneInfo{}
  def get(:local, date),   do: local(date)
  def get(0, datetime),    do: get("UTC", datetime)
  # These are shorthand for specific time zones
  def get("A", datetime),  do: get(+1, datetime)
  def get("M", datetime),  do: get(+12, datetime)
  def get("N", datetime),  do: get(-1, datetime)
  def get("Y", datetime),  do: get(-12, datetime)
  # Allow querying by offset
  def get(offset, datetime) when is_number(offset) do
    if offset > 0 do
      get("Etc/GMT-#{offset}", datetime)
    else
      get("Etc/GMT+#{offset * -1}", datetime)
    end
  end
  def get(<<?+, offset :: binary>> = tz, datetime) do
    case Integer.parse(offset) do
      {num, _} ->
        cond do
          num >= 100 -> get(trunc(num/100), datetime)
          true      -> get(num, datetime)
        end
      :error ->
        {:error, "No timezone found for: #{tz}"}
    end
  end
  def get(<<?-, offset :: binary>> = tz, datetime) do
    case Integer.parse(offset) do
      {num, _} ->
        cond do
          num >= 100 -> get(trunc(num/100) * -1, datetime)
          true      -> get(num * -1, datetime)
        end
      :error ->
        {:error, {:no_such_timezone, tz}}
    end
  end
  def get(<<"GMT", ?+, offset::binary>>, datetime), do: get("Etc/GMT+#{offset}", datetime)
  def get(<<"GMT", ?-, offset::binary>>, datetime), do: get("Etc/GMT-#{offset}", datetime)

  # Gets a timezone for an Erlang datetime tuple
  def get(timezone, {{_,_,_}, {_,_,_}} = datetime) do
     case Tzdata.zone_exists?(timezone) do
      false ->
        # Lookup the real timezone for this abbreviation and date
        seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds(datetime)
        lookup_timezone_by_abbreviation(timezone, seconds_from_zeroyear)
      true  ->
         seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds(datetime)
         resolve(timezone, seconds_from_zeroyear)
    end
  end

  # Gets a timezone for a DateTime struct
  def get(timezone, %DateTime{} = dt) do
    case Tzdata.zone_exists?(timezone) do
      false ->
        seconds_from_zeroyear = DateTime.to_seconds(dt, :zero)
        lookup_timezone_by_abbreviation(timezone, seconds_from_zeroyear)
      true  ->
        seconds_from_zeroyear = DateTime.to_seconds(dt, :zero)
        resolve(timezone, seconds_from_zeroyear)
    end
  end

  @doc """
  Given a timezone name as a string, and a date/time in the form of the number of seconds since year zero,
  attempt to resolve a TimezoneInfo for that date/time. If the time is ambiguous, AmbiguousTimezoneInfo will
  be returned. If the time doesn't exist, the clock will shift forward an hour, and try again, and if no result
  is found, an error will be returned.

  If an invalid zone name is provided, an error will be returned
  """
  @spec resolve(String.t, non_neg_integer) :: TimezoneInfo.t | AmbiguousTimezoneInfo.t | {:error, term}
  def resolve(name, seconds_from_zeroyear) when is_binary(name) and is_integer(seconds_from_zeroyear) do
    case Tzdata.periods_for_time(name, seconds_from_zeroyear, :wall) do
      [] ->
        # Shift forward an hour, try again
        case Tzdata.periods_for_time(name, seconds_from_zeroyear + (60 * 60), :wall) do
          # Do not try again, something is wrong
          [] ->
            {:error, {:could_not_resolve_timezone, name, seconds_from_zeroyear, :wall}}
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
  This version of resolve/2 takes a timezone name as a string, and an Erlang datetime tuple,
  and attempts to resolve the date and time in that timezone. Unlike the previous clause of resolve/2,
  this one will return either an error, a DateTime struct, or an AmbiguousDateTime struct.
  """
  @spec resolve(Types.valid_timezone, Types.datetime) :: DateTime.t | AmbiguousDateTime.t | {:error, term}
  # These are shorthand for specific time zones
  def resolve(tzname, {{y,m,d},{h,mm,s}} = datetime) when is_binary(tzname) and is_datetime(y,m,d,h,mm,s) do
    secs_from_zero = :calendar.datetime_to_gregorian_seconds(datetime)
    case resolve(tzname, secs_from_zero) do
      {:error, _} = err ->
        err
      %TimezoneInfo{} = tz ->
        case Tzdata.periods_for_time(tz.full_name, secs_from_zero, :wall) do
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
  def resolve(tzname, {{y,m,d},{h,mm,s,ms}}) when is_binary(tzname) and is_datetime(y,m,d,h,mm,s,ms) do
    case resolve(tzname, {{y,m,d},{h,mm,s}}) do
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
  def convert(%DateTime{millisecond: ms} = date, %TimezoneInfo{full_name: name} = tz) do
    # Calculate the difference between `date`'s timezone, and the provided timezone
    difference = diff(date, tz)
    # Offset the provided date's time by the difference
    shifted = Timex.shift(date, minutes: difference) |> Map.put(:timezone, tz)
    # Check the shifted datetime to make sure it's in the right zone
    seconds_from_zeroyear = DateTime.to_seconds(shifted, :zero, utc: false)
    case resolve(name, seconds_from_zeroyear) do
      {:error, _} = err -> err
      ^tz -> %{shifted | :millisecond => ms}
      %TimezoneInfo{} = new_zone ->
        difference = diff(shifted, new_zone)
        shifted = Timex.shift(shifted, minutes: difference)
        %{shifted | :millisecond => ms, :timezone => new_zone}
      %AmbiguousTimezoneInfo{:before => before_tz, :after => after_tz} ->
        before_diff = diff(shifted, before_tz)
        before_shifted = Timex.shift(shifted, minutes: before_diff)
        before_shifted = %{before_shifted | :millisecond => ms, :timezone => before_tz}
        after_diff = diff(shifted, after_tz)
        after_shifted = Timex.shift(shifted, minutes: after_diff)
        after_shifted = %{after_shifted | :millisecond => ms, :timezone => after_tz}
        %AmbiguousDateTime{:before => before_shifted, :after => after_shifted}
    end
  end

  def convert(date, tz) do
    case get(tz, date) do
      {:error, _} = err -> err
      timezone    -> convert(date, timezone)
    end
  end

  @doc """
  Determine what offset is required to convert a date into a target timezone
  """
  @spec diff(date :: DateTime.t, tz :: TimezoneInfo.t) :: integer | {:error, term}
  def diff(%DateTime{:timezone => origin}, %TimezoneInfo{:offset_std => dest_std, :offset_utc => dest_utc}) do
    %TimezoneInfo{:offset_std => origin_std, :offset_utc => origin_utc} = origin
    cond do
      origin_utc == dest_utc -> dest_std - origin_std
      true -> (dest_utc + dest_std) - (origin_utc + origin_std)
    end
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
  @spec lookup_timezone_by_abbreviation(String.t, integer) :: String.t | {:error, term}
  defp lookup_timezone_by_abbreviation(abbr, secs) do
    case lookup_posix(abbr) do
      full_name when is_binary(full_name) ->
        resolve(full_name, secs)
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
