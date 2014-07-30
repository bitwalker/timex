defmodule Timex.Parsers.DateFormat.Parser do
  @moduledoc """
  This is the base plugin behavior for all Timex date/time string parsers.
  """
  use Behaviour

  alias Timex.Date
  alias Timex.DateTime
  alias Timex.Timezone
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
  @spec parse(binary, binary) :: %DateTime{} | {:error, term}
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
  @spec parse(binary, binary, Timex.Parsers.DateFormat.Parser) :: %DateTime{} | {:error, term}
  def parse(date_string, format_string, parser)
    when is_binary(date_string) and is_binary(format_string)
    do
      cond do
        parsers |> Enum.member?(parser) ->
          case parser.tokenize(format_string) do
            {:error, reason} -> {:error, reason}
            directives ->
              case date_string do
                nil -> {:error, "Input string cannot be null"}
                ""  -> {:error, "Input string cannot be empty"}
                _   -> do_parse(date_string, directives, parser)
              end
          end
        true ->
          {:error, "The parser provided does not implement the `Timex.Parsers.Parser` behaviour!"}
      end
  end

  defp do_parse(date_string, directives, parser),   do: do_parse(date_string, directives, parser, DateTime.new)
  defp do_parse(_, [], _, %DateTime{} = date), do: date
  defp do_parse(date_string, [%Directive{type: :format, format: format}|rest], parser, %DateTime{} = date) do
    case format do
      [tokenizer: tokenizer, format: format_string] ->
        case tokenizer.tokenize(format_string) do
          {:error, _} = error -> error
          directives -> do_parse(date_string, directives ++ rest, parser, date)
        end
      {:error, _} = error ->
        error
    end
  end
  defp do_parse(date_string, [%Directive{} = directive|rest], parser, %DateTime{} = date) do
    case parser.parse_directive(date_string, directive) do
      {_, {:error, reason}} ->
        {:error, reason}
      {token, {value, date_string}} ->
        case update_date(date, token, value) do
          {:error, _} = error -> error
          date                -> do_parse(date_string, rest, parser, date)
        end
      result ->
        {:error, "Invalid return value from parse_directive: #{result |> Macro.to_string}"}
    end
  end
  defp do_parse(_date_string, [directive|_rest], _parser, %DateTime{} = _date) do
    {:error, "#{directive} not implemented"}
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
      :century   -> %{date | :year => year + (value * 100)}
      :year2     ->
        %DateTime{year: current_year} = Date.now
        %{date | :year => (current_year - rem(current_year, 100)) + value}
      year when year in [:year4, :iso_year4, :iso_year2] ->
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
      :sec_epoch -> Date.from(value, :secs, :epoch)
      am_pm when am_pm in [:am, :AM] ->
        %{date | :hour => to_12hour_clock(date.hour, value)}
      # Timezones
      tz when tz in [:zname, :zoffs] ->
        %{date | :timezone => Timezone.get(value)}
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

  defp to_12hour_clock(hour, am_pm) when is_number(hour) and am_pm in ["AM", "am"] do
    case hour do
      hour when hour > 12 -> hour - 12
      hour when hour < 12 -> hour
    end
  end
  defp to_12hour_clock(hour, am_pm) when is_number(hour) and am_pm in ["PM", "pm"] do
    case hour do
      hour when hour > 12 -> hour
      hour when hour < 12 -> hour + 12
    end
  end

  @doc """
  Loads all parsers in all code paths.
  """
  @spec parsers() :: [] | [atom]
  def parsers, do: parsers(:code.get_path)

  @doc """
  Loads all parsers in the given `paths`.
  """
  @spec parsers([binary]) :: [] | [atom]
  def parsers(paths) do
    Enum.reduce(paths, [], fn(path, matches) ->
      {:ok, files} = :erl_prim_loader.list_dir(path)
      Enum.reduce(files, matches, &match_parsers/2)
    end)
  end

  @re_pattern Regex.re_pattern(~r/Elixir\.Timex\.Parsers\.DateFormat\..+Parser\.beam$/)

  @spec match_parsers(char_list, [atom]) :: [atom]
  defp match_parsers(filename, modules) do
    if :re.run(filename, @re_pattern, [capture: :none]) == :match do
      mod = :filename.rootname(filename, '.beam') |> List.to_atom
      if Code.ensure_loaded?(mod), do: [mod | modules], else: modules
    else
      modules
    end
  end

end