defmodule Timex.Parse.ZoneInfo.Parser do
  @moduledoc """
  This module is responsible for parsing binary zoneinfo files,
  such as those found in /usr/local/zoneinfo.

  Supports TZif versions 1 through 4. Leap-second records, including version 4
  truncation and expiration data, are returned as raw records.
  """

  # See https://www.rfc-editor.org/rfc/rfc9636.html for details
  alias Timex.Parse.Timezones.Posix

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

    @type t :: %__MODULE__{}
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
    # Offsets retain POSIX seconds west of UTC. Ordinary bounds retain Time;
    # newly supported carried bounds use signed seconds from midnight.
    defstruct std_abbr: nil,
              std_offset: 0,
              dst_abbr: nil,
              dst_offset: 0,
              start_time: nil,
              end_time: nil
  end

  ##############
  # Macros defining common bitstring modifier combinations in zoneinfo files

  defmacrop char() do
    quote do: size(1) - unit(8) - integer
  end

  defmacrop bytes(size) do
    quote do: binary - size(unquote(size)) - unit(8)
  end

  defmacrop integer_32bit_be do
    quote do: big - size(4) - unit(8) - signed - integer
  end

  defmacrop integer_64bit_be do
    quote do: big - size(8) - unit(8) - signed - integer
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
  @spec parse(binary) :: {:ok, Zone.t()} | {:error, term()}
  def parse(<<?T, ?Z, ?i, ?f, version::bytes(1), _reserved::bytes(15), rest::binary>>) do
    version =
      case version do
        <<0>> ->
          1

        <<?2>> ->
          2

        <<?3>> ->
          3

        <<?4>> ->
          4

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
    with {:ok, %Zone{} = zone, rest} <- parse_content(1, data, %Zone{version: 1}) do
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
        4 -> <<?4>>
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

      {:error, _, _} = error ->
        error
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
    {utc_count, header_raw} = parse_u32(header_raw)
    {wall_count, header_raw} = parse_u32(header_raw)
    {leap_count, header_raw} = parse_u32(header_raw)
    {tx_count, header_raw} = parse_u32(header_raw)
    {type_count, header_raw} = parse_u32(header_raw)
    {abbrev_length, _} = parse_u32(header_raw)

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
  defp parse_transition_times(
         version,
         data,
         %Header{transition_count: tx_count} = header,
         %Zone{} = zone
       ) do
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
    <<abbrevs::bytes(^len), rest::binary>> = data

    txinfos =
      Enum.map(transitions, fn %TransitionInfo{abbrev_index: idx} = tx ->
        {:ok, abbrev, _} = parse_null_terminated_str(:binary.part(abbrevs, idx, len - idx))

        %{tx | :abbreviation => abbrev}
      end)

    parse_leap_seconds(version, rest, header, %Zone{zone | transitions: txinfos})
  end

  # Parses leap second information for this zone
  defp parse_leap_seconds(version, data, %Header{leap_count: count} = header, %Zone{} = zone) do
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
  defp parse_flags(
         version,
         data,
         %Header{utc_count: utc_count, wall_count: wall_count},
         %Zone{} = zone
       ) do
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

  # TZif frames its footer with two newlines. Parse only the complete enclosed
  # string; the shared POSIX scanner also supports embedded input and remainders.
  defp parse_posixtz_string(version, <<?\n, data::binary>>, %Zone{} = zone) do
    case :binary.match(data, "\n") do
      {size, 1} ->
        <<footer::binary-size(^size), ?\n, rest::binary>> = data

        case Posix.parse(footer, extended_transition_times: version >= 3) do
          {:ok, rule, ""} ->
            {:ok, %Zone{zone | rule: to_rule(rule)}, rest}

          {:ok, _, remainder} ->
            {:error, :invalid_tz_rule_format, remainder}

          {:error, reason, remainder} ->
            {:error, reason, remainder}
        end

      :nomatch ->
        {:error, :unterminated_posix_footer, data}
    end
  end

  defp parse_posixtz_string(_version, rest, _zone) do
    {:error, {:invalid_format, "expected newline to follow set of utc/local indicators"}, rest}
  end

  defp to_rule(nil), do: nil

  defp to_rule(%Timex.PosixTimezone{} = tz) do
    %Rule{
      std_abbr: tz.std_abbr,
      std_offset: -tz.std_offset,
      dst_abbr: tz.dst_abbr,
      dst_offset: -tz.dst_offset,
      start_time: to_rule_bound(tz.dst_start),
      end_time: to_rule_bound(tz.dst_end)
    }
  end

  defp to_rule_bound(nil), do: nil

  defp to_rule_bound({date, seconds}) do
    date =
      case date do
        {:julian, day} -> {:julian, day, [allow_leap_days: false]}
        {:julian_leap, day} -> {:julian, day, [allow_leap_days: true]}
        other -> other
      end

    time =
      if seconds >= 0 and seconds < 86_400 do
        Time.new!(div(seconds, 3600), div(rem(seconds, 3600), 60), rem(seconds, 60), 0)
      else
        seconds
      end

    {date, time}
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

  defp parse_i32(<<val::integer_32bit_be(), rest::binary>>), do: {val, rest}
  defp parse_i64(<<val::integer_64bit_be(), rest::binary>>), do: {val, rest}
  defp parse_u32(<<val::unsigned-big-integer-size(32), rest::binary>>), do: {val, rest}
  defp parse_char(<<val::signed_char_be(), rest::binary>>), do: {val, rest}
  defp parse_uchar(<<val::unsigned_char_be(), rest::binary>>), do: {val, rest}

  defp parse_null_terminated_str(bin), do: parse_null_terminated_str(bin, <<>>)

  defp parse_null_terminated_str(<<>>, acc), do: {:ok, acc, ""}
  defp parse_null_terminated_str(<<0, rest::binary>>, acc), do: {:ok, acc, rest}

  defp parse_null_terminated_str(<<c::char(), rest::binary>>, acc) do
    parse_null_terminated_str(rest, acc <> <<c::char()>>)
  end
end
