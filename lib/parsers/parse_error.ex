defmodule Timex.Parsers.ParseError do
  @moduledoc """
  Used for errors encountered during date parsing.
  """
  alias Timex.Parsers.ParseError

  defexception message: "Invalid input!"

  def exception(message) do
    %ParseError{message: message}
  end
end