defmodule Timex.Parse.DateTime.Parsers.DefaultParser do
  @moduledoc """
  This module is responsible for parsing date strings using
  the default timex formatting syntax.

  See `Timex.DateFormat.Formatters.DefaultFormatter` for more info.
  """
  use Timex.Parse.DateTime.Parser

  alias Timex.Format.DateTime.Directive
  alias Timex.DateTime
  alias Timex.TimezoneInfo

  @doc """
  The tokenizer used by this parser.
  """
  defdelegate tokenize(format_string), to: Timex.Format.DateTime.Tokenizers.Default

  @doc """
  Constructs a DateTime from the parsed tokens
  """
  def apply_directives([]),     do: {:ok, %DateTime{}}
  def apply_directives(tokens) do
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
    case Timex.Parse.DateTime.Parser.update_date(date, token, value) do
      {:error, _} = error -> error
      updated             -> apply_directives(tokens, updated)
    end
  end

  @doc """
  Extracts the value for a given directive.
  """
  def parse_directive(<<>>, _), do: {:error, @invalid_input}
  def parse_directive(date_string, %Directive{token: token} = directive) do
    {token, do_parse_directive(date_string, directive)}
  end


  # Special handling for fractional seconds
  defp do_parse_directive(<<?., date_string::binary>>, %Directive{token: :sec_fractional} = dir) do
    do_parse_directive(date_string, dir)
  end
  # If we attempt to parse the next character and it's not a number, return an empty string since
  # fractional seconds are optional
  defp do_parse_directive(<<c::utf8, _::binary>>=date_string, %Directive{token: :sec_fractional})
    when not c in ?0..?9 do
      {"", date_string}
  end
  # Validate that intermediate characters match, but return an empty string since we do not care
  # about the parse result from these directives.
  defp do_parse_directive(date_string, %Directive{type: :char, raw: char}) do
    char_size = byte_size(char)
    case date_string do
      <<^char :: binary-size(char_size), rest ::binary>> -> {"", rest}
      _     -> {:error, @invalid_input}
    end
  end
  # Pattern directives
  defp do_parse_directive(date_string, %Directive{token: _token, type: :pattern, pattern: pattern}) do
    case Regex.named_captures(pattern, date_string) do
      nil ->
        {:error, @invalid_input}
      map when is_map(map) ->
        date = %{}
               |> apply_map(map, "year")
               |> apply_map(map, "month")
               |> apply_map(map, "day")
               |> apply_map(map, "hour")
               |> apply_map(map, "minute")
               |> apply_map(map, "second")
               |> apply_map(map, "ms")
               |> apply_map(map, "fractional")
               |> apply_map(map, "timezone")
        {date, ""}
    end
  end
  # Numeric directives
  defp do_parse_directive(date_string, %Directive{token: token, type: :numeric, pad: pad} = dir) do
    date_chars = date_string |> String.to_char_list
    # Parse padding first
    {padding, padding_stripped} = date_chars |> strip_padding(pad, dir.pad_type)
    case padding_stripped do
      {:error, _} = error -> error
      []                  -> {:error, @invalid_input}
      [h|_] when h in @numerics == false -> {:error, @invalid_input}
      padding_stripped    ->
        # Extract a numeric value up to the maximum length allowed by dir.len
        chars = extract_value(padding_stripped, dir.len, @numerics, padding)
        # Convert to numeric value
        len = length(chars)
        padding_stripped = padding_stripped |> Enum.drop(len)

        valid? = chars
          |> valid_length?(token, dir.len)
          |> valid_value?(token, dir.validate)
          |> within_bounds?(token, dir.min, dir.max)
        case valid? do
          {:error, _} = error -> error
          str                 -> {str, padding_stripped |> List.to_string}
        end
    end
  end
  defp do_parse_directive(date_string, %Directive{token: token, type: :word, allowed_chars: allowed_chars} = dir) do
    date_chars = date_string |> String.to_char_list
    # Extract a word value up to the maximum length allowed by dir.len
    chars      = extract_value(date_chars, dir.len, allowed_chars)
    len        = length(chars)
    date_chars = date_chars |> Enum.drop(len)
    # Validate that the word value is of the correct length
    valid? = chars
      |> valid_length?(token, dir.len)
      |> valid_value?(token, dir.validate)
    case valid? do
      {:error, _} = error -> error
      str                 -> {str, date_chars |> List.to_string}
    end
  end
  defp do_parse_directive(date_string, %Directive{token: token, type: :match, match: match} = dir) when match != false do
    date_chars = date_string |> String.to_char_list
    # Drop leading non-word characters.
    date_chars = date_chars |> Enum.drop_while(fn c -> (c in @word_chars) == false end)
    # Extract a value up to the maximum length allowed by dir.len
    chars      = extract_value(date_chars, dir.len, @word_chars)
    len        = length(chars)
    date_chars = date_chars |> Enum.drop(len)
    # Validate that the value is of the correct length
    valid? = chars
      |> valid_length?(token, dir.len)
      |> valid_value?(token, match: match)
    case valid? do
      {:error, _} = error -> error
      str                 -> {str, date_chars |> List.to_string}
    end
  end
  defp do_parse_directive(_date_string, directive) do
    {:error, "Unsupported directive: #{directive |> Macro.to_string}"}
  end

  # Strip the padding from a char list

  # If 0 is given as padding, do nothing
  defp strip_padding(str, 0, _)
    when is_list(str),
    do: {0, str}
  # If we reach the end of the input string before
  # we trim all the padding, return an error.
  defp strip_padding([], pad, _)
    when pad > 0,
    do: {:error, "Unexpected end of string!"}
  # Start trimming off padding, but pass along the source string as well
  defp strip_padding(str, pad, pad_type)
    when is_list(str),
    do: strip_padding({0, str}, str, pad, pad_type)
  # If we hit 0, return the stripped string
  defp strip_padding({count, str}, _, 0, _),
    do: {count, str}
  # If we hit the end of the string before the
  # we trim all the padding, return an error.
  defp strip_padding({_,[]}, _, _, _),
    do: {:error, "Unexpected end of string!"}
  # Trim off leading zeros
  defp strip_padding({count, [h|rest]}, str, pad, :zero)
    when pad > 0 and h == ?0,
    do: strip_padding({count + 1, rest}, str, pad - 1, :zero)
  # Trim off leading spaces
  defp strip_padding({count, [h|rest]}, str, pad, :space)
    when pad > 0 and h == 32,
    do: strip_padding({count + 1, rest}, str, pad - 1, :space)
  # If the first character is not padding, and is the same
  # as the source string's first character, there is no padding
  # to strip.
  defp strip_padding({count, [h|_]}, [h|_] = str, pad, _)
    when pad > 0,
    do: {count, str}

  # Parse a value from a char list given a max length, and
  # a list of valid characters the value can be composed of
  defp extract_value(str, str_len, valid_chars, padding \\ 0) when is_list(str) do
    str_len = case str_len do
      :word                            -> :word
      lo..hi when lo <= (hi - padding) -> lo..(hi-padding)
      lo..hi when lo > (hi - padding)  -> 0
      num when (num - padding) > 0     -> (num - padding)
      _                                -> 0
    end
    Stream.transform(str, 0, fn char, chars_taken ->
      valid_char? = Enum.member?(valid_chars, char)
      case {char, str_len} do
        {char, :word} when valid_char? ->
          {[char], chars_taken + 1}
        {char, str_len} when is_number(str_len) and chars_taken < str_len and valid_char? ->
          {[char], chars_taken + 1}
        {char, _..hi} when chars_taken < hi and valid_char? ->
          {[char], chars_taken + 1}
        _ ->
          {:halt, chars_taken}
      end
    end) |> Enum.to_list
  end

  defp apply_map(date, map, key, default_value \\ nil)

  defp apply_map({:error, _} = err, _, _, _), do: err
  defp apply_map(date, map, key, default_value) when key in ["year", "month", "day", "hour", "minute", "second", "ms"] do
    case Map.get(map, key) do
      nil -> date
      ""  -> date
      val ->
        case {to_int(val), default_value} do
          {:error, nil}     -> {:error, "Value for `#{key}` is invalid (non-numeric): #{val}"}
          {:error, default} -> Map.put(date, String.to_atom(key), default)
          {parsed, _}       -> Map.put(date, String.to_atom(key), parsed)
        end
    end
  end
  defp apply_map(date, map, "fractional", default_value) do
    case Map.get(map, "fractional") do
      nil -> date
      ""  -> date
      val ->
        case {to_float("0.#{val}"), default_value} do
          {:error, nil}     -> {:error, "Value for `fractional` is invalid (non-numeric): #{val}"}
          {:error, default} -> Map.put(date, :ms, default)
          {parsed, _}       -> Map.put(date, :ms, (1_000*parsed) |> Float.round |> trunc)
        end
    end
  end
  defp apply_map(date, map, "timezone", _) do
    case Map.get(map, "timezone") do
      nil -> date
      val -> Map.put(date, :timezone, val)
    end
  end

  defp to_int(str) do
    case Integer.parse(str) do
      {n, _} -> n
      :error -> :error
    end
  end
  defp to_float(str) do
    case Float.parse(str) do
      {n, _} -> n
      :error -> :error
    end
  end

end
