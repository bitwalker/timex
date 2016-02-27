defmodule Timex.Parse.Timezones.Posix do
  @moduledoc """
  Parses POSIX-style timezones:

  ## Format

  POSIX-style timezones are of the format: `local_timezone,date/time,date/time`

  Where `date` is in the `Mm.n.d` format, and where:

  - `Mm` (1-12) for 12 months
  - `n` (1-5) 1 for the first week and 5 for the last week in the month
  - `d` (0-6) 0 for Sunday and 6 for Saturday

  ## Example

  TZ = `CST6CDT,M3.2.0/2:00:00,M11.1.0/2:00:00`

  This would represents a change to daylight saving time at 2:00 AM on the second Sunday
  in March and change back at 2:00 AM on the first Sunday in November, and keep 6 hours time
  offset from GMT every year. The breakdown of the string is:

  - `CST6CDT` is the timezone name
  - `CST` is the standard abbreviation
  - `6` is the hours of time difference from GMT
  - `CDT` is the DST abbreviation
  - `,M3` is the third month
  - `.2` is the second occurrence of the day in the month
  - `.0` is Sunday
  - `/2:00:00` is the time
  - `,M11` is the eleventh month
  - `.1` is the first occurrence of the day in the month
  - `.0` is Sunday
  - `/2:00:00` is the time

  """
  defmodule PosixTimezone do
    @doc"""
    ## Spec

    ## dst_start/dst_end
    - `month`:       1-12
    - `week`:        week of the month
    - `day_of_week`: 0-6, 0 is Sunday
    - `time`:        {hour, minute, second}

    """
    defstruct name: "",
              std_name: "",
              dst_name: "",
              diff: 0,
              dst_start: nil,
              dst_end: nil
  end

  alias PosixTimezone, as: TZ

  # Start parsing provided zone name
  def parse(tz) when is_binary(tz) do
    case parse_posix(tz, :std_name, %TZ{:diff => "0"}) do
      {:ok, %TZ{:std_name => std, :dst_name => dst, :diff => diff} = res} ->
        {:ok, %{res | :name => "#{std}#{diff}#{dst}"}}
      {:error, _} = err ->
        err
      {:error, :invalid_time, :dst_start} ->
        {:error, :invalid_dst_start_time}
      {:error, :invalid_time, :dst_end} ->
        {:error, :invalid_dst_end_time}
    end
  end

  # Alpha character for standard name
  defp parse_posix(<<c::utf8, rest::binary>>, :std_name, %TZ{:std_name => acc} = result) when c in ?A..?Z do
    parse_posix(rest, :std_name, %{result | :std_name => <<acc::binary, c::utf8>>})
  end
  # Transition from standard name to diff from UTC
  defp parse_posix(<<c::utf8, rest::binary>>, :std_name, %TZ{:diff => acc} = result) when c in ?0..?9 do
    parse_posix(rest, :diff, %{result | :diff => <<acc::binary, c::utf8>>})
  end
  # Digit for diff from UTC
  defp parse_posix(<<c::utf8, rest::binary>>, :diff, %TZ{:diff => acc} = result) when c in ?0..?9 do
    parse_posix(rest, :diff, %{result | :diff => <<acc::binary, c::utf8>>})
  end
  # Transition from diff to DST name
  defp parse_posix(<<c::utf8, rest::binary>>, :diff, %TZ{:diff => diff, :dst_name => acc} = result) when c in ?A..?Z do
    # Convert diff to integer value
    parse_posix(rest, :dst_name, %{result | :diff => String.to_integer(diff), :dst_name => <<acc::binary, c::utf8>>})
  end
  # Alpha character for DST name
  defp parse_posix(<<c::utf8, rest::binary>>, :dst_name, %{:dst_name => acc} = result) when c in ?A..?Z do
    parse_posix(rest, :dst_name, %{result | :dst_name => <<acc::binary, c::utf8>>})
  end
  # Times
  defp parse_posix(<<?,, ?M, ?1, c::utf8, rest::binary>>, :dst_name, result) when c in ?0..?2 do
    start = %{month: String.to_integer(<<?1, c::utf8>>), week: nil, day_of_week: nil, time: nil}
    parse_week(rest, :dst_start, %{result | :dst_start => start})
  end
  defp parse_posix(<<?,, ?M, ?1, c::utf8, rest::binary>>, :dst_start, result) when c in ?0..?2 do
    new_end = %{month: String.to_integer(<<?1, c::utf8>>), week: nil, day_of_week: nil, time: nil}
    parse_week(rest, :dst_end, %{result | :dst_end => new_end})
  end
  defp parse_posix(<<?,, ?M, c::utf8, rest::binary>>, :dst_name, result) when c in ?1..?9 do
    start = %{month: String.to_integer(<<c::utf8>>), week: nil, day_of_week: nil, time: nil}
    parse_week(rest, :dst_start, %{result | :dst_start => start})
  end
  defp parse_posix(<<?,, ?M, c::utf8, rest::binary>>, :dst_start, result) when c in ?1..?9 do
    new_end = %{month: String.to_integer(<<c::utf8>>), week: nil, day_of_week: nil, time: nil}
    parse_week(rest, :dst_end, %{result | :dst_end => new_end})
  end
  # Reached end of input with all parts parsed
  defp parse_posix(<<>>, :dst_name, result), do: {:ok, result}
  defp parse_posix(<<>>, :dst_end, result),  do: {:ok, result}
  # Invalid character for current state
  defp parse_posix(<<_c::utf8, _rest::binary>>, _, _result), do: {:error, :not_posix}
  # Empty before all parts are processed
  defp parse_posix(<<>>, _, _result), do: {:error, :not_posix}

  defp parse_week(<<?., c::utf8, rest::binary>>, :dst_start, %{:dst_start => start} = result) when c in ?1..?5 do
    new_start = %{start | :week => String.to_integer(<<c::utf8>>)}
    parse_weekday(rest, :dst_start, %{result | :dst_start => new_start})
  end
  defp parse_week(<<?., c::utf8, rest::binary>>, :dst_end, %{:dst_end => dst_end} = result) when c in ?1..?5 do
    new_end = %{dst_end | :week => String.to_integer(<<c::utf8>>)}
    parse_weekday(rest, :dst_end, %{result | :dst_end => new_end})
  end
  defp parse_week(_rest, state, _result), do: {:error, :"invalid_#{state}_week"}

  defp parse_weekday(<<?., c::utf8, rest::binary>>, :dst_start, %{:dst_start => start} = result) when c in ?0..?6 do
    new_start = %{start | :day_of_week => String.to_integer(<<c::utf8>>)}
    parse_time(rest, :dst_start, %{result | :dst_start => new_start})
  end
  defp parse_weekday(<<?., c::utf8, rest::binary>>, :dst_end, %{:dst_end => dst_end} = result) when c in ?0..?6 do
    new_end = %{dst_end | :day_of_week => String.to_integer(<<c::utf8>>)}
    parse_time(rest, :dst_end, %{result | :dst_end => new_end})
  end
  defp parse_weekday(_rest, state, _result), do: {:error, :"invalid_#{state}_weekday"}

  defp parse_time(<<?/, h1::utf8, h2::utf8, ?:, m1::utf8, m2::utf8, ?:, s1::utf8, s2::utf8, rest::binary>>, state, result)
    when h1 in ?0..?9 and h2 in ?0..?9 and m1 in ?0..?9 and m2 in ?0..9 and s1 in ?0..?9 and s2 in ?0..?9 do
      parse_time(<<h1::utf8, h2::utf8>>, <<m1::utf8, m2::utf8>>, <<s1::utf8, s2::utf8>>, rest, state, result)
  end
  defp parse_time(<<?/, h::utf8, ?:, m1::utf8, m2::utf8, ?:, s1::utf8, s2::utf8, rest::binary>>, state, result)
    when h in ?1..?9 and m1 in ?0..?9 and m2 in ?0..9 and s1 in ?0..?9 and s2 in ?0..?9 do
      parse_time(<<h::utf8>>, <<m1::utf8, m2::utf8>>, <<s1::utf8, s2::utf8>>, rest, state, result)
  end
  defp parse_time(_rest, _state, _result), do: {:error, :not_posix}

  defp parse_time(hs, ms, ss, rest, state, result) do
    hour = String.to_integer(hs)
    mins = String.to_integer(ms)
    secs = String.to_integer(ss)
    case {hour, mins, secs} do
      {h,m,s} when h > 0 and h < 25 and m >= 0 and m < 60 and s >= 0 and s < 60 ->
        case state do
          :dst_start ->
            new_start = %{result.dst_start | :time => {h,m,s}}
            parse_posix(rest, :dst_start, %{result | :dst_start => new_start})
          :dst_end   ->
            new_end = %{result.dst_end | :time => {h,m,s}}
            parse_posix(rest, :dst_end, %{result | :dst_end => new_end})
        end
      _ ->
        {:error, :invalid_time, state}
    end
  end

end
