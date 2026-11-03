defmodule Timex.Parse.Timezones.Posix do
  @moduledoc """
  Parses POSIX-style timezones:

  ## Format

  POSIX-style timezones are of the format: `stdoffset[dst[offset][,start[/time],end[/time]]]`

  `std` and `dst` are abbreviations. The `start` and `end` dates use one of the following formats:

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

  Transition times are signed seconds from midnight in the parsed rule bounds.
  Hours may range from -167 through 167, allowing transitions on adjacent days.
  Timezone offset hours retain their separate range of 0 through 24.
  The timezone name includes its explicit transition rules so it can be reparsed.
  Pass `extended_transition_times: false` to `parse/2` for classic unsigned
  transition hours through 24, as required in a version 2 TZif footer.

  For more info, see [POSIX.1-2024](https://pubs.opengroup.org/onlinepubs/9799919799/basedefs/V1_chap08.html)
  and [RFC 9636 section 3.3.2](https://www.rfc-editor.org/rfc/rfc9636.html#section-3.3.2).

  ## Example

  TZ = `CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00`

  This would represents a change to daylight saving time at 2:00 AM on the second Sunday
  in March and change back at 2:00 AM on the first Sunday in November, and keep 6 hours time
  offset from GMT every year. The breakdown of the string is:

  - `CST6CDT` is the timezone header (the full name also includes the transition rules)
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

  def parse(s, options \\ []) when is_binary(s) do
    extended? = Keyword.get(options, :extended_transition_times, true)

    with {:ok, format_str, rest} <- parse_newline_terminated_str(s),
         {:ok, tz, format_rest} <- parse_tz(format_str, extended?) do
      {:ok, finalize(tz, format_str, format_rest), format_rest <> rest}
    end
  end

  defp finalize(nil, _input, _rest), do: nil

  defp finalize(tz, input, rest) do
    tz = finalize(tz)
    consumed = binary_part(input, 0, byte_size(input) - byte_size(rest))

    case :binary.match(consumed, ",") do
      {index, 1} ->
        %{tz | name: tz.name <> binary_part(consumed, index, byte_size(consumed) - index)}

      :nomatch ->
        tz
    end
  end

  defp finalize(%TZ{std_abbr: std, std_offset: soffs, dst_abbr: dst, dst_offset: nil} = tz)
       when is_binary(dst) do
    # DST exists, but offset is unset, so the standard dictates that this means an hour ahead of standard
    %TZ{
      tz
      | name: "#{quote_abbrev(std)}#{to_offset(soffs)}#{quote_abbrev(dst)}",
        dst_offset: soffs + 3600
    }
  end

  defp finalize(%TZ{std_abbr: std, std_offset: soffs, dst_abbr: nil, dst_offset: nil} = tz) do
    # No DST, so set the abbreviation to STD and set the offset to the same
    %TZ{tz | name: "#{quote_abbrev(std)}#{to_offset(soffs)}", dst_abbr: std, dst_offset: soffs}
  end

  defp finalize(
         %TZ{name: nil, std_abbr: std, std_offset: soffs, dst_abbr: dst, dst_offset: doffs} = tz
       ) do
    # Retain an explicitly specified DST offset, including non-default offsets.
    %TZ{
      tz
      | name: "#{quote_abbrev(std)}#{to_offset(soffs)}#{quote_abbrev(dst)}#{to_offset(doffs)}"
    }
  end

  defp quote_abbrev(abbreviation) do
    if abbreviation |> String.to_charlist() |> Enum.all?(fn c -> is_alphabetic(c) end),
      do: abbreviation,
      else: "<#{abbreviation}>"
  end

  defp to_offset(0), do: "0"

  defp to_offset(n) do
    sign = if n > 0, do: "-", else: ""
    n = abs(n)
    hours = div(n, 3600)
    minutes = div(rem(n, 3600), 60)
    seconds = rem(n, 60)

    cond do
      seconds == 0 and minutes == 0 ->
        "#{sign}#{hours}"

      seconds == 0 ->
        "#{sign}#{hours}:#{String.pad_leading(to_string(minutes), 2, "0")}"

      :else ->
        "#{sign}#{hours}:#{String.pad_leading(to_string(minutes), 2, "0")}:#{String.pad_leading(to_string(seconds), 2, "0")}"
    end
  end

  defp parse_tz("", _extended?), do: {:ok, nil, ""}
  defp parse_tz(str, extended?), do: parse_tz(:std_abbr, str, %TZ{}, extended?)

  defp parse_tz(:std_abbr, str, %TZ{} = rule, extended?) do
    with {:ok, abbr, rest} <- parse_abbrev(str) do
      parse_tz(:std_offset, rest, %TZ{rule | std_abbr: abbr}, extended?)
    end
  end

  defp parse_tz(:std_offset, str, %TZ{} = rule, extended?) do
    with {:ok, offset, rest} <- parse_offset(str) do
      parse_tz(:dst_abbr, rest, %TZ{rule | std_offset: offset}, extended?)
    else
      {:error, nil, rest} ->
        {:error, :invalid_offset, rest}

      {:error, _, _} = err ->
        err
    end
  end

  # dst[offset][,...]
  defp parse_tz(:dst_abbr, "", %TZ{} = rule, _extended?), do: {:ok, rule, ""}

  defp parse_tz(:dst_abbr, str, %TZ{} = rule, extended?) do
    with {:ok, abbr, rest} <- parse_abbrev(str),
         rule = %TZ{rule | dst_abbr: abbr} do
      # dst_offset is optional, and may or may not be followed by a comma and start/end rule
      # if the offset is not present.
      case rest do
        <<>> ->
          {:ok, rule, ""}

        <<?,, rest::binary>> ->
          parse_tz(:rule_period, rest, rule, extended?)

        _ ->
          parse_tz(:dst_offset, rest, rule, extended?)
      end
    end
  end

  # offset[,...]
  defp parse_tz(:dst_offset, str, %TZ{} = rule, extended?) do
    with {:ok, offset, rest} <- parse_offset(str),
         rule = %TZ{rule | dst_offset: offset} do
      case rest do
        <<>> ->
          {:ok, rule, ""}

        <<?,, rest::binary>> ->
          parse_tz(:rule_period, rest, rule, extended?)

        _ ->
          {:error, :invalid_tz_rule_format, rest}
      end
    end
  end

  defp parse_tz(:rule_period, str, %TZ{} = rule, extended?) do
    case String.split(str, ",", parts: 2, trim: false) do
      [start_dt, end_dt] ->
        with {:ok, dst_start, ""} <- parse_posixtz_datetime(start_dt, extended?),
             {:ok, dst_end, rest} <- parse_posixtz_datetime(end_dt, extended?) do
          {:ok, %TZ{rule | dst_start: dst_start, dst_end: dst_end}, rest}
        else
          {:ok, _, rest} -> {:error, :invalid_tz_rule_format, rest}
          {:error, _, _} = error -> error
        end

      _ ->
        {:error, :expected_datetime_range, str}
    end
  end

  defp parse_posixtz_datetime(str, extended?) do
    result =
      case str do
        <<?M, rest::binary>> -> parse_month_week_day(rest)
        <<?J, rest::binary>> -> parse_julian_day(rest, allow_leap_days: false)
        _ -> parse_julian_day(str, allow_leap_days: true)
      end

    with {:ok, date, rest} <- result do
      case rest do
        <<?/, rest::binary>> ->
          with {:ok, time, rest} <- parse_time(rest, extended?) do
            {:ok, {date, time}, rest}
          end

        _ ->
          {:ok, {date, 7200}, rest}
      end
    end
  end

  defp parse_month_week_day(str) do
    case String.split(str, ".", parts: 3, trim: false) do
      [m, n, rest] ->
        case parse_integer_unsigned(rest) do
          {:ok, d, rest} ->
            with {:ok, date} <- parse_month_week_day(m, n, d) do
              {:ok, date, rest}
            else
              {:error, reason} ->
                {:error, reason, str}
            end

          {:error, _, _} ->
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

  defp parse_quoted_abbrev(<<c::char(), rest::binary>>, acc)
       when is_alphabetic(c) or is_digit(c) or c in [?+, ?-],
       do: parse_quoted_abbrev(rest, acc <> <<c::char()>>)

  defp parse_quoted_abbrev(<<>>, acc),
    do: {:error, :unclosed_quoted_abbreviation, acc}

  defp parse_quoted_abbrev(rest, acc),
    do: {:error, {:invalid_quoted_abbreviation, acc}, rest}

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

    with {:ok, {hour, minute, second}, rest} <- parse_time_components(str, 24) do
      {:ok, sign * (hour * 3600 + minute * 60 + second), rest}
    end
  end

  defp parse_time(<<sign, rest::binary>>, true) when sign in [?+, ?-],
    do: parse_time(rest, 167, if(sign == ?-, do: -1, else: 1))

  defp parse_time(str, extended?), do: parse_time(str, if(extended?, do: 167, else: 24), 1)

  defp parse_time(str, max_hour, sign) do
    with {:ok, {hour, minute, second}, rest} <- parse_time_components(str, max_hour) do
      {:ok, sign * (hour * 3600 + minute * 60 + second), rest}
    end
  end

  defp parse_time_components(str, max_hour) do
    case parse_integer_unsigned(str) do
      {:ok, hh, <<?:, rest::binary>>} when hh >= 0 and hh <= max_hour ->
        case parse_integer_unsigned(rest) do
          {:ok, mm, <<?:, rest::binary>>} when mm >= 0 and mm < 60 ->
            case parse_integer_unsigned(rest) do
              {:ok, ss, rest} when ss >= 0 and ss < 60 ->
                {:ok, {hh, mm, ss}, rest}

              _ ->
                {:error, :invalid_second, rest}
            end

          {:ok, mm, rest} when mm >= 0 and mm < 60 ->
            {:ok, {hh, mm, 0}, rest}

          _ ->
            {:error, :invalid_minute, rest}
        end

      {:ok, hh, rest} when hh >= 0 and hh <= max_hour ->
        {:ok, {hh, 0, 0}, rest}

      {:ok, _, _} ->
        {:error, :invalid_hour, str}

      {:error, :invalid_number, str} ->
        {:error, nil, str}
    end
  end

  defp to_integer(n) when is_integer(n) and n >= 0, do: {:ok, n}

  defp to_integer(s) when is_binary(s) do
    case parse_integer_unsigned(s) do
      {:ok, n, ""} ->
        {:ok, n}

      _ ->
        {:error, :invalid_number}
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
