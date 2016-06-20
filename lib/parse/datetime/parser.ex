defmodule Timex.Parse.DateTime.Parser do
  @moduledoc """
  This is the base plugin behavior for all Timex date/time string parsers.
  """
  import Combine.Parsers.Base, only: [eof: 0, map: 2, pipe: 2]

  alias Timex.DateTime
  alias Timex.Timezone
  alias Timex.TimezoneInfo
  alias Timex.Parse.ParseError
  alias Timex.Parse.DateTime.Tokenizers.Directive
  alias Timex.Parse.DateTime.Tokenizers.Default
  alias Timex.Parse.DateTime.Tokenizers.Strftime


  @doc """
  Parses a date/time string using the default parser.

  ## Examples

      iex> use Timex
      ...> {:ok, dt} = #{__MODULE__}.parse("2014-07-29T00:20:41.196Z", "{ISO:Extended:Z}")
      ...> dt.year
      2014
      iex> dt.month
      7
      iex> dt.day
      29
      iex> dt.timezone.full_name
      "UTC"

  """
  @spec parse(binary, binary) :: {:ok, DateTime.t} | {:error, term}
  def parse(date_string, format_string)
    when is_binary(date_string) and is_binary(format_string),
    do: parse(date_string, format_string, Default)
  def parse(_, _),
    do: {:error, :badarg}

  @doc """
  Parses a date/time string using the provided tokenizer. Tokenizers must implement the
  `Timex.Parse.DateTime.Tokenizer` behaviour.

  ## Examples

      iex> use Timex
      ...> {:ok, dt} = #{__MODULE__}.parse("2014-07-29T00:30:41.196-02:00", "{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default)
      ...> dt.year
      2014
      iex> dt.month
      7
      iex> dt.day
      29
      iex> dt.timezone.full_name
      "Etc/GMT+2"

  """
  @spec parse(binary, binary, atom) :: {:ok, DateTime.t} | {:error, term}
  def parse(date_string, format_string, :strftime),
    do: parse(date_string, format_string, Strftime)
  def parse(date_string, format_string, tokenizer)
    when is_binary(date_string) and is_binary(format_string)
    do
      case tokenizer.tokenize(format_string) do
        {:error, err}     -> {:error, {:format, err}}
        {:ok, []}         -> {:error, "There were no parsing directives in the provided format string."}
        {:ok, directives} ->
          case date_string do
            ""  -> {:error, "Input datetime string cannot be empty."}
            _   -> do_parse(date_string, directives, tokenizer)
          end
      end
  end
  def parse(_, _, _), do: {:error, :badarg}

  @doc """
  Same as `parse/2` and `parse/3`, but raises on error.
  """
  @spec parse!(String.t, String.t, atom | nil) :: DateTime.t | no_return
  def parse!(date_string, format_string, tokenizer \\ Default)
    when is_binary(date_string) and is_binary(format_string) and is_atom(tokenizer)
    do
      case parse(date_string, format_string, tokenizer) do
        {:ok, result}    -> result
        {:error, reason} -> raise ParseError, message: reason
      end
  end

  # Special case iso8601/rfc3339 for performance
  defp do_parse(str, [%Directive{:type => type}], _tokenizer)
    when type in [:iso_8601, :iso_8601z, :iso_8601_extended, :iso_8601_extended_z, :rfc_3339, :rfc_3339z] do
    case Combine.parse(str, Timex.Parse.DateTime.Parsers.ISO8601Extended.parse) do
      {:error, _} = err -> err
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:zname, tzname}]] ->
        dt = %DateTime{:year => y, :month => m, :day => d, :hour => h}
        tz = Timezone.get(tzname, dt)
        {:ok, %{dt | :timezone => tz}}
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:min, mm}, {:zname, tzname}]] ->
        dt = %DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => mm}
        tz = Timezone.get(tzname, dt)
        {:ok, %{dt | :timezone => tz}}
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:min, mm}, {:sec, s}, {:zname, tzname}]] ->
        dt = %DateTime{
          :year => y, :month => m, :day => d,
          :hour => h, :minute => mm, :second => s
        }
        tz = Timezone.get(tzname, dt)
        {:ok, %{dt | :timezone => tz}}
      [[{:year4, y}, {:month, m}, {:day, d}, {:hour24, h}, {:min, mm}, {:sec, s}, {:sec_fractional, ms}, {:zname, tzname}]] ->
        dt = %DateTime{
          :year => y, :month => m, :day => d,
          :hour => h, :minute => mm, :second => s,
          :millisecond => ms
        }
        tz = Timezone.get(tzname, dt)
        {:ok, %{dt | :timezone => tz}}
    end
  end
  defp do_parse(str, directives, tokenizer) do
    parsers = directives
              |> Stream.map(fn %Directive{weight: weight, parser: parser} -> map(parser, &({&1, weight})) end)
              |> Stream.filter(fn nil -> false; _ -> true end)
              |> Enum.reverse
    case Combine.parse(str, pipe([eof()|parsers] |> Enum.reverse, &(&1))) do
      [results] when is_list(results) ->
        results
        |> extract_parse_results
        |> Stream.with_index
        |> Enum.sort_by(fn
            # If :force_utc exists, make sure it is applied last
            {{{:force_utc, true}, _}, _} -> 9999
            # Timezones must always be applied after other date/time tokens ->
            {{{tz, _}, _}, _} when tz in [:zname, :zoffs, :zoffs_colon, :zoffs_sec] -> 9998
            # If no weight is set, use the index as its weight
            {{{_token, _value}, 0}, i} -> i
            # Use the directive weight
            {{{_token, _value}, weight}, _} -> weight
          end)
        |> Stream.flat_map(fn {{token, _}, _} -> [token] end)
        |> Enum.filter(&Kernel.is_tuple/1)
        |> apply_directives(tokenizer)
      {:error, _} = err -> err
    end
  end
  defp extract_parse_results(parse_results), do: extract_parse_results(parse_results, [])
  defp extract_parse_results([], acc), do: Enum.reverse(acc)
  defp extract_parse_results([{tokens, _}|rest], acc) when is_list(tokens) do
    extracted = Enum.reverse(extract_parse_results(tokens))
    extract_parse_results(rest, extracted ++ acc)
  end
  defp extract_parse_results([{{token, value}, weight}|rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, weight}|acc])
  end
  defp extract_parse_results([{token, value}|rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, 0}|acc])
  end
  defp extract_parse_results([[{token, value}]|rest], acc) when is_atom(token) do
    extract_parse_results(rest, [{{token, value}, 0}|acc])
  end
  defp extract_parse_results([h|rest], acc) when is_list(h) do
    extracted = Enum.reverse(extract_parse_results(h))
    extract_parse_results(rest, extracted ++ acc)
  end
  defp extract_parse_results([_|rest], acc) do
    extract_parse_results(rest, acc)
  end

  # Constructs a DateTime from the parsed tokens
  defp apply_directives([], _),             do: {:ok, %DateTime{}}
  defp apply_directives(tokens, tokenizer), do: apply_directives(tokens, %DateTime{}, tokenizer)
  defp apply_directives([], %DateTime{timezone: nil} = date, tokenizer) do
    apply_directives([], %{date | :timezone => %TimezoneInfo{}}, tokenizer)
  end
  defp apply_directives([], %DateTime{} = date, _), do: {:ok, date}
  defp apply_directives([{token, value}|tokens], %DateTime{} = date, tokenizer) do
    case update_date(date, token, value, tokenizer) do
      {:error, _} = error -> error
      updated             -> apply_directives(tokens, updated, tokenizer)
    end
  end

  # Given a date, a token, and the value for that token, update the
  # date according to the rules for that token and the provided value
  defp update_date(%DateTime{year: year, hour: hh} = date, token, value, tokenizer) when is_atom(token) do
    case token do
      # Formats
      clock when clock in [:kitchen, :strftime_iso_kitchen] ->
        case apply_directives(value, DateTime.now, tokenizer) do
          {:error, _} = err -> err
          {:ok, date} when clock == :kitchen -> %{date | :second => 0, :millisecond => 0}
          {:ok, date} -> %{date | :millisecond => 0}
        end
      # Years
      :century   ->
        century = Timex.century(%{date | :year => year})
        year_shifted = year + ((value - century) * 100)
        %{date | :year => year_shifted}
      y when y in [:year2, :iso_year2] ->
        current_century = Timex.century(DateTime.now)
        year_shifted    = value + ((current_century - 1) * 100)
        %{date | :year => year_shifted}
      y when y in [:year4, :iso_year4] ->
        # Special case for UNIX format dates, where the year is parsed after the timezone,
        # so we must lookup the timezone again to ensure it's properly set
        case date do
          %DateTime{timezone: %Timex.TimezoneInfo{:full_name => tzname}} ->
            zone_date = Timex.to_erlang_datetime(%{date | :year => value})
            %{date | :year => value, :timezone => Timezone.get(tzname, zone_date)}
          %DateTime{timezone: nil} ->
            %{date | :year => value}
        end
      # Months
      :month  -> %{date | :month => value}
      month when month in [:mshort, :mfull] ->
        %{date | :month => Timex.month_to_num(value)}
      # Days
      :day      -> %{date | :day => value}
      :oday when is_integer(value) and value >= 0 ->
        Timex.from_iso_day(value, date)
      :wday_mon ->
        current_day = Timex.weekday(date)
        cond do
          current_day == value -> date
          current_day > value  -> Timex.shift(date, days: current_day - value)
          current_day < value  -> Timex.shift(date, days: value - current_day)
        end
      :wday_sun ->
        current_day = Timex.weekday(date) - 1
        cond do
          current_day == value -> date
          current_day > value -> Timex.shift(date, days: current_day - value)
          current_day < value -> Timex.shift(date, days: value - current_day)
        end
      day when day in [:wdshort, :wdfull] ->
        %{date | :day => Timex.day_to_num(value)}
      # Weeks
      :iso_weeknum ->
        {year, _, weekday} = Timex.iso_triplet(date)
        %DateTime{year: y, month: m, day: d} = Timex.from_iso_triplet({year, value, weekday})
        %{date | :year => y, :month => m, :day => d}
      week_num when week_num in [:week_mon, :week_sun] ->
        reset = %{date | :month => 1, :day => 1}
        reset |> Timex.shift(weeks: value)
      # Hours
      hour when hour in [:hour24, :hour12] ->
        %{date | :hour => value}
      :min       -> %{date | :minute => value}
      :sec       -> %{date | :second => value}
      :sec_fractional ->
        case value do
          "" -> date
          n when is_number(n) -> %{date | :millisecond => n}
        end
      :us -> %{date | :millisecond => div(value, 1000)}
      :ms -> %{date | :millisecond => value}
      :sec_epoch -> DateTime.from_seconds(value, :epoch)
      am_pm when am_pm in [:am, :AM] ->
        cond do
          hh == 24 ->
            %{date | :hour => 0}
          hh == 12 and (String.downcase(value) == "am") ->
            %{date | :hour => 0}
          hh in (1..11) and String.downcase(value) == "pm" ->
            %{date | :hour => hh + 12} 
          true ->
            date
        end
      # Timezones
      :zoffs ->
        zone_date = Timex.to_erlang_datetime(date)
        %{date | :timezone => Timezone.get(value, zone_date)}
      :zname ->
        zone_date = Timex.to_erlang_datetime(date)
        %{date | :timezone => Timezone.get(value, zone_date)}
      tz when tz in [:zoffs_colon, :zoffs_sec] ->
        case value do
          <<?-, h1::utf8, h2::utf8, _::binary>> ->
            zone_date = Timex.to_erlang_datetime(date)
            %{date | :timezone => Timezone.get(<<?-, h1::utf8, h2::utf8>>, zone_date)}
          <<?+, h1::utf8, h2::utf8, _::binary>> ->
            zone_date = Timex.to_erlang_datetime(date)
            %{date | :timezone => Timezone.get(<<?+, h1::utf8, h2::utf8>>, zone_date)}
          _ ->
            {:error, "#{token} not implemented"}
        end
      :force_utc ->
        case date do
          %DateTime{timezone: nil} -> %{date | :timezone => %Timex.TimezoneInfo{}}
          _   -> Timezone.convert(date, "UTC")
        end
      :literal -> date
      _ ->
        case tokenizer.apply(date, token, value) do
          {:ok, date}       -> date
          {:error, _} = err -> err
          _ ->
            {:error, "Unrecognized token: #{token}"}
        end
    end
  end

end
