defmodule Timex.Parsers.DateFormat.StrftimeParser do
  @moduledoc """
  This module is responsible for parsing date strings using
  the strftime formatting syntax.

  See `Timex.DateFormat.Formatters.StrftimeFormatter` for more info.
  """
  use Timex.Parsers.DateFormat.Parser

  @doc """
  The tokenizer used by this parser.
  """
  defdelegate tokenize(format_string), to: Timex.Parsers.DateFormat.Tokenizers.Strftime

  @doc """
  Extracts the value for a given directive.
  """
  defdelegate parse_directive(date_string, directive), to: Timex.Parsers.DateFormat.DefaultParser
end