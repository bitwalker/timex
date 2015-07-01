defmodule Timex.Format.FormatError do
  @moduledoc """
  Used for errors encountered during date formatting.
  """
  alias Timex.Format.FormatError

  defexception message: "Invalid format!"

  def exception([message: message]) do
    %FormatError{message: message}
  end
end
