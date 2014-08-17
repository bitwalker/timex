defmodule Timex.Parsers.DateFormat.Parser do
  @moduledoc """
  This is the base plugin behavior for all Timex date/time string parsers.
  """
  use Behaviour

  alias Timex.Date
  alias Timex.Time
  alias Timex.DateTime
  alias Timex.Timezone
  alias Timex.Parsers.ParseError
  alias Timex.Parsers.DateFormat.Directive

  defcallback tokenize(format_string :: binary) :: [%Directive{}] | {:error, term}
  defcallback parse_directive(date::binary, directive::%Directive{}) :: {token::atom, {value::term, date_rest::binary} | {:error, term}}

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Timex.Parsers.DateFormat.Parser

      import Timex.Parsers.DateFormat.Parser

        @whitespace    [32, ?\t, ?\n, ?\r]
        @numerics      ?0..?9 |> Enum.to_list
        @lower_alpha   ?a..?z |> Enum.to_list
        @upper_alpha   ?A..?Z |> Enum.to_list
        @alpha_chars   @lower_alpha ++ @upper_alpha
        @word_chars    @alpha_chars ++ [?:, ?+, ?-]
        @allowed_chars @word_chars ++ @numerics
        @invalid_input "Input string does not match format!"
    end
  end

  @doc """
  Parses a date/time string using the default parser.

  ## Examples

    iex> #{__MODULE__}.parse("2014-07-29T00:20:41.196Z", "{ISOz}")
    %Date{year: 2014, month: 7, day: 29, hour: 0, minute: 20, second: 41, ms: 196, tz: %Timezone{name: "CST"}}

  """
  @spec parse(binary, binary) :: {:ok, %DateTime{}} | {:error, term}
  def parse(date_string, format_string)
    when is_binary(date_string) and is_binary(format_string),
    do: parse(date_string, format_string, Timex.Parsers.DateFormat.DefaultParser)

  @doc """
  Parses a date/time string using the provided parser. Must implement the
  `Timex.Parsers.Parser` behaviour.

  ## Examples

    iex> #{__MODULE__}.parse("2014-07-29T00:30:41.196Z", "{ISOz}", Timex.Parsers.DefaultParser)
    %Date{year: 2014, month: 7, day: 29, hour: 0, minute: 20, second: 41, ms: 196, tz: %Timezone{name: "CST"}}

  """
  @spec parse(binary, binary, Timex.Parsers.DateFormat.Parser) :: {:ok, %DateTime{}} | {:error, term}
  def parse(date_string, format_string, parser)
    when is_binary(date_string) and is_binary(format_string)
    do
      case parser.tokenize(format_string) do
        {:error, reason} -> {:error, reason}
        directives ->
          case date_string do
            nil -> {:error, "Input string cannot be null"}
            ""  -> {:error, "Input string cannot be empty"}
            _   -> 
              if Enum.any?(directives, fn dir -> dir.type != :char end) do
                do_parse(date_string, directives, parser)
              else
                {:error, "There were no parsing directives in the provided string."}
              end
          end
      end
  end

  @doc """
  Same as `parse/2` and `parse/3`, but raises on error.
  """
  @spec parse!(String.t, String.t, Timex.Parsers.DateFormat.Parser | nil) :: %DateTime{} | no_return
  def parse!(date_string, format_string, parser \\ Timex.Parsers.DateFormat.DefaultParser)
    when is_binary(date_string) and is_binary(format_string)
    do
      case parse(date_string, format_string, parser) do
        {:ok, result}    -> result
        {:error, reason} -> raise ParseError, message: reason
      end
  end

  defp do_parse(date_string, directives, parser), do: do_parse(date_string, directives, parser, %DateTime{})
  defp do_parse(<<>>, [], _, %DateTime{timezone: nil} = date), do: {:ok, %{date | :timezone => Timezone.get(:utc)}}
  defp do_parse(<<>>, [], _, %DateTime{} = date),              do: {:ok, date}
  defp do_parse(rest, [], _, _),                  do: {:error, "Unexpected end of string! Starts at: #{rest}"}
  # Ignore :char directives when parsing
  defp do_parse(<<_::utf8, date_string::binary>>, [%Directive{type: :char}|rest], parser, date) do
    do_parse(date_string, rest, parser, date)
  end
  # Inject component directives of pre-formatted directives.
  defp do_parse(date_string, [%Directive{token: token, type: :format, format: format}|rest], parser, %DateTime{} = date) do
    case format do
      [tokenizer: tokenizer, format: format_string] ->
        # When parsing a date string with one of the zulu directives,
        # shift the date to UTC/Zulu
        date = case token do
          token when token in [:iso_8601z, :rfc_822z, :rfc3339z, :rfc_1123z] ->
            Date.set(date, timezone: Timezone.get(:utc))
          _ ->
            date
        end
        # Tokenize the nested directives and continue parsing
        case tokenizer.tokenize(format_string) do
          {:error, _} = error -> error
          directives ->
            do_parse(date_string, directives ++ rest, parser, date)
        end
      {:error, _} = error ->
        error
    end
  end
  defp do_parse(date_string, [%Directive{} = directive|rest], parser, %DateTime{} = date) do
    case parse_directive(date_string, directive, parser, date) do
      {:error, _} = error -> error
      {date_string, date} -> do_parse(date_string, rest, parser, date)
    end
  end
  defp do_parse(_date_string, [directive|_rest], _parser, %DateTime{} = _date) do
    {:error, "#{directive} not implemented"}
  end

  defp parse_directive(date_string, %Directive{} = directive, parser, %DateTime{} = date) do
    case parser.parse_directive(date_string, directive) do
      {_, {:error, reason}} ->
        {:error, reason}
      {token, {value, date_string}} ->
        case update_date(date, token, value) do
          {:error, _} = error -> error
          date                -> {date_string, date}
        end
      result ->
        {:error, "Invalid return value from parse_directive: #{result |> Macro.to_string}"}
    end
  end

  @doc """
  Given a string value (as a charlist), a token name, and a length specification,
  return a boolean indicating the validity of the string length of the provided value.

  ## Example

    valid_length?('Mar', :mshort, 3..4) #=> true

  """
  def valid_length?({:error, _} = error, _, _),
    do: error
  def valid_length?(str, _, :word)
    when is_list(str) and length(str) > 0,
    do: str
  def valid_length?(str, _, len)
    when is_list(str) and length(str) == len,
    do: str
  def valid_length?(str, _, lo..hi)
    when is_list(str) and length(str) >= lo and length(str) <= hi,
    do: str
  def valid_length?(_, token, len),
    do: {:error, "Invalid value for #{token}. Does not meet expected length requirements: #{len |> Macro.to_string}"}

  @doc """
  Validates the value against a validator, the validator can
  be false, an atom representing a Date.* function to be called,
  a function taking a single string parameter, or a regex.

  ## Example

    valid_value?('+0200', :zname, ~r/^[-+]\d{4}$/) #=> true

  """
  def valid_value?(str, token, validator)
    when is_list(str),
    do: valid_value?(str |> List.to_string, token, validator)
  def valid_value?({:error, _} = error, _, _),
    do: error
  def valid_value?(str, _token, false),
    do: str
  def valid_value?(str, _token, match: str),
    do: str
  def valid_value?(str, token, match: matches) when is_list(matches) do
    if Enum.member?(matches, str) do
      str
    else
      {:error, "Invalid value for #{token}. No match found in #{matches |> Macro.to_string}"}
    end
  end
  def valid_value?(str, _token, match: false),
    do: str
  def valid_value?(str, token, validator) when is_atom(validator) do
    case apply(Timex.Date, validator, [str]) do
      true  -> str
      false -> {:error, "Invalid value for #{token}. Does not match specification for #{validator}"}
      _     -> str
    end
  end
  def valid_value?(str, token, validator) when is_function(validator) do
    case validator.(str) do
      true  -> str
      false -> {:error, "Invalid value for #{token}. Does not match specification for #{validator |> Macro.to_string}"}
      _     -> str
    end
  end
  def valid_value?(str, token, %Regex{} = validator) do
    case validator |> Regex.match?(str) do
      true -> str
      _  ->
        {:error, "Invalid value for #{token}. Does not match specification for #{validator |> Macro.to_string}"}
    end
  end
  def valid_value?(_, token, validator) do
    {:error, "Invalid value for #{token}. Does not match specification for #{validator}"}
  end

  @doc """
  Validate that a numeric value is within the valid range, if
  applicable. If not return an appropriate error.

  ## Example

    within_bounds?("61", :min, 0, 59) #=> false

  """
  def within_bounds?(str, token, min, max) when is_list(str) do
    str |> List.to_string |> within_bounds?(token, min, max)
  end
  def within_bounds?(str, token, min, max) when is_binary(str) do
    num = case Integer.parse(str) do
      :error   -> {:error, "Invalid numeric value for #{token}: #{str}"}
      {num, _} -> num
    end
    within_bounds?(num, token, min, max)
  end
  def within_bounds?({:error, _} = error, _, _, _), do: error
  def within_bounds?(num, _token, false, max)   when is_number(num) and num <= max, do: num
  def within_bounds?(num, _token, min, false)   when is_number(num) and num >= min, do: num
  def within_bounds?(num, _token, false, false) when is_number(num),                do: num
  def within_bounds?(num, _token, min, max) when is_number(num) and num >= min and num <= max, do: num
  def within_bounds?(num, token, min, max) when is_number(num) do
    {:error, "Invalid numeric value `#{num}` for #{token}. Outside of the allowed bounds: #{min}..#{max}"}
  end

  # Given a date, a token, and the value for that token, update the
  # date according to the rules for that token and the provided value
  defp update_date(%DateTime{year: year} = date, token, value) when is_atom(token) do
    case token do
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
        %{date | :year => value}
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
        # If timezone is not nil, then we know it was set
        # by a preformatted directive, so do not overrule that value
        case date.timezone do
          nil -> %{date | :timezone => Timezone.get(value)}
          _   -> date
        end
      :zname ->
        # If timezone is not nil, then we know it was set
        # by a preformatted directive, so do not overrule that value
        case date.timezone do
          nil -> %{date | :timezone => Timezone.get(value)}
          _   -> date
        end
      tz when tz in [:zoffs_colon, :zoffs_sec] ->
        case value do
          <<?-, h1::utf8, h2::utf8, _::binary>> ->
            %{date | :timezone => Timezone.get(<<?-, h1::utf8, h2::utf8>>)}
          <<?+, h1::utf8, h2::utf8, _::binary>> ->
            %{date | :timezone => Timezone.get(<<?+, h1::utf8, h2::utf8>>)}
          _ ->
            {:error, "#{token} not implemented"}
        end
    end
  end

end