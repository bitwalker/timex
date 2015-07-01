defmodule Timex.Parse.ParseError do
  @moduledoc """
  Used for errors encountered during date parsing.
  """
  alias Timex.Parse.ParseError

  defexception message: "Invalid input!"

  def exception(message) do
    %ParseError{message: message}
  end
end
