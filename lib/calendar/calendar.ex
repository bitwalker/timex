defmodule Timex.Calendar do
  @moduledoc """
  This module contains functions that are common across more than a single calendar

  Currently it is empty, but that will change as multi-calendar support is added.
  """

  def is_leap_year?(year), do: :calendar.is_leap_year(year)
end
