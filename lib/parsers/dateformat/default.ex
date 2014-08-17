defmodule Timex.Parsers.DateFormat.DefaultParser do
  @moduledoc """
  This module is responsible for parsing date strings using
  the default timex formatting syntax.

  See `Timex.DateFormat.Formatters.DefaultFormatter` for more info.
  """
  use Timex.Parsers.DateFormat.Parser

  alias Timex.Parsers.DateFormat.Directive

  @doc """
  The tokenizer used by this parser.
  """
  defdelegate tokenize(format_string), to: Timex.Parsers.DateFormat.Tokenizers.Default

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
  # Numeric directives
  defp do_parse_directive(date_string, %Directive{token: token, type: :numeric, pad: pad} = dir) do
    date_chars = date_string |> String.to_char_list
    # Drop non-numeric characters
    date_chars = date_chars |> Enum.drop_while(fn c -> (c in @numerics) == false end)
    # Parse padding first
    padding_stripped = date_chars |> strip_padding(pad, dir.pad_type)
    # Parse value
    case padding_stripped do
      {:error, _} = error -> error
      []                  -> {:error, @invalid_input}
      padding_stripped    ->
        # Extract a numeric value up to the maximum length allowed by dir.len
        chars = extract_value(padding_stripped, dir.len, @numerics)
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
  defp do_parse_directive(date_string, %Directive{token: token, type: :word} = dir) do
    date_chars = date_string |> String.to_char_list
    # Drop leading non-alpha characters.
    date_chars = date_chars |> Enum.drop_while(&(Enum.member?(@allowed_chars, &1) == false))
    # Extract a word value up to the maximum length allowed by dir.len
    chars      = extract_value(date_chars, dir.len, @allowed_chars)
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
    do: str
  # If we reach the end of the input string before
  # we trim all the padding, return an error.
  defp strip_padding([], pad, _)
    when pad > 0,
    do: {:error, "Unexpected end of string!"}
  # Start trimming off padding, but pass along the source string as well
  defp strip_padding(str, pad, pad_type)
    when is_list(str),
    do: strip_padding(str, str, pad, pad_type)
  # If we hit 0, return the stripped string
  defp strip_padding(str, _, 0, _),
    do: str
  # If we hit the end of the string before the
  # we trim all the padding, return an error.
  defp strip_padding([], _, _, _),
    do: {:error, "Unexpected end of string!"}
  # Trim off leading zeros
  defp strip_padding([h|rest], str, pad, :zero)
    when pad > 0 and h == ?0,
    do: strip_padding(rest, str, pad - 1, :zero)
  # Trim off leading spaces
  defp strip_padding([h|rest], str, pad, :space)
    when pad > 0 and h == 32,
    do: strip_padding(rest, str, pad - 1, :space)
  # If the first character is not padding, and is the same
  # as the source string's first character, there is no padding
  # to strip.
  defp strip_padding([h|_], [h|_] = str, pad, _)
    when pad > 0,
    do: str

  # Parse a value from a char list given a max length, and 
  # a list of valid characters the value can be composed of
  defp extract_value(str, str_len, valid_chars) when is_list(str) do
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

end