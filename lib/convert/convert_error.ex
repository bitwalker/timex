defmodule Timex.ConvertError do
  @moduledoc false
  defexception [:message]

  def exception({:error, :insufficient_date_information}) do
    %__MODULE__{message: "unable to convert value, insufficient date/time information"}
  end

  def exception({:error, {:expected_integer, for: k, got: v}}) do
    msg = "unable to convert value, expected integer for #{inspect(k)}, but got #{inspect(v)}"
    %__MODULE__{message: msg}
  end

  def exception({:error, reason}) do
    %__MODULE__{message: "unable to convert value: #{inspect(reason)}"}
  end

  def exception(reason) do
    %__MODULE__{message: "unable to convert value: #{inspect(reason)}"}
  end
end
