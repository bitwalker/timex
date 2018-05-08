defmodule Timex.Format.FormatError do
  @moduledoc """
  Used for errors encountered during string formatting.
  """
  defexception message: "Invalid format!"

  def exception([message: message]) when is_binary(message) do
    %__MODULE__{message: message}
  end
  def exception([message: message]) do
    %__MODULE__{message: "Invalid format: #{inspect message}"}
  end
  def exception(err) do
    %__MODULE__{message: "Invalid format: #{inspect err}"}
  end
end
