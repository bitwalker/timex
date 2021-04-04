defmodule Timex.Parse.Timezones.Posix do
  @moduledoc """
  Parses POSIX-style timezones:

  ## Format

  POSIX-style timezones are of the format: `stdoffset[dst[offset][,start[/time],end[/time]]]`

  Where `std`/`dst` are dates in one of the following formats:

  The `Mm.n.d` format, where:

  - `Mm` (1-12) for 12 months
  - `n` (1-5) 1 for the first week and 5 for the last week in the month
  - `d` (0-6) 0 for Sunday and 6 for Saturday

  The `Jn` format, where `n` is the julian day and leap days are excluded.

  Or the `n` format, where `n` is the julian day, and leap days are included.

  Offsets are optional, except for the `std` offset, and can be preceded by a sign. The offset indicates
  the time added to the local time to obtain UTC time. The offsets may be hours; hours and minutes;
  and hours, minutes, and seconds - colon separated between components. NOTE: The sign of the offset is
  opposite the usual expectation, positive numbers are west of GMT, and negative numbers are east of GMT,
  this is because the offset is the time added to _local_ time to arrive at UTC, rather than the other way
  around.

  For more info, see: https://pubs.opengroup.org/onlinepubs/9699919799/

  ## Example

  TZ = `CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00`

  This would represents a change to daylight saving time at 2:00 AM on the second Sunday
  in March and change back at 2:00 AM on the first Sunday in November, and keep 6 hours time
  offset from GMT every year. The breakdown of the string is:

  - `CST6CDT` is the timezone name (constructed by concatenating the abbreviation and offset of std/dst)
  - `CST` is the standard abbreviation
  - `6` is the offset from `CST` to get `UTC`
  - `CDT` is the DST abbreviation
  - There is no offset from `CDT`, so the standard assumes the offset is one hour ahead of `CST`, or `5`
  - `,M3` is the third month
  - `.2` is second week of the month
  - `.0` is the day of the week (Sunday in this case)
  - `/2:00:00` is the time at which `CST` changes to `CDT`; defaults to `2:00:00` if not specified
  - `,M11` is the eleventh month
  - `.1` is the first week of the month
  - `.0` is the day of the week
  - `/2:00:00` is the time at which `CDT` changes back to `CST`; defaults to `2:00:00` if not specified

  """
  alias Timex.PosixTimezone, as: TZ

  defguardp is_digit(c) when c >= ?0 and c <= ?9
  defguardp is_alphabetic(c) when (c >= ?A and c <= ?Z) or (c >= ?a and c <= ?z)

  defmacrop char() do
    quote do: size(1) - unit(8) - integer
  end

  def parse(s) when is_binary(s) do
    with {:ok, format_str, rest} <- parse_newline_terminated_str(s),
         {:ok, tz, format_rest} <- parse_tz(format_str) do
      {:ok, finalize(tz), format_rest <> rest}
    end
  end

  defp finalize(%TZ{std_abbr: std, std_offset: soffs, dst_abbr: dst, dst_offset: nil} = tz)
       when is_binary(dst) do
    # DST exists, but offset is unset, so the standard dictates that this means an hour ahead of standard
    %TZ{tz | name: "#{std}#{to_offset(soffs)}#{dst}", dst_offset: soffs + 3600}
  end

  defp finalize(%TZ{std_abbr: std, std_offset: soffs, dst_abbr: nil, dst_offset: nil} = tz) do
    # No DST, so set the abbreviation to STD and set the offset to the same
    %TZ{tz | name: "#{std}#{soffs}", dst_abbr: std, dst_offset: soffs}
  end

  defp finalize(
         %TZ{name: nil, std_abbr: std, std_offset: soffs, dst_abbr: dst, dst_offset: doffs} = tz
       ) do
    # Construct the full name for this zone
    if diff(soffs, doffs) == 3600 do
      # The DST offset is one hour ahead of the STD offset, so we can omit it
      %TZ{tz | name: "#{std}#{to_offset(soffs)}#{dst}"}
    else
      %TZ{tz | name: "#{std}#{to_offset(soffs)}#{dst}#{to_offset(doffs)}"}
    end
  end

  defp finalize(nil), do: nil

  defp diff(std, dst), do: std - dst

  defp to_offset(0), do: "0"

  defp to_offset(n) do
    n = n * -1
    hours = div(n, 3600)
    minutes = div(rem(n, 3600), 60)
    seconds = rem(minutes, 60)

    cond do
      seconds == 0 and minutes == 0 ->
        "#{hours}"

      seconds == 0 ->
        "#{hours}:#{String.pad_leading(minutes, 2, "0")}"

      :else ->
        "#{hours}:#{String.pad_leading(minutes, 2, "0")}:#{String.pad_leading(seconds, 2, "0")}"
    end
  end

  defp parse_tz(""), do: {:ok, nil, ""}
  defp parse_tz(str), do: parse_tz(:std_abbr, str, %TZ{})

  defp parse_tz(:std_abbr, str, rule) do
    with {:ok, abbr, rest} <- parse_abbrev(str) do
      parse_tz(:std_offset, rest, %TZ{rule | std_abbr: abbr})
    end
  end

  defp parse_tz(:std_offset, str, rule) do
    with {:ok, offset, rest} <- parse_offset(str) do
      parse_tz(:dst_abbr, rest, %TZ{rule | std_offset: offset})
    else
      {:error, nil, ""} ->
        {:error, :invalid_offset, ""}

      {:error, nil, rest} ->
        parse_tz(:dst_abbr, rest, rule)

      {:error, _, _} = err ->
        err
    end
  end

  # dst[offset][,...]
  defp parse_tz(:dst_abbr, str, rule) do
    with {:ok, abbr, rest} <- parse_abbrev(str),
         rule = %TZ{rule | dst_abbr: abbr} do
      # dst_offset is optional, and may or may not be followed by a comma and start/end rule
      # if the offset is not present.
      case rest do
        <<>> ->
          {:ok, rule, ""}

        <<?,, rest::binary>> ->
          parse_tz(:rule_period, rest, rule)

        _ ->
          parse_tz(:dst_offset, rest, rule)
      end
    end
  end

  # offset[,...]
  defp parse_tz(:dst_offset, str, rule) do
    with {:ok, offset, rest} <- parse_offset(str),
         rule = %TZ{rule | dst_offset: offset} do
      case rest do
        <<>> ->
          {:ok, rule, ""}

        <<?,, rest::binary>> ->
          parse_tz(:rule_period, rest, rule)

        _ ->
          {:error, :invalid_tz_rule_format}
      end
    else
      {:error, nil, ""} ->
        {:ok, rule, ""}

      {:error, nil, <<?,, rest::binary>>} ->
        parse_tz(:rule_period, rest, rule)

      {:error, _, _} = err ->
        err
    end
  end

  defp parse_tz(:rule_period, str, rule) do
    case String.split(str, ",", parts: 2, trim: false) do
      [start_dt, end_dt] ->
        with {:ok, dst_start, _} <- parse_posixtz_datetime(start_dt),
             {:ok, dst_end, rest} <- parse_posixtz_datetime(end_dt) do
          {:ok, %TZ{rule | dst_start: dst_start, dst_end: dst_end}, rest}
        else
          {:ok, _, rest} ->
            {:error, :expected_comma, rest}

          {:error, _, _} = err ->
            err
        end

      _ ->
        {:error, :expected_datetime_range, str}
    end
  end

  defp parse_posixtz_datetime(str) do
    result =
      case str do
        <<?M, rest::binary>> -> parse_month_week_day(rest)
        <<?J, rest::binary>> -> parse_julian_day(rest, allow_leap_days: false)
        _ -> parse_julian_day(str, allow_leap_days: true)
      end

    with {:ok, date, rest} <- result do
      case rest do
        <<?/, rest::binary>> ->
          with {:ok, time, rest} <- parse_time(rest) do
            {:ok, {date, time}, rest}
          end

        _ ->
          {:ok, {date, Timex.Time.new!(2, 0, 0, 0)}, rest}
      end
    end
  end

  defp parse_month_week_day(str) do
    case String.split(str, ".", parts: 3, trim: false) do
      [m, n, rest] ->
        case Integer.parse(rest) do
          {d, rest} ->
            with {:ok, date} <- parse_month_week_day(m, n, d) do
              {:ok, date, rest}
            else
              {:error, reason} ->
                {:error, reason, str}
            end

          :error ->
            {:error, :expected_day_number, str}
        end

      _ ->
        {:error, :invalid_month_week_day, str}
    end
  end

  defp parse_month_week_day(m, n, d) do
    with {:ok, m} <- to_integer(m),
         {:ok, n} <- to_integer(n),
         {:ok, d} <- to_integer(d) do
      cond do
        m < 1 or m > 12 ->
          {:error, :invalid_month}

        n < 1 or n > 5 ->
          {:error, :invalid_week_of_month}

        d < 0 or d > 6 ->
          {:error, :invalid_week_day}

        :else ->
          {:ok, {:mwd, {m, n, d}}}
      end
    else
      :error ->
        {:error, :invalid_number}
    end
  end

  defp parse_julian_day(str, opts) do
    with {:ok, day, rest} <- parse_integer_unsigned(str) do
      allow_leaps? = Keyword.get(opts, :allow_leap_days, true)

      cond do
        # Day of year including Feb 29
        allow_leaps? and day >= 0 and day <= 365 ->
          {:ok, {:julian_leap, day}, rest}

        allow_leaps? ->
          {:error, {:invalid_julian_day, day}, str}

        # Day of year without Feb 29, i.e. day 59 is Feb 28, and day 60 is Mar 1
        day >= 1 and day <= 365 ->
          {:ok, {:julian, day}, rest}

        :else ->
          {:error, {:invalid_julian_day, day}, str}
      end
    end
  end

  defp parse_abbrev(<<?<, rest::binary>>), do: parse_quoted_abbrev(rest)
  defp parse_abbrev(str), do: parse_unquoted_abbrev(str)

  defp parse_quoted_abbrev(str, acc \\ "")

  defp parse_quoted_abbrev(<<?>, rest::binary>>, acc) when byte_size(acc) < 3,
    do: {:error, {:invalid_quoted_abbreviation, acc}, rest}

  defp parse_quoted_abbrev(<<?>, rest::binary>>, acc),
    do: {:ok, acc, rest}

  defp parse_quoted_abbrev(<<c::char(), rest::binary>>, acc),
    do: parse_quoted_abbrev(rest, acc <> <<c::char()>>)

  defp parse_quoted_abbrev(<<>>, acc),
    do: {:error, :unclosed_quoted_abbreviation, acc}

  defp parse_unquoted_abbrev(str, acc \\ "")

  defp parse_unquoted_abbrev(<<c::char(), rest::binary>>, acc) when is_alphabetic(c),
    do: parse_unquoted_abbrev(rest, acc <> <<c::char()>>)

  defp parse_unquoted_abbrev(rest, acc) when byte_size(acc) < 3,
    do: {:error, {:invalid_unquoted_abbreviation, acc}, rest}

  defp parse_unquoted_abbrev(rest, acc),
    do: {:ok, acc, rest}

  defp parse_offset(<<sign::char(), rest::binary>>) when sign in [?+, ?-],
    do: parse_offset(rest, sign)

  defp parse_offset(str) when is_binary(str),
    do: parse_offset(str, ?+)

  defp parse_offset(str, sign) do
    sign = if sign == ?+, do: -1, else: 1

    with {:ok, time, rest} <- parse_time(str),
         {seconds, _} <- Timex.Time.to_seconds_after_midnight(time) do
      {:ok, sign * seconds, rest}
    end
  end

  defp parse_time(str) do
    case parse_integer_unsigned(str) do
      {:ok, hh, <<?:, rest::binary>>} when hh >= 0 and hh <= 24 ->
        case parse_integer_unsigned(rest) do
          {:ok, mm, <<?:, rest::binary>>} when mm >= 0 and mm < 60 ->
            case parse_integer_unsigned(rest) do
              {:ok, ss, rest} when ss >= 0 and ss < 60 ->
                {:ok, Timex.Time.new!(hh, mm, ss), rest}

              _ ->
                {:ok, Timex.Time.new!(hh, mm, 0), rest}
            end

          {:ok, mm, rest} when mm >= 0 and mm < 60 ->
            {:ok, Timex.Time.new!(hh, mm, 0), rest}

          _ ->
            {:ok, Timex.Time.new!(hh, 0, 0), rest}
        end

      {:ok, hh, rest} when hh >= 0 and hh <= 24 ->
        {:ok, Timex.Time.new!(hh, 0, 0), rest}

      {:ok, _, _} ->
        {:error, :invalid_hour, str}

      {:error, :invalid_number, str} ->
        {:error, nil, str}
    end
  end

  defp to_integer(n) when is_integer(n) and n >= 0, do: {:ok, n}

  defp to_integer(s) when is_binary(s) do
    with {:ok, n, _} <- parse_integer_signed(s) do
      {:ok, n}
    end
  end

  defp parse_integer_signed(str) do
    case Integer.parse(str) do
      {value, rest} ->
        {:ok, value, rest}

      _ ->
        {:error, :invalid_number, str}
    end
  end

  defp parse_integer_unsigned(str, acc \\ "")

  defp parse_integer_unsigned(<<c::char(), rest::binary>>, acc) when is_digit(c) do
    parse_integer_unsigned(rest, acc <> <<c::char()>>)
  end

  defp parse_integer_unsigned(rest, acc) when byte_size(acc) > 0 do
    {:ok, String.to_integer(acc), rest}
  end

  defp parse_integer_unsigned(rest, _) do
    {:error, :invalid_number, rest}
  end

  defp parse_newline_terminated_str(bin), do: parse_newline_terminated_str(bin, <<>>)

  defp parse_newline_terminated_str(<<>>, acc), do: {:ok, acc, ""}
  defp parse_newline_terminated_str(<<?\n, rest::binary>>, acc), do: {:ok, acc, rest}

  defp parse_newline_terminated_str(<<c::char(), rest::binary>>, acc) do
    parse_newline_terminated_str(rest, acc <> <<c::char()>>)
  end
end
