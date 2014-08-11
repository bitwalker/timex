defmodule Timex.DateFormat.FormatError do
  @moduledoc """
  Used for errors encountered during date formatting.
  """
  alias Timex.DateFormat.FormatError

  defexception message: "Invalid format!"

  def exception(message) do
    %FormatError{message: message}
  end
end