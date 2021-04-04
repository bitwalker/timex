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
  alias Timex.PosixTimezone
  alias Timex.AmbiguousTimezoneInfo
  alias Timex.Timezone.Local, as: Local
  alias Timex.Parse.Timezones.Posix
  alias Timex.Types

  @doc """
  Determines if a given zone name exists
  """
  @spec exists?(String.t()) :: boolean
  def exists?(zone) when is_binary(zone) do
    if Tzdata.zone_exists?(zone) do
      true
    else
      case lookup_posix(zone) do
        %PosixTimezone{} -> true
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
          | {:error, :time_zone_not_found}
          | {:error, term}
  def name_of(%TimezoneInfo{:full_name => name}), do: name
  def name_of(:utc), do: "Etc/UTC"
  def name_of(:local), do: name_of(Local.lookup())

  def name_of("Etc/UTC"), do: "Etc/UTC"
  def name_of("GMT"), do: "Etc/UTC"
  def name_of("UTC"), do: "Etc/UTC"
  def name_of("UT"), do: "Etc/UTC"
  def name_of("Z"), do: "Etc/UTC"
  def name_of("A"), do: "Etc/UTC+1"
  def name_of("M"), do: "Etc/UTC+12"
  def name_of("N"), do: "Etc/UTC-1"
  def name_of("Y"), do: "Etc/UTC-12"

  def name_of(0), do: "Etc/UTC"

  def name_of(offset) when is_integer(offset) do
    cond do
      offset <= -100 ->
        hh = div(offset * -1, 100)
        mm = rem(offset, 100) * -1

        if mm == 0 do
          "Etc/UTC-#{hh}"
        else
          hh = String.pad_leading(to_string(hh), 2, "0")
          mm = String.pad_leading(to_string(mm), 2, "0")
          "Etc/UTC-#{hh}:#{mm}"
        end

      offset >= 100 ->
        hh = div(offset, 100)
        mm = rem(offset, 100)

        if mm == 0 do
          "Etc/UTC+#{hh}"
        else
          hh = String.pad_leading(to_string(hh), 2, "0")
          mm = String.pad_leading(to_string(mm), 2, "0")
          "Etc/UTC+#{hh}:#{mm}"
        end

      offset >= 0 and offset < 24 ->
        "Etc/UTC+#{offset}"

      offset <= 0 and offset > -24 ->
        "Etc/UTC-#{offset * -1}"

      :else ->
        {:error, :time_zone_not_found}
    end
  end

  def name_of(<<sign::utf8, ?0, ?0, ?:, ?0, ?0>>) when sign in [?+, ?-] do
    "Etc/UTC"
  end

  def name_of(<<sign::utf8, h::binary-size(2)-unit(8), ?:, ?0, ?0>>) when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary>>
  end

  def name_of(<<sign::utf8, h::binary-size(1)-unit(8), ?:, ?0, ?0>>) when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary>>
  end

  def name_of(<<sign::utf8, h::binary-size(2)-unit(8), ?:, m::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary, ?:, m::binary>>
  end

  def name_of(<<sign::utf8, h::binary-size(1)-unit(8), ?:, m::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary, ?:, m::binary>>
  end

  def name_of(
        <<sign::utf8, h::binary-size(2)-unit(8), ?:, m::binary-size(2)-unit(8), ?:,
          s::binary-size(2)-unit(8)>>
      )
      when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary, ?:, m::binary, ?:, s::binary>>
  end

  def name_of(
        <<sign::utf8, h::binary-size(1)-unit(8), ?:, m::binary-size(2)-unit(8), ?:,
          s::binary-size(2)-unit(8)>>
      )
      when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary, ?:, m::binary, ?:, s::binary>>
  end

  def name_of(<<sign::utf8, h::binary-size(2)-unit(8), m::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary, ?:, m::binary>>
  end

  def name_of(<<sign::utf8, h::binary-size(1)-unit(8), m::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary, ?:, m::binary>>
  end

  def name_of(<<sign::utf8, h::binary-size(2)-unit(8)>>) when sign in [?+, ?-] do
    "Etc/UTC" <> <<sign::utf8, h::binary>>
  end

  def name_of(<<sign::utf8, h::utf8>>) when sign in [?+, ?-] and h >= ?0 and h <= ?9 do
    "Etc/UTC" <> <<sign::utf8, h::utf8>>
  end

  def name_of("Etc/UTC" <> offset), do: name_of(offset)

  def name_of("Etc/GMT" <> offset) do
    case name_of("GMT" <> offset) do
      {:error, _} = err ->
        err

      <<"Etc/UTC", ?+, rest::binary>> ->
        "Etc/GMT-" <> rest

      <<"Etc/UTC", ?-, rest::binary>> ->
        "Etc/GMT+" <> rest

      other ->
        other
    end
  end

  def name_of(<<"GMT", sign::utf8, hh::utf8>>) when sign in [?+, ?-],
    do: "Etc/UTC" <> <<sign::utf8, hh::utf8>>

  def name_of(<<"GMT", sign::utf8, hh::binary-size(2)-unit(8)>>) when sign in [?+, ?-],
    do: "Etc/UTC" <> <<sign::utf8, hh::binary>>

  def name_of(<<"GMT", sign::utf8, hh::binary-size(2)-unit(8), ?:, mm::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-],
      do: "Etc/UTC" <> <<sign::utf8, hh::binary, ?:, mm::binary>>

  def name_of(<<"GMT", sign::utf8, hh::binary-size(1)-unit(8), ?:, mm::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-],
      do: "Etc/UTC" <> <<sign::utf8, hh::binary, ?:, mm::binary>>

  def name_of(<<"GMT", sign::utf8, hh::binary-size(2)-unit(8), mm::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-],
      do: "Etc/UTC" <> <<sign::utf8, hh::binary, ?:, mm::binary>>

  def name_of(<<"GMT", sign::utf8, hh::binary-size(1)-unit(8), mm::binary-size(2)-unit(8)>>)
      when sign in [?+, ?-],
      do: "Etc/UTC" <> <<sign::utf8, hh::binary, ?:, mm::binary>>

  def name_of(""), do: {:error, :time_zone_not_found}

  def name_of(tz) when is_binary(tz) do
    if Tzdata.zone_exists?(tz) do
      tz
    else
      case lookup_posix(tz) do
        %PosixTimezone{name: name} ->
          name

        nil ->
          {:error, :time_zone_not_found}
      end
    end
  end

  def name_of(_tz), do: {:error, :time_zone_not_found}

  @doc """
  Gets timezone info for a given zone name and date. The date provided
  can either be an Erlang datetime tuple, or a DateTime struct, and if one
  is not provided, then the current date and time is returned.
  """
  @spec get(Types.valid_timezone()) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  @spec get(Types.valid_timezone(), Types.valid_datetime()) ::
          TimezoneInfo.t() | AmbiguousTimezoneInfo.t() | {:error, term}
  def get(tz, datetime \\ NaiveDateTime.utc_now())

  def get(:utc, _datetime), do: %TimezoneInfo{}
  def get(:local, datetime), do: local(datetime)

  def get(tz, datetime) do
    utc_or_wall = if match?(%DateTime{}, datetime), do: :utc, else: :wall

    case name_of(tz) do
      {:error, _} = err ->
        err

      name ->
        get_info(name, datetime, utc_or_wall)
    end
  end

  @doc """
  Same as `get/2`, but allows specifying whether to obtain the TimezoneInfo based
  on utc time or wall time manually (`:utc` or `:wall` respectively).
  """
  def get(:utc, _, _), do: %TimezoneInfo{}
  def get(:local, datetime, _), do: local(datetime)

  def get(tz, datetime, utc_or_wall) do
    case name_of(tz) do
      {:error, _} = err ->
        err

      name ->
        get_info(name, datetime, utc_or_wall)
    end
  end

  defp get_info(timezone, datetime, utc_or_wall)

  defp get_info("Etc/UTC", _datetime, _utc_or_wall),
    do: %TimezoneInfo{}

  defp get_info("Etc/GMT", _datetime, _utc_or_wall),
    do: %TimezoneInfo{}

  defp get_info(<<"Etc/UTC", sign::utf8, offset::binary>>, datetime, utc_or_wall)
       when sign in [?+, ?-] do
    get_utc_info("Etc/UTC", <<sign::utf8, offset::binary>>, datetime, utc_or_wall)
  end

  defp get_info(<<"Etc/GMT", sign::utf8, offset::binary>>, datetime, utc_or_wall)
       when sign in [?+, ?-] do
    get_utc_info("Etc/GMT", <<sign::utf8, offset::binary>>, datetime, utc_or_wall)
  end

  defp get_info(<<"GMT", sign::utf8, offset::binary>>, _datetime, _utc_or_wall)
       when sign in [?+, ?-] do
    with offset_secs when is_integer(offset_secs) <- parse_offset(offset) do
      hours = div(offset_secs, 3600)
      minutes = div(rem(offset_secs, 3600), 60)

      if hours != 0 or minutes != 0 do
        hh = String.pad_leading(to_string(hours), 2, "0")
        mm = String.pad_leading(to_string(minutes), 2, "0")

        {suffix, abbr, offset_utc} =
          cond do
            sign == ?+ and minutes == 0 ->
              {"+#{hours}", "-#{hh}", offset_secs * -1}

            sign == ?+ ->
              {"+#{hours}:#{mm}", "-#{hh}:#{mm}", offset_secs * -1}

            sign == ?- and minutes == 0 ->
              {"-#{hours}", "+#{hh}", offset_secs}

            sign == ?- ->
              {"-#{hours}:#{mm}", "+#{hh}:#{mm}", offset_secs}
          end

        %TimezoneInfo{
          full_name: <<"Etc/GMT", suffix::binary>>,
          abbreviation: abbr,
          offset_std: 0,
          offset_utc: offset_utc,
          from: :min,
          until: :max
        }
      else
        %TimezoneInfo{
          full_name: "Etc/GMT",
          abbreviation: "GMT",
          offset_std: 0,
          offset_utc: 0,
          from: :min,
          until: :max
        }
      end
    end
  end

  defp get_info(name, datetime, utc_or_wall) when is_binary(name) do
    seconds_from_zeroyear = Timex.to_gregorian_seconds(datetime)

    if Tzdata.zone_exists?(name) do
      resolve(name, seconds_from_zeroyear, utc_or_wall)
    else
      with {:ok, %PosixTimezone{} = posixtz, _} <- Posix.parse(name) do
        PosixTimezone.to_timezone_info(posixtz, Timex.to_naive_datetime(datetime))
      else
        {:error, _, _} ->
          {:error, :time_zone_not_found}
      end
    end
  end

  defp get_info(%TimezoneInfo{} = info, _datetime, _utc_or_wall), do: info

  defp get_utc_info(prefix, <<sign::utf8, offset::binary>>, _datetime, _utc_or_wall)
       when sign in [?+, ?-] do
    with offset_secs when is_integer(offset_secs) <- parse_offset(offset) do
      hours = div(offset_secs, 3600)
      minutes = div(rem(offset_secs, 3600), 60)

      if hours != 0 or minutes != 0 do
        hh = String.pad_leading(to_string(hours), 2, "0")
        mm = String.pad_leading(to_string(minutes), 2, "0")

        {suffix, abbr, offset_utc} =
          cond do
            sign == ?+ and minutes == 0 ->
              {"#{hours}", "+#{hh}", offset_secs}

            sign == ?+ ->
              {"#{hours}:#{mm}", "+#{hh}:#{mm}", offset_secs}

            sign == ?- and minutes == 0 ->
              {"#{hours}", "-#{hh}", offset_secs * -1}

            sign == ?- ->
              {"#{hours}:#{mm}", "-#{hh}:#{mm}", offset_secs * -1}
          end

        %TimezoneInfo{
          full_name: <<prefix::binary, sign::utf8, suffix::binary>>,
          abbreviation: abbr,
          offset_std: 0,
          offset_utc: offset_utc,
          from: :min,
          until: :max
        }
      else
        %TimezoneInfo{}
      end
    end
  end

  defp parse_offset(
         <<h::binary-size(2)-unit(8), ?:, m::binary-size(2)-unit(8), ?:,
           s::binary-size(2)-unit(8)>>
       ) do
    with {hh, _} <- Integer.parse(h),
         {mm, _} <- Integer.parse(m),
         {ss, _} <- Integer.parse(s) do
      hh * 3600 + mm * 60 + ss
    else
      _ ->
        {:error, :invalid_offset}
    end
  end

  defp parse_offset(
         <<h::binary-size(1)-unit(8), ?:, m::binary-size(2)-unit(8), ?:,
           s::binary-size(2)-unit(8)>>
       ) do
    with {hh, _} <- Integer.parse(h),
         {mm, _} <- Integer.parse(m),
         {ss, _} <- Integer.parse(s) do
      hh * 3600 + mm * 60 + ss
    else
      _ ->
        {:error, :invalid_offset}
    end
  end

  defp parse_offset(<<h::binary-size(2)-unit(8), ?:, m::binary-size(2)-unit(8)>>) do
    with {hh, _} <- Integer.parse(h),
         {mm, _} <- Integer.parse(m) do
      hh * 3600 + mm * 60
    else
      _ ->
        {:error, :invalid_offset}
    end
  end

  defp parse_offset(<<h::binary-size(1)-unit(8), ?:, m::binary-size(2)-unit(8)>>) do
    with {hh, _} <- Integer.parse(h),
         {mm, _} <- Integer.parse(m) do
      hh * 3600 + mm * 60
    else
      _ ->
        {:error, :invalid_offset}
    end
  end

  defp parse_offset(<<h::binary-size(2)-unit(8)>>) do
    with {hh, _} <- Integer.parse(h) do
      hh * 3600
    else
      _ ->
        {:error, :invalid_offset}
    end
  end

  defp parse_offset(<<h::utf8>> = input) when h >= ?0 and h <= ?9 do
    String.to_integer(input) * 3600
  end

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

  @doc """
  Convert a date to the given timezone (either TimezoneInfo or a timezone name)
  """
  @spec convert(date :: DateTime.t() | NaiveDateTime.t(), tz :: AmbiguousTimezoneInfo.t()) ::
          AmbiguousDateTime.t() | {:error, term}
  @spec convert(
          date :: DateTime.t() | NaiveDateTime.t(),
          tz :: TimezoneInfo.t() | Types.valid_timezone()
        ) ::
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

  def convert(%DateTime{} = date, %TimezoneInfo{full_name: name}) do
    with {:ok, datetime} <- DateTime.shift_zone(date, name, Timex.Timezone.Database) do
      datetime
    else
      {ty, a, b} when ty in [:gap, :ambiguous] ->
        %AmbiguousDateTime{before: a, after: b, type: ty}

      {:error, _} = err ->
        err
    end
  end

  def convert(%DateTime{} = date, tz) do
    case get(tz, date) do
      {:error, _} = err ->
        err

      timezone ->
        convert(date, timezone)
    end
  end

  def convert(%NaiveDateTime{} = date, %AmbiguousTimezoneInfo{} = tz) do
    before_date = convert(date, tz.before)
    after_date = convert(date, tz.after)
    %AmbiguousDateTime{:before => before_date, :after => after_date}
  end

  def convert(%NaiveDateTime{} = date, %TimezoneInfo{full_name: name}) do
    with {:ok, datetime} <- DateTime.from_naive(date, name, Timex.Timezone.Database) do
      datetime
    else
      {ty, a, b} when ty in [:gap, :ambiguous] ->
        %AmbiguousDateTime{before: a, after: b, type: ty}

      {:error, _} = err ->
        err
    end
  end

  def convert(%NaiveDateTime{} = date, tz) do
    with %TimezoneInfo{} = tzinfo <- get(tz, date) do
      convert(date, tzinfo)
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

  @doc false
  @spec lookup_posix(String.t()) :: PosixTimezone.t() | nil
  def lookup_posix(timezone) when is_binary(timezone) do
    with {:ok, %PosixTimezone{} = posixtz, _} <- Posix.parse(timezone) do
      posixtz
    else
      _ ->
        nil
    end
  end

  def lookup_posix(_), do: nil
end
