defmodule Timex.Parse.ZoneInfo.Parser do
  @moduledoc """
  This module is responsible for parsing binary zoneinfo files,
  such as those found in /usr/local/zoneinfo.
  """

  # See http://linux.about.com/library/cmd/blcmdl5_tzfile.htm or
  # https://github.com/eggert/tz/blob/master/tzfile.h for details on the tzfile format
  defmodule Zone do
    @moduledoc """
    Represents the data retreived from a binary tzfile.
    For details on the tzfile format, see:

      http://www.cstdbill.com/tzdb/tzfile-format.html
      http://linux.about.com/library/cmd/blcmdl5_tzfile.htm
      https://github.com/eggert/tz/blob/master/tzfile.h
    """
    defstruct transitions: [],     # Transition times
              abbreviations: [],   # Zone abbreviations,
              leaps: [],           # Leap second adjustments
              std_or_wall?: false, # whether local transitions are standard or wall
              utc_or_local?: false # whether local transitions are UTC or local
  end

  defmodule Header do
    @moduledoc false

    # Six big-endian 4-8 byte integers
    defstruct utc_count: 0,        # count of UTC/local indicators
              wall_count: 0,       # count of standard/wall indicators
              leap_count: 0,       #  number of leap seconds
              transition_count: 0, #  number of transition times
              type_count: 0,       #  number of local time types (never zero)
              abbrev_length: 0     #  total number of characters of the zone abbreviations string
  end

  defmodule TransitionInfo do
    @moduledoc false
    defstruct gmt_offset: 0,       # total ISO 8601 offset (std + dst)
              starts_at: 0,        # The time at which this transition starts
              is_dst?: false,      # Is this transition in daylight savings time
              abbrev_index: 0,     # The lookup index of the abbreviation
              abbreviation: "N/A", # The zone abbreviation
              is_std?: true,       # Whether transitions are standard or wall
              is_utc?: false       # Whether transitions are UTC or local
  end

  defmodule LeapSecond do
    @moduledoc false
    defstruct start: 0,    # The time at which this leap second occurs
              remaining: 0 # The count of leap seconds after this leap second
  end


  ##############
  # Macros defining common bitstring modifier combinations in zoneinfo files
  defmacrop bytes(size) do
    quote do: binary-size(unquote(size))-unit(8)
  end
  defmacrop integer_32bit_be do
    quote do: big-size(4)-unit(8)-integer
  end
  defmacrop signed_char_be do
    quote do: big-size(1)-unit(8)-signed-integer
  end
  defmacrop unsigned_char_be do
    quote do: big-size(1)-unit(8)-unsigned-integer
  end

  @doc """
  Given a path to a zoneinfo file, or the binary data from a zoneinfo file,
  parse the timezone information inside, and return it as a Zone struct.
  """
  @spec parse(binary) :: {:ok, Zone.t} | {:error, binary}
  def parse(<<?T, ?Z, ?i, ?f, _reserved :: bytes(16), rest :: binary>>) do
    do_parse_header(rest)
  end
  def parse(path) when is_binary(path) do
    if path |> File.exists? do
      path |> File.read! |> parse
    else
      {:error, "No zoneinfo file at #{path}"}
    end
  end
  def parse(_) do
    {:error, "Invalid zoneinfo file header"}
  end

  # Parse the header information from the zoneinfo file
  defp do_parse_header(<<header :: bytes(24), rest :: binary>>) do
    {utc_count, next}  = parse_int(header)
    {wall_count, next} = parse_int(next)
    {leap_count, next} = parse_int(next)
    {tx_count, next}   = parse_int(next)
    {type_count, next} = parse_int(next)
    {abbrev_length, _} = parse_int(next)
    header = %Header{
      utc_count: utc_count,
      wall_count: wall_count,
      leap_count: leap_count,
      transition_count: tx_count,
      type_count: type_count,
      abbrev_length: abbrev_length
    }
    do_parse_transition_times(rest, header)
  end
  # Parse the number of transition times in this zone
  defp do_parse_transition_times(data, %Header{transition_count: tx_count} = header) do
    {times, rest} = parse_array(data, tx_count, &parse_int/1)
    do_parse_transition_info(rest, header, %Zone{transitions: times})
  end
  # Parse transition time info for this zone
  defp do_parse_transition_info(
    data,
    %Header{transition_count: tx_count, type_count: type_count} = header,
    %Zone{transitions: transitions} = tzfile
  ) do
    {indices, rest} = parse_array data, tx_count, &parse_uchar/1
    {txinfos, rest} = parse_array rest, type_count, fn data ->
      {gmt_offset, next}   = parse_int(data)
      {is_dst?, next}      = parse_char(next)
      {abbrev_index, next} = parse_uchar(next)
      info = %TransitionInfo{
        gmt_offset: gmt_offset,
        is_dst?: is_dst? == 1,
        abbrev_index: abbrev_index
      }
      {info, next}
    end
    txs = indices
          |> Enum.map(&(Enum.at(txinfos, &1)))
          |> Enum.zip(transitions)
          |> Enum.map(fn {info, time} ->
            Map.put(info, :starts_at, time)
          end)
    do_parse_abbreviations(rest, header, %{tzfile | :transitions => txs})
  end
  # Parses zone abbreviations for this zone
  defp do_parse_abbreviations(data, %Header{abbrev_length: len} = header, %Zone{transitions: transitions} = tzfile) do
    {abbrevs, rest} = parse_array(data, len, &parse_char/1)
    txinfos = Enum.map(transitions, fn %TransitionInfo{abbrev_index: idx} = tx ->
      abbrev = abbrevs
        |> Enum.drop(idx)
        |> Enum.take_while(fn c -> c > 0 end)
      %{tx | :abbreviation => "#{abbrev}"}
    end)
    do_parse_leap_seconds(rest, header, %{tzfile | :transitions => txinfos})
  end
  # Parses leap second information for this zone
  defp do_parse_leap_seconds(data, %Header{leap_count: count} = header, tzfile) do
    {leaps, rest} = parse_array data, count, fn data ->
      {start, next}     = parse_int(data)
      {remaining, next} = parse_int(next)
      leap = %LeapSecond{
        start: start,
        remaining: remaining
      }
      {leap, next}
    end
    do_parse_flags(rest, header, %{tzfile | :leaps => leaps})
  end
  # Parses the trailing flags in the zoneinfo binary
  defp do_parse_flags(data, %Header{utc_count: utc_count, wall_count: wall_count}, tzfile) do
    {is_std, rest} = parse_array(data, wall_count, &parse_char/1)
    {is_gmt, _} = parse_array(rest, utc_count, &parse_char/1)
    {:ok, %{tzfile | :std_or_wall? => is_std, :utc_or_local? => is_gmt}}
  end

  ################
  # Parses an array of a primitive type, ex:
  #   parse_array(<<"test">>, 2, &parse_uchar/1) => [?t, ?e]
  ###
  defp parse_array(data, 0, _parser), do: {[], data}
  defp parse_array(data, count, parser) when is_binary(data) and is_function(parser) do
    {results, rest} = Range.new(1, count)
      |> Enum.reduce({[], data}, &do_parse_array(&1, &2, parser))
    {results |> Enum.reverse, rest}
  end
  defp do_parse_array(_, {acc, data}, parser) when is_function(parser) do
    {item, next} = parser.(data)
    {[item | acc], next}
  end

  #################
  # Data Type Parsers
  defp parse_int(<<val :: integer_32bit_be, rest :: binary>>),   do: {val, rest}
  defp parse_char(<<val :: signed_char_be, rest :: binary>>),    do: {val, rest}
  defp parse_uchar(<<val :: unsigned_char_be, rest :: binary>>), do: {val, rest}
end
