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
  alias Timex.Date,           as: Date
  alias Timex.DateTime,       as: DateTime
  alias Timex.TimezoneInfo,   as: TimezoneInfo
  alias Timex.Timezone.Local, as: Local
  alias Timex.Parse.Timezones.Posix
  alias Timex.Parse.Timezones.Posix.PosixTimezone, as: PosixTz

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
  @spec local() :: %TimezoneInfo{}
  def local(), do: local(Date.now)

  @doc """
  Gets the local timezone configuration for the provided date and time.
  The provided date and time can either be an Erlang datetime tuple, or a DateTime struct.
  """
  @spec local(Date.datetime | %DateTime{}) :: %TimezoneInfo{}
  def local(date)

  def local({{y,m,d}, {h,min,s}}) do
    local(%DateTime{year: y, month: m, day: d, hour: h, minute: min, second: s, timezone: %TimezoneInfo{}})
  end
  def local(%DateTime{} = date), do: get(Local.lookup(date), date)

  @doc """
  Gets timezone info for a given zone name and date. The date provided
  can either be an Erlang datetime tuple, or a DateTime struct, and if one
  is not provided, then the current date and time is returned.
  """
  @spec get(String.t | integer | :utc, Date.datetime | %DateTime{} | nil) :: %TimezoneInfo{} | {:error, String.t}
  def get(tz, datetime \\ Date.now)

  def get(tz, datetime) when tz in ["Z", "UT", "GMT"], do: get(:utc, datetime)
  def get(:utc, _),   do: %TimezoneInfo{}
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
        {:error, "No timezone found for: #{tz}"}
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
        case lookup_timezone_by_abbreviation(timezone, seconds_from_zeroyear) do
          %TimezoneInfo{} = tz ->
            tz
          false ->
            {:error, "No timezone found for: #{timezone}"}
        end
      true  ->
        seconds_from_zeroyear = :calendar.datetime_to_gregorian_seconds(datetime)
        case Tzdata.periods_for_time(timezone, seconds_from_zeroyear, :wall) do
          [] ->
            {:error, "The provided date is not valid for #{timezone}. It may represent a time during a zone transition."}
          [period | _] ->
            tzdata_to_timezone(period, timezone)
        end
    end
  end

  # Gets a timezone for a DateTime struct
  def get(timezone, %DateTime{} = dt) do
    case Tzdata.zone_exists?(timezone) do
      false ->
        seconds_from_zeroyear = Date.to_secs(dt, :zero)
        case lookup_timezone_by_abbreviation(timezone, seconds_from_zeroyear) do
          %TimezoneInfo{} = tz ->
            tz
          _ ->
            {:error, "No timezone found for: #{timezone}"}
        end
      true  ->
        seconds_from_zeroyear = Date.to_secs(dt, :zero)
        case Tzdata.periods_for_time(timezone, seconds_from_zeroyear, :wall) do
          [] ->
            {:error, "The provided date is not valid for #{timezone}. It may represent a time during a zone transition."}
          [period | _] ->
            tzdata_to_timezone(period, timezone)
        end
    end
  end

  @doc """
  Convert a date to the given timezone (either TimezoneInfo or a timezone name)
  """
  @spec convert(date :: DateTime.t, tz :: TimezoneInfo.t | String.t) :: DateTime.t

  def convert(%DateTime{ms: ms} = date, %TimezoneInfo{full_name: name} = tz) do
    # Calculate the difference between `date`'s timezone, and the provided timezone
    difference = diff(date, tz)
    # Offset the provided date's time by the difference
    shifted = Date.shift(date, mins: difference) |> Map.put(:timezone, tz)
    # Check the shifted datetime to make sure it's in the right zone
    seconds_from_zeroyear = Date.to_secs(shifted, :zero, utc: false)
    [period | _] = Tzdata.periods_for_time(name, seconds_from_zeroyear, :wall)
    case tzdata_to_timezone(period, name) do
      # No change, we're valid
      ^tz ->
        Map.put(shifted, :ms, ms)
      # The shift put us in a new timezone, so shift by the updated
      # difference, and set the zone
      new_zone    ->
        difference = diff(shifted, new_zone)
        Date.shift(shifted, mins: difference)
        |> Map.put(:timezone, new_zone)
        |> Map.put(:ms, ms)
    end
  end

  def convert(date, tz) when is_binary(tz) do
    case get(tz, date) do
      {:error, e} -> {:error, e}
      timezone    -> convert(date, timezone)
    end
  end

  @doc """
  Determine what offset is required to convert a date into a target timezone
  """
  @spec diff(date :: DateTime.t, tz :: TimezoneInfo.t) :: integer
  def diff(%DateTime{:timezone => origin}, %TimezoneInfo{:offset_std => dest_std, :offset_utc => dest_utc}) do
    %TimezoneInfo{:offset_std => origin_std, :offset_utc => origin_utc} = origin
    cond do
      origin_utc == dest_utc -> dest_std - origin_std
      true -> (dest_utc + dest_std) - (origin_utc + origin_std)
    end
  end

  # Fetches the first timezone period which matches the abbreviation and is
  # valid for the given moment in time (secs from :zero)
  defp lookup_timezone_by_abbreviation(abbr, secs) do
    case lookup_posix(abbr) do
      full_name when is_binary(full_name) ->
        case Tzdata.periods_for_time(full_name, secs, :wall) do
          [] ->
            {:error, "The provided date is not valid for #{abbr} (#{full_name}). It may represent a time during a zone transition."}
          [period | _] ->
            tzdata_to_timezone(period, full_name)
        end
      nil ->
        {:error, "The provided timezone abbreviation #{abbr} does not exist. Please use a valid POSIX or Olson timezone name."}
    end
  end

  defp tzdata_to_timezone(%{from: %{standard: from}, std_off: std_off_secs, until: %{standard: until}, utc_off: utc_off_secs, zone_abbr: abbr} = _tzdata, zone) do
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

  defp boundary_to_erlang_datetime(:min), do: :min
  defp boundary_to_erlang_datetime(:max), do: :max
  defp boundary_to_erlang_datetime(secs), do: :calendar.gregorian_seconds_to_datetime(trunc(secs))

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

end
