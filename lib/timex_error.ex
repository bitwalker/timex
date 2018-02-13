defmodule Timex.TimexError do
  @moduledoc """
  Used for errors encountered during string formatting.
  """
  alias Timex.TimexError

  defexception message: "Invalid input!", atom: nil

  def exception(message: message) when is_atom(message) do
    %TimexError{message: to_string(message), atom: message}
  end
  def exception(message: message) do
    %TimexError{message: message}
  end
end
