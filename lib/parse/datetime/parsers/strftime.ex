defmodule Timex.Parse.DateTime.Parsers.StrftimeParser do
  @moduledoc """
  This module is responsible for parsing date strings using
  the strftime formatting syntax.

  See `Timex.DateFormat.Formatters.StrftimeFormatter` for more info.
  """
  use Timex.Parse.DateTime.Parser

  @doc """
  The tokenizer used by this parser.
  """
  defdelegate tokenize(format_string), to: Timex.Format.DateTime.Tokenizers.Strftime

  @doc """
  Extracts the value for a given directive.
  """
  defdelegate parse_directive(date_string, directive), to: Timex.Parse.DateTime.Parsers.DefaultParser

  @doc """
  Constructs a DateTime from the parsed tokens
  """
  defdelegate apply_directives(tokens), to: Timex.Parse.DateTime.Parsers.DefaultParser
end
