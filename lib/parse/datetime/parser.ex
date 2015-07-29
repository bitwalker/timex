defmodule Timex.Parse.DateTime.Parser do
  @moduledoc """
  This is the base plugin behavior for all Timex date/time string parsers.
  """
  use Behaviour
  import Combine.Parsers.Base, only: [eof: 0, sequence: 1]

  alias Timex.Date
  alias Timex.Time
  alias Timex.DateTime
  alias Timex.TimezoneInfo
  alias Timex.Timezone
  alias Timex.Parse.ParseError
  alias Timex.Parse.DateTime.Tokenizers.Directive
  alias Timex.Parse.DateTime.Tokenizers.Default, as: DefaultTokenizer

  @doc """
  Parses a date/time string using the default parser.

  ## Examples

      iex> #{__MODULE__}.parse("2014-07-29T00:20:41.196Z", "{ISOz}")
      %DateTime{year: 2014, month: 7, day: 29, hour: 0, minute: 20, second: 41, ms: 196, tz: %Timezone{name: "CST"}}

  """
  @spec parse(binary, binary) :: {:ok, %DateTime{}} | {:error, term}
  def parse(date_string, format_string)
    when is_binary(date_string) and is_binary(format_string),
    do: parse(date_string, format_string, DefaultTokenizer)

  @doc """
  Parses a date/time string using the provided parser. Must implement the
  `Timex.Parsers.Parser` behaviour.

  ## Examples

    iex> #{__MODULE__}.parse("2014-07-29T00:30:41.196Z", "{ISOz}", Timex.Parse.DateTime.Tokenizers.Default)
    %Date{year: 2014, month: 7, day: 29, hour: 0, minute: 20, second: 41, ms: 196, tz: %Timezone{name: "CST"}}

  """
  @spec parse(binary, binary, atom) :: {:ok, %DateTime{}} | {:error, term}
  def parse(date_string, format_string, tokenizer)
    when is_binary(date_string) and is_binary(format_string)
    do
      case tokenizer.tokenize(format_string) do
        {:error, err}     -> {:error, {:format, err}}
        {:ok, []}         -> {:error, "There were no parsing directives in the provided format string."}
        {:ok, directives} ->
          case date_string do
            ""  -> {:error, "Input datetime string cannot be empty."}
            _   -> do_parse(date_string, directives)
          end
      end
  end

  @doc """
  Same as `parse/2` and `parse/3`, but raises on error.
  """
  @spec parse!(String.t, String.t, atom | nil) :: %DateTime{} | no_return
  def parse!(date_string, format_string, tokenizer \\ DefaultTokenizer)
    when is_binary(date_string) and is_binary(format_string) and is_atom(tokenizer)
    do
      case parse(date_string, format_string, tokenizer) do
        {:ok, result}    -> result
        {:error, reason} -> raise ParseError, message: reason
      end
  end

  defp do_parse(str, directives) do
    parsers = directives
              |> Stream.map(fn %Directive{parser: parser} -> parser end)
              |> Stream.filter(fn nil -> false; _ -> true end)
              |> Enum.reverse
    case Combine.parse(str, sequence([eof|parsers] |> Enum.reverse)) do
      results when is_list(results) ->
        results
        |> List.flatten
        |> Enum.filter(&Kernel.is_tuple/1)
        |> apply_directives
      {:error, _} = err -> err
    end
  end

  # Constructs a DateTime from the parsed tokens
  defp apply_directives([]), do: {:ok, %DateTime{}}
  defp apply_directives(tokens) do
    # If :force_utc exists, make sure it is applied last
    sorted = tokens
      |> Enum.with_index
      |> Enum.sort_by(fn
           {{:force_utc, _}, _} -> 9999
           {{_,_}, i} -> i
         end)
      |> Enum.map(fn {token, _} -> token end)
    apply_directives(sorted, %DateTime{})
  end
  defp apply_directives([], %DateTime{timezone: nil} = date) do
    apply_directives([], %{date | :timezone => %TimezoneInfo{}})
  end
  defp apply_directives([], %DateTime{} = date), do: {:ok, date}
  defp apply_directives([{token, value}|tokens], %DateTime{} = date) do
    case update_date(date, token, value) do
      {:error, _} = error -> error
      updated             -> apply_directives(tokens, updated)
    end
  end

  # Given a date, a token, and the value for that token, update the
  # date according to the rules for that token and the provided value
  defp update_date(%DateTime{year: year} = date, token, value) when is_atom(token) do
    case token do
      # Formats
      clock when clock in [:kitchen, :strftime_iso_kitchen] ->
        case apply_directives(value, Date.now) do
          {:error, _} = err -> err
          {:ok, date} when clock == :kitchen -> %{date | :second => 0, :ms => 0}
          {:ok, date} -> %{date | :ms => 0}
        end
      # Years
      :century   ->
        century = Date.century(%{date | :year => year})
        year_shifted = year + ((value - century) * 100)
        %{date | :year => year_shifted}
      y when y in [:year2, :iso_year2] ->
        current_century = Date.century(Date.now)
        year_shifted    = value + ((current_century - 1) * 100)
        %{date | :year => year_shifted}
      y when y in [:year4, :iso_year4] ->
        # Special case for UNIX format dates, where the year is parsed after the timezone,
        # so we must lookup the timezone again to ensure it's properly set
        case date.timezone do
          %Timex.TimezoneInfo{:full_name => tzname} ->
            zone_date = {{value, date.month, date.day}, {date.hour, date.minute, date.second}}
            %{date | :year => value, :timezone => Timezone.get(tzname, zone_date)}
          nil ->
            %{date | :year => value}
        end
      # Months
      :month  -> %{date | :month => value}
      month when month in [:mshort, :mfull] ->
        %{date | :month => Date.month_to_num(value)}
      # Days
      :day      -> %{date | :day => value}
      :oday     -> Date.from_iso_day(value, date)
      :wday_mon ->
        current_day = Date.weekday(date)
        cond do
          current_day == value -> date
          current_day > value  -> Date.shift(date, days: current_day - value)
          current_day < value  -> Date.shift(date, days: value - current_day)
        end
      :wday_sun ->
        current_day = Date.weekday(date) - 1
        cond do
          current_day == value -> date
          current_day > value -> Date.shift(date, days: current_day - value)
          current_day < value -> Date.shift(date, days: value - current_day)
        end
      day when day in [:wdshort, :wdfull] ->
        %{date | :day => Date.day_to_num(value)}
      # Weeks
      :iso_weeknum ->
        {year, _, weekday} = Date.iso_triplet(date)
        converted = Date.from_iso_triplet({year, value, weekday})
        %{date | :year => converted.year, :month => converted.month, :day => converted.day}
      week_num when week_num in [:week_mon, :week_sun] ->
        reset = %{date | :month => 1, :day => 1}
        reset |> Date.shift(weeks: value)
      # Hours
      hour when hour in [:hour24, :hour12] ->
        %{date | :hour => value}
      :min       -> %{date | :minute => value}
      :sec       -> %{date | :second => value}
      :sec_fractional ->
        case value do
          "" -> date
          n when is_number(n) -> %{date | :ms => n}
        end
      :sec_epoch -> Date.from(value, :secs, :epoch)
      am_pm when am_pm in [:am, :AM] ->
        {converted, hemisphere} = Time.to_12hour_clock(date.hour)
        case value do
          am when am in ["am", "AM"]->
            %{date | :hour => converted}
          pm when pm in ["pm", "PM"] and hemisphere == :am ->
            %{date | :hour => converted + 12}
          _ ->
            %{date | :hour => converted}
        end
      # Timezones
      :zoffs ->
        zone_date = {{date.year, date.month, date.day}, {date.hour, date.minute, date.second}}
        %{date | :timezone => Timezone.get(value, zone_date)}
      :zname ->
        zone_date = {{date.year, date.month, date.day}, {date.hour, date.minute, date.second}}
        %{date | :timezone => Timezone.get(value, zone_date)}
      tz when tz in [:zoffs_colon, :zoffs_sec] ->
        case value do
          <<?-, h1::utf8, h2::utf8, _::binary>> ->
            zone_date = {{date.year, date.month, date.day}, {date.hour, date.minute, date.second}}
            %{date | :timezone => Timezone.get(<<?-, h1::utf8, h2::utf8>>, zone_date)}
          <<?+, h1::utf8, h2::utf8, _::binary>> ->
            zone_date = {{date.year, date.month, date.day}, {date.hour, date.minute, date.second}}
            %{date | :timezone => Timezone.get(<<?+, h1::utf8, h2::utf8>>, zone_date)}
          _ ->
            {:error, "#{token} not implemented"}
        end
      :force_utc ->
        case date.timezone do
          nil -> %{date | :timezone => %Timex.TimezoneInfo{}}
          _   -> Timezone.convert(date, "UTC")
        end
      :literal -> date
      _ ->
        {:error, "Unknown token: #{token}"}
    end
  end

end
