defmodule Timex.Parse.ZoneInfo.Parser do
  @moduledoc """
  This module is responsible for parsing binary zoneinfo files,
  such as those found in /usr/local/zoneinfo.
  """

  # See https://tools.ietf.org/id/draft-murchison-tzdist-tzif-00.html for details 
  defmodule Zone do
    @moduledoc """
    Represents the data retrieved from a binary tzfile.
    """
    # Maximum version encountered
    defstruct version: nil,
              # Transition times
              transitions: [],
              # Leap second adjustments
              leaps: [],
              # POSIX-TZ rule that describes the zone for future dates
              rule: nil
  end

  defmodule Header do
    @moduledoc false

    # Six big-endian 4-8 byte integers
    # count of UTC/local indicators
    defstruct utc_count: 0,
              # count of standard/wall indicators
              wall_count: 0,
              #  number of leap seconds
              leap_count: 0,
              #  number of transition times
              transition_count: 0,
              #  number of local time types (never zero)
              type_count: 0,
              #  total number of characters of the zone abbreviations string
              abbrev_length: 0
  end

  defmodule TransitionInfo do
    @moduledoc false
    # total ISO 8601 offset (std + dst)
    defstruct gmt_offset: 0,
              # The time at which this transition starts
              starts_at: 0,
              # Is this transition in daylight savings time
              is_dst?: false,
              # The lookup index of the abbreviation
              abbrev_index: 0,
              # The zone abbreviation
              abbreviation: "N/A",
              # Whether transitions are standard or wall
              is_std?: true,
              # Whether transitions are UTC or local
              is_utc?: false
  end

  defmodule LeapSecond do
    @moduledoc false
    # The time at which this leap second occurs
    defstruct epoch: 0,
              # The number of leap seconds to be applied to UTC on/after epoch
              correction: 0
  end

  defmodule Rule do
    @moduledoc false
    defstruct std_abbr: nil,
              std_offset: 0,
              dst_abbr: nil,
              dst_offset: 0,
              start_time: nil,
              end_time: nil
  end

  defguardp is_digit(c) when c >= ?0 and c <= ?9
  defguardp is_alphabetic(c) when (c >= ?A and c <= ?Z) or (c >= ?a and c <= ?z)

  ##############
  # Macros defining common bitstring modifier combinations in zoneinfo files

  defmacrop char() do
    quote do: size(1) - unit(8) - integer
  end

  defmacrop bytes(size) do
    quote do: binary - size(unquote(size)) - unit(8)
  end

  defmacrop integer_32bit_be do
    quote do: big - size(4) - unit(8) - integer
  end

  defmacrop integer_64bit_be do
    quote do: big - size(8) - unit(8) - integer
  end

  defmacrop signed_char_be do
    quote do: big - size(1) - unit(8) - signed - integer
  end

  defmacrop unsigned_char_be do
    quote do: big - size(1) - unit(8) - unsigned - integer
  end

  @doc """
  Parses a binary representing a valid zoneinfo file.

  Parses the timezone information inside, and returns it as a Zone struct.
  """
  @spec parse(binary) :: {:ok, Zone.t()} | {:error, binary}
  def parse(<<?T, ?Z, ?i, ?f, version::bytes(1), _reserved::bytes(15), rest::binary>>) do
    version =
      case version do
        <<0>> ->
          1

        <<?2>> ->
          2

        <<?3>> ->
          3

        byte ->
          {:error, {:invalid_tzfile_version, byte}, rest}
      end

    with v when is_integer(v) <- version,
         {:ok, zoneinfo, _} <- parse_versioned_content(v, rest) do
      {:ok, zoneinfo}
    else
      {:error, reason, _} ->
        {:error, reason}
    end
  end

  def parse(_) do
    {:error, :invalid_zoneinfo_content}
  end

  @doc """
  Like `parse/1`, but expects a file path to parse.
  """
  def parse_file(path) when is_binary(path) do
    if path |> File.exists?() do
      path |> File.read!() |> parse()
    else
      {:error, "No zoneinfo file at #{path}"}
    end
  end

  # Parses the content of a tzinfo file based on the version format
  defp parse_versioned_content(version, data)

  defp parse_versioned_content(1, data) do
    with {:ok, zone, rest} <- parse_content(1, data, %Zone{version: 1}) do
      transitions = Enum.sort_by(zone.transitions, fn tx -> tx.starts_at end)
      leaps = Enum.sort_by(zone.leaps, fn leap -> leap.epoch end)
      {:ok, %Zone{zone | transitions: transitions, leaps: leaps}, rest}
    end
  end

  defp parse_versioned_content(version, data) do
    expected_version =
      case version do
        1 -> <<0>>
        2 -> <<?2>>
        3 -> <<?3>>
      end

    with {:ok, zone1, rest} <- parse_content(1, data, %Zone{version: 1}),
         {:header, <<?T, ?Z, ?i, ?f, ^expected_version::bytes(1), _::bytes(15), rest::binary>>} <-
           {:header, rest},
         {:ok, zone2, rest} <- parse_content(version, rest, %Zone{version: version}) do
      # Append the second set of zone info to the first set
      transitions =
        zone1.transitions
        |> Enum.concat(zone2.transitions)
        |> Enum.sort_by(fn tx -> tx.starts_at end)

      leaps =
        zone1.leaps
        |> Enum.concat(zone2.leaps)
        |> Enum.sort_by(fn leap -> leap.epoch end)

      zone = %Zone{
        version: zone2.version,
        transitions: transitions,
        leaps: leaps,
        rule: zone2.rule
      }

      {:ok, zone, rest}
    else
      {:header, bytes} ->
        {:error, {:invalid_version_header, version}, bytes}
    end
  end

  # Parsing the content of a tzinfo file starting with the header
  #
  # ## Header Format
  #
  #     +---------------+---+
  #     |  magic    (4) | <-+-- version (1)
  #     +---------------+---+---------------------------------------+
  #     |           [unused - reserved for future use] (15)         |
  #     +---------------+---------------+---------------+-----------+
  #     |  isutccnt (4) |  isstdcnt (4) |  leapcnt  (4) |
  #     +---------------+---------------+---------------+
  #     |  timecnt  (4) |  typecnt  (4) |  charcnt  (4) |
  #     ---
  #
  # ## 32-bit Body Format
  #
  #     |  transition times          (timecnt x 4)    ...
  #     +-----------------------------------------------+
  #     |  transition time index     (timecnt)        ...
  #     +-----------------------------------------------+
  #     |  local time type records   (typecnt x 6)    ...
  #     +-----------------------------------------------+
  #     |  time zone designations    (charcnt)        ...
  #     +-----------------------------------------------+
  #     |  leap second records       (leapcnt x 8)    ...
  #     +-----------------------------------------------+
  #     |  standard/wall indicators  (isstdcnt)       ...
  #     +-----------------------------------------------+
  #     |  UTC/local indicators      (isutccnt)       ...
  #     +-----------------------------------------------+
  #
  # ## 64-bit Body Format
  #
  #     |  transition times          (timecnt x 8)    ...
  #     +-----------------------------------------------+
  #     |  transition time index     (timecnt)        ...
  #     +-----------------------------------------------+
  #     |  local time type records   (typecnt x 6)    ...
  #     +-----------------------------------------------+
  #     |  time zone designations    (charcnt)        ...
  #     +-----------------------------------------------+
  #     |  leap second records       (leapcnt x 12)   ...
  #     +-----------------------------------------------+
  #     |  standard/wall indicators  (isstdcnt)       ...
  #     +-----------------------------------------------+
  #     |  UTC/local indicators      (isutccnt)       ...
  #     +---+---------------------------------------+---+
  #     | NL| POSIX TZ string       (0...)          |NL |
  #     +---+---------------------------------------+---+
  defp parse_content(version, <<header_raw::bytes(24), rest::binary>>, zone) do
    {utc_count, header_raw} = parse_i32(header_raw)
    {wall_count, header_raw} = parse_i32(header_raw)
    {leap_count, header_raw} = parse_i32(header_raw)
    {tx_count, header_raw} = parse_i32(header_raw)
    {type_count, header_raw} = parse_i32(header_raw)
    {abbrev_length, _} = parse_i32(header_raw)

    header = %Header{
      utc_count: utc_count,
      wall_count: wall_count,
      leap_count: leap_count,
      transition_count: tx_count,
      type_count: type_count,
      abbrev_length: abbrev_length
    }

    parse_transition_times(version, rest, header, zone)
  end

  # Parse the number of transition times in this zone
  defp parse_transition_times(version, data, %Header{transition_count: tx_count} = header, zone) do
    {times, rest} = parse_array(data, tx_count, &parse_int(version, &1))
    parse_transition_info(version, rest, header, %Zone{zone | transitions: times})
  end

  # Parse transition time info for this zone
  defp parse_transition_info(
         version,
         data,
         %Header{transition_count: tx_count, type_count: type_count} = header,
         %Zone{transitions: transitions} = zone
       ) do
    {indices, rest} = parse_array(data, tx_count, &parse_uchar/1)

    {txinfos, rest} =
      parse_array(rest, type_count, fn data ->
        {gmt_offset, next} = parse_i32(data)
        {is_dst, next} = parse_char(next)
        {abbrev_index, next} = parse_uchar(next)

        info = %TransitionInfo{
          gmt_offset: gmt_offset,
          is_dst?: is_dst == 1,
          abbrev_index: abbrev_index
        }

        {info, next}
      end)

    txs =
      indices
      |> Enum.map(&Enum.at(txinfos, &1))
      |> Enum.zip(transitions)
      |> Enum.map(fn {info, time} ->
        Map.put(info, :starts_at, time)
      end)

    parse_abbreviations(version, rest, header, %Zone{zone | transitions: txs})
  end

  # Parses zone abbreviations for this zone
  defp parse_abbreviations(
         version,
         data,
         %Header{abbrev_length: len} = header,
         %Zone{transitions: transitions} = zone
       ) do
    <<abbrevs::bytes(len), rest::binary>> = data

    txinfos =
      Enum.map(transitions, fn %TransitionInfo{abbrev_index: idx} = tx ->
        {:ok, abbrev, _} = parse_null_terminated_str(:binary.part(abbrevs, idx, len - idx))

        %{tx | :abbreviation => abbrev}
      end)

    parse_leap_seconds(version, rest, header, %Zone{zone | transitions: txinfos})
  end

  # Parses leap second information for this zone
  defp parse_leap_seconds(version, data, %Header{leap_count: count} = header, zone) do
    {leaps, rest} =
      parse_array(data, count, fn data ->
        {epoch, next} = parse_int(version, data)
        {correction, next} = parse_i32(next)

        leap = %LeapSecond{
          epoch: epoch,
          correction: correction
        }

        {leap, next}
      end)

    parse_flags(version, rest, header, %Zone{zone | leaps: leaps})
  end

  # Parses the trailing flags in the zoneinfo binary
  defp parse_flags(version, data, %Header{utc_count: utc_count, wall_count: wall_count}, zone) do
    {is_std_indicators, rest} = parse_array(data, wall_count, &parse_char/1)
    {is_utc_indicators, rest} = parse_array(rest, utc_count, &parse_char/1)

    transitions =
      zone.transitions
      |> Enum.with_index()
      |> Enum.map(fn {tx, i} ->
        is_std? = Enum.at(is_std_indicators, i) == 1
        is_utc? = Enum.at(is_utc_indicators, i) == 1
        %{tx | :is_std? => is_std?, :is_utc? => is_utc?}
      end)

    if version > 1 do
      parse_posixtz_string(version, rest, %Zone{zone | transitions: transitions})
    else
      {:ok, %Zone{zone | transitions: transitions}, rest}
    end
  end

  # stdoffset[dst[offset][,start[/time],end[/time]]]
  defp parse_posixtz_string(_version, <<?\n, rest::binary>>, zone) do
    with {:ok, format_str, rest} <- parse_newline_terminated_str(rest),
         {:ok, rule, format_rest} <- parse_tz(format_str) do
      {:ok, %Zone{zone | rule: rule}, format_rest <> rest}
    end
  end

  defp parse_posixtz_string(_version, rest, _zone) do
    {:error, {:invalid_format, "expected newline to follow set of utc/local indicators"}, rest}
  end

  defp parse_tz(""), do: {:ok, nil, ""}
  defp parse_tz(str), do: parse_tz(:std_abbr, str, %Rule{})

  defp parse_tz(:std_abbr, str, rule) do
    with {:ok, abbr, rest} <- parse_abbrev(str) do
      parse_tz(:std_offset, rest, %Rule{rule | std_abbr: abbr, dst_abbr: abbr})
    end
  end

  defp parse_tz(:std_offset, str, rule) do
    with {:ok, offset, rest} <- parse_offset(str) do
      parse_tz(:dst_abbr, rest, %Rule{rule | std_offset: offset, dst_offset: offset})
    else
      {:error, nil, ""} ->
        {:ok, rule, ""}

      {:error, nil, rest} ->
        parse_tz(:dst_abbr, rest, rule)

      {:error, _, _} = err ->
        err
    end
  end

  # dst[offset][,...]
  defp parse_tz(:dst_abbr, str, rule) do
    with {:ok, abbr, rest} <- parse_abbrev(str),
         rule = %Rule{rule | dst_abbr: abbr} do
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
         rule = %Rule{rule | dst_offset: offset} do
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
        with {:ok, start_time, _} <- parse_posixtz_datetime(start_dt),
             {:ok, end_time, rest} <- parse_posixtz_datetime(end_dt) do
          {:ok, %Rule{rule | start_time: start_time, end_time: end_time}, rest}
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
          {:ok, {:julian, day, opts}, rest}

        allow_leaps? ->
          {:error, {:invalid_julian_day, day}, str}

        # Day of year without Feb 29, i.e. day 59 is Feb 28, and day 60 is Mar 1
        day >= 1 and day <= 365 ->
          {:ok, {:julian, day, opts}, rest}

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
    sign = if sign == ?+, do: 1, else: -1

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
                {:ok, Timex.Time.new!(hh, mm, ss, 0), rest}

              _ ->
                {:ok, Timex.Time.new!(hh, mm, 0, 0), rest}
            end

          {:ok, mm, rest} when mm >= 0 and mm < 60 ->
            {:ok, Timex.Time.new!(hh, mm, 0, 0), rest}

          _ ->
            {:ok, Timex.Time.new!(hh, 0, 0, 0), rest}
        end

      {:ok, hh, rest} when hh >= 0 and hh <= 24 ->
        {:ok, Timex.Time.new!(hh, 0, 0, 0), rest}

      {:ok, _, _} ->
        {:error, :invalid_hour, str}

      {:error, _, _} = err ->
        err
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

  ################
  # Parses an array of a primitive type, ex:
  #   parse_array(<<"test">>, 2, &parse_uchar/1) => [?t, ?e]
  ###
  defp parse_array(data, 0, _parser), do: {[], data}

  defp parse_array(data, count, parser) when is_binary(data) and is_function(parser) do
    {results, rest} = do_parse_array(data, count, parser, [])
    {results, rest}
  end

  defp do_parse_array(data, 0, _, acc), do: {Enum.reverse(acc), data}

  defp do_parse_array(data, count, parser, acc) do
    {item, next} = parser.(data)
    do_parse_array(next, count - 1, parser, [item | acc])
  end

  #################
  # Data Type Parsers
  defp parse_int(1, bin), do: parse_i32(bin)
  defp parse_int(_, bin), do: parse_i64(bin)

  defp parse_i32(<<val::integer_32bit_be, rest::binary>>), do: {val, rest}
  defp parse_i64(<<val::integer_64bit_be, rest::binary>>), do: {val, rest}
  defp parse_char(<<val::signed_char_be, rest::binary>>), do: {val, rest}
  defp parse_uchar(<<val::unsigned_char_be, rest::binary>>), do: {val, rest}

  defp parse_null_terminated_str(bin), do: parse_null_terminated_str(bin, <<>>)

  defp parse_null_terminated_str(<<>>, acc), do: {:ok, acc, ""}
  defp parse_null_terminated_str(<<0, rest::binary>>, acc), do: {:ok, acc, rest}

  defp parse_null_terminated_str(<<c::char(), rest::binary>>, acc) do
    parse_null_terminated_str(rest, acc <> <<c::char()>>)
  end

  defp parse_newline_terminated_str(bin), do: parse_newline_terminated_str(bin, <<>>)

  defp parse_newline_terminated_str(<<>>, acc), do: {:ok, acc, ""}
  defp parse_newline_terminated_str(<<?\n, rest::binary>>, acc), do: {:ok, acc, rest}

  defp parse_newline_terminated_str(<<c::char(), rest::binary>>, acc) do
    parse_newline_terminated_str(rest, acc <> <<c::char()>>)
  end
end
