defmodule Timex.Calendar.Gregorian do
  @moduledoc """
  This module contains functions specific to the Gregorian calendar,
  many things are still in other modules, but as multi-calendar support
  is added, those things specific to Gregorian will be moved here.
  """
  alias Timex.Calendar

  @days_per_month_lookup %{
    true => %{
      1 => 31, 2 => 29, 3 => 31, 4 => 30,
      5 => 31, 6 => 30, 7 => 31, 8 => 31,
      9 => 30, 10 => 31, 11 => 30, 12 => 31
    },
    false => %{
      1 => 31, 2 => 28, 3 => 31, 4 => 30,
      5 => 31, 6 => 30, 7 => 31, 8 => 31,
      9 => 30, 10 => 31, 11 => 30, 12 => 31
    }
  }

  def days_in_month(year, month) do
    get_in(@days_per_month_lookup, [Calendar.is_leap_year?(year), month])
  end

end
