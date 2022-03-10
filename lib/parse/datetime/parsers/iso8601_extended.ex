defmodule Timex.Parse.DateTime.Parsers.ISO8601Extended do
  use Combine.Helpers
  alias Combine.ParserState

  defparser parse(%ParserState{status: :ok, column: col, input: input, results: results} = state) do
    case parse_extended(input) do
      {:ok, parts, len, remaining} ->
        %{
          state
          | :column => col + len,
            :input => remaining,
            :results => [Enum.reverse(parts) | results]
        }

      {:error, reason, count} ->
        %{state | :status => :error, :column => col + count, :error => reason}
    end
  end

  def parse_extended(<<>>), do: {:error, "Expected year, but got end of input."}
  def parse_extended(input), do: parse_extended(input, :year, [], 0)

  def parse_extended(
        <<y1::utf8, y2::utf8, y3::utf8, y4::utf8, "-", rest::binary>>,
        :year,
        acc,
        count
      )
      when y1 >= ?0 and y1 <= ?9 and
             y2 >= ?0 and y2 <= ?9 and
             y3 >= ?0 and y3 <= ?9 and
             y4 >= ?0 and y4 <= ?9 do
    year = String.to_integer(<<y1::utf8, y2::utf8, y3::utf8, y4::utf8>>)
    parse_extended(rest, :month, [{:year4, year} | acc], count + 4)
  end

  def parse_extended(<<h::utf8, _::binary>>, :year, _acc, count),
    do: {:error, "Expected 4 digit year, but got `#{<<h::utf8>>}` instead.", count}

  def parse_extended(_, :year, _acc, count),
    do: {:error, "Expected 4 digit year.", count}

  def parse_extended(<<m1::utf8, m2::utf8, "-", rest::binary>>, :month, acc, count)
      when m1 >= ?0 and m1 < ?2 and
             m2 >= ?0 and m2 <= ?9 do
    month = String.to_integer(<<m1::utf8, m2::utf8>>)

    cond do
      month > 0 and month < 13 ->
        parse_extended(rest, :day, [{:month, month} | acc], count + 2)

      :else ->
        {:error, "Expected month between 1-12, but got `#{month}` instead.", count}
    end
  end

  def parse_extended(<<h::utf8, _::binary>>, :month, _acc, count),
    do: {:error, "Expected 2 digit month, but got `#{<<h::utf8>>}` instead.", count}

  def parse_extended(_, :month, _acc, count),
    do: {:error, "Expected 2 digit month.", count}

  def parse_extended(<<d1::utf8, d2::utf8, sep::utf8, rest::binary>>, :day, acc, count)
      when d1 >= ?0 and d1 <= ?3 and
             d2 >= ?0 and d2 <= ?9 do
    cond do
      sep in [?T, ?\s] ->
        day = String.to_integer(<<d1::utf8, d2::utf8>>)

        cond do
          day > 0 and day < 32 ->
            parse_extended(rest, :hour, [{:day, day} | acc], count + 3)

          :else ->
            {:error, "Expected day between 1-31, but got `#{day}` instead.", count}
        end

      :else ->
        {:error,
         "Expected valid date/time separator (T or space), but got `#{<<sep::utf8>>}` instead.",
         count + 2}
    end
  end

  def parse_extended(<<h::utf8, _::binary>>, :day, _acc, count),
    do: {:error, "Expected 2 digit day, but got `#{<<h::utf8>>}` instead.", count}

  def parse_extended(_, :day, _acc, count),
    do: {:error, "Expected 2 digit day.", count}

  def parse_extended(<<h1::utf8, h2::utf8, rest::binary>>, :hour, acc, count)
      when h1 >= ?0 and h1 < ?3 and
             h2 >= ?0 and h2 <= ?9 do
    hour = String.to_integer(<<h1::utf8, h2::utf8>>)

    cond do
      hour >= 0 and hour <= 24 ->
        case rest do
          <<":", rest::binary>> ->
            parse_extended(rest, :minute, [{:hour24, hour} | acc], count + 3)

          _ ->
            parse_offset(rest, [{:hour24, hour} | acc], count + 2)
        end

      :else ->
        {:error, "Expected hour between 0-24, but got `#{hour}` instead.", count}
    end
  end

  def parse_extended(<<h::utf8, _::binary>>, :hour, _acc, count),
    do: {:error, "Expected 2 digit hour, but got `#{<<h::utf8>>}` instead.", count}

  def parse_extended(_, :hour, _acc, count),
    do: {:error, "Expected 2 digit hour.", count}

  # Minutes are optional
  def parse_extended(<<m1::utf8, m2::utf8, rest::binary>>, :minute, acc, count)
      when m1 >= ?0 and m1 < ?6 and
             m2 >= ?0 and m2 <= ?9 do
    minute = String.to_integer(<<m1::utf8, m2::utf8>>)

    cond do
      minute >= 0 and minute <= 60 ->
        case rest do
          <<":", rest::binary>> ->
            parse_extended(rest, :second, [{:min, minute} | acc], count + 3)

          _ ->
            parse_offset(rest, [{:min, minute} | acc], count + 2)
        end

      :else ->
        {:error, "Expected minute between 0-60, but got `#{minute}` instead.", count}
    end
  end

  def parse_extended(<<m1::utf8, _::binary>>, :minute, _acc, count),
    do: {:error, "Expected 2 digit minute, but got `#{<<m1::utf8>>}` instead.", count}

  def parse_extended(_, :minute, _acc, count),
    do: {:error, "Expected 2 digit minute.", count}

  # Seconds are optional
  # Has fractional seconds
  def parse_extended(<<s1::utf8, s2::utf8, ".", rest::binary>>, :second, acc, count)
      when s1 >= ?0 and s1 < ?6 and
             s2 >= ?0 and s2 <= ?9 do
    case parse_fractional_seconds(rest, count, <<>>) do
      {:ok, fraction, count, rest} ->
        seconds = String.to_integer(<<s1::utf8, s2::utf8>>)
        precision = byte_size(fraction)
        fraction = if precision > 6, do: binary_part(fraction, 0, 6), else: fraction
        precision = if precision > 6, do: 6, else: precision
        fractional = String.to_integer(fraction)
        fractional = fractional * div(1_000_000, trunc(:math.pow(10, precision)))

        cond do
          seconds >= 0 and seconds <= 60 ->
            parse_offset(
              rest,
              [{:sec_fractional, {fractional, precision}}, {:sec, seconds} | acc],
              count + 2
            )

          :else ->
            {:error, "Expected second between 0-60, but got `#{seconds}` instead.", count}
        end

      {:error, _reason, _count} = err ->
        err
    end
  end

  # No fractional seconds
  def parse_extended(<<s1::utf8, s2::utf8, rest::binary>>, :second, acc, count)
      when s1 >= ?0 and s1 < ?6 and
             s2 >= ?0 and s2 <= ?9 do
    second = String.to_integer(<<s1::utf8, s2::utf8>>)

    cond do
      second >= 0 and second <= 60 ->
        parse_offset(rest, [{:sec, second} | acc], count + 2)

      :else ->
        {:error, "Expected second between 0-60, but got `#{second}` instead.", count}
    end
  end

  def parse_extended(<<h::utf8, _::binary>>, :second, _acc, count),
    do: {:error, "Expected valid value for seconds, but got `#{<<h::utf8>>}` instead.", count}

  def parse_extended(_, :second, _acc, count),
    do: {:error, "Expected valid value for seconds.", count}

  def parse_fractional_seconds(<<digit::utf8, rest::binary>>, count, acc)
      when digit >= ?0 and digit <= ?9 do
    parse_fractional_seconds(rest, count + 1, <<acc::binary, digit::utf8>>)
  end

  def parse_fractional_seconds(_rest, count, "") do
    {:error, "Expected at least one digit after the decimal sign, but found none", count}
  end

  def parse_fractional_seconds(rest, count, acc) do
    {:ok, acc, count, rest}
  end

  def parse_offset(<<"Z", rest::binary>>, acc, count),
    do: {:ok, [{:zname, "Etc/UTC"} | acc], count + 1, rest}

  def parse_offset(<<dir::utf8, rest::binary>>, acc, count) when dir in [?+, ?-] do
    parse_offset(dir, rest, acc, count + 1)
  end

  def parse_offset("", acc, count), do: {:ok, acc, count, ""}

  def parse_offset(str, _acc, count),
    do: {:error, "Expected either Z or a valid timezone offset, but got `#{str}`", count}

  # +/-HH:MM:SS (seconds are currently unhandled in offsets)
  def parse_offset(
        dir,
        <<h1::utf8, h2::utf8, ":", m1::utf8, m2::utf8, ":", s1::utf8, s2::utf8, rest::binary>>,
        acc,
        count
      )
      when h1 >= ?0 and h1 < ?2 and
             h2 >= ?0 and h2 <= ?9 and
             m1 >= ?0 and m1 < ?6 and
             m2 >= ?0 and m2 <= ?9 and
             s1 >= ?0 and s1 < ?6 and
             s2 >= ?0 and s2 <= ?9 do
    {:ok, [{:zname, <<dir::utf8, h1::utf8, h2::utf8, ":", m1::utf8, m2::utf8>>} | acc], count + 7,
     rest}
  end

  # +/-HH:MM
  def parse_offset(dir, <<h1::utf8, h2::utf8, ":", m1::utf8, m2::utf8, rest::binary>>, acc, count)
      when h1 >= ?0 and h1 < ?2 and
             h2 >= ?0 and h2 <= ?9 and
             m1 >= ?0 and m1 < ?6 and
             m2 >= ?0 and m2 <= ?9 do
    {:ok, [{:zname, <<dir::utf8, h1::utf8, h2::utf8, ":", m1::utf8, m2::utf8>>} | acc], count + 5,
     rest}
  end

  # +/-HHMM
  def parse_offset(dir, <<h1::utf8, h2::utf8, m1::utf8, m2::utf8, rest::binary>>, acc, count)
      when h1 >= ?0 and h1 < ?2 and
             h2 >= ?0 and h2 <= ?9 and
             m1 >= ?0 and m1 < ?6 and
             m2 >= ?0 and m2 <= ?9 do
    {:ok, [{:zname, <<dir::utf8, h1::utf8, h2::utf8, ":", m1::utf8, m2::utf8>>} | acc], count + 5,
     rest}
  end

  # +/-HH
  def parse_offset(dir, <<h1::utf8, h2::utf8, rest::binary>>, acc, count)
      when h1 >= ?0 and h1 < ?2 and
             h2 >= ?0 and h2 <= ?9 do
    {:ok, [{:zname, <<dir::utf8, h1::utf8, h2::utf8, ":00">>} | acc], count + 2, rest}
  end

  def parse_offset(_, <<h::utf8, _rest::binary>>, _acc, count),
    do: {:error, "Expected valid offset, but got `#{<<h::utf8>>}` instead.", count}
end
