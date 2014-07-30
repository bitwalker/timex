defmodule Timex.Parsers.DateFormat.ParserState do
  @derive Access
  defstruct col: 0,          # The current column number
            start_index: 0,  # The last index of a starting token
            padding: 0,      # The amount of padding for the current token
            pad_type: :zero, # The character to use for padding, :zero or :space
            token: "",       # The current state of the parsed token
            tokens: []       # A keyword list of tokens
end