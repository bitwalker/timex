defmodule Timex.Comparable.Utils do
  @moduledoc false

  alias Timex.Duration

  @doc false
  def to_compare_result(0), do: 0
  # If the diff is negative, a occurs before b
  def to_compare_result(n) when is_integer(n) and n < 0, do: -1
  # If the diff is positive, a occurs after b
  def to_compare_result(n) when is_integer(n) and n > 0, do: 1

  def to_compare_result(%Duration{} = d),
    do: to_compare_result(Duration.to_microseconds(d))

  def to_compare_result({:error, _} = err),
    do: err
end
