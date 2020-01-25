defmodule Timex.Format.FormatError do
  @moduledoc """
  Used for errors encountered during string formatting.
  """
  defexception message: "Invalid format!"

  def exception(message: message) do
    %__MODULE__{message: message}
  end

  def exception(err) do
    %__MODULE__{message: err}
  end

  def message(%__MODULE__{message: msg}) when is_binary(msg) do
    msg
  end

  def message(%__MODULE__{message: msg}) do
    "invalid format: #{inspect(msg)}"
  end
end
