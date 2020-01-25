defmodule Timex.Timezone.Utils do
  @moduledoc false

  {olson_mappings, _} = Path.join("priv", "standard_to_olson.exs") |> Code.eval_file()
  {windows_mappings, _} = Path.join("priv", "olson_to_win.exs") |> Code.eval_file()

  @doc """
  Lookup the Olson time zone given its standard name

  ## Example

      iex> Timex.Timezone.Utils.to_olson("Azores Standard Time")
      "Atlantic/Azores"

  """
  Enum.each(olson_mappings, fn {key, value} ->
    quoted =
      quote do
        def to_olson(unquote(key)), do: unquote(value)
      end

    Module.eval_quoted(__MODULE__, quoted, [], __ENV__)
  end)

  def to_olson(_tz), do: nil

  @doc """
  Lookup the Windows time zone name given an Olson time zone name.

  ## Example

      iex> Timex.Timezone.Utils.olson_to_win("Pacific/Noumea")
      "Central Pacific Standard Time"

  """
  Enum.each(windows_mappings, fn {key, value} ->
    quoted =
      quote do
        def olson_to_win(unquote(key)), do: unquote(value)
      end

    Module.eval_quoted(__MODULE__, quoted, [], __ENV__)
  end)

  def olson_to_win(_tz), do: nil
end
