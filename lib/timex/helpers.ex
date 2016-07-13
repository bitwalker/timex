defmodule Timex.Helpers do
  @moduledoc false
  use Timex.Constants
  import Timex.Macros

  def iso_day_to_date_tuple(year, day) when is_year(year) and is_day_of_year(day) do
    {year, day} = cond do
      day < 1 && :calendar.is_leap_year(year - 1) -> {year - 1, day + 366}
      day < 1                                     -> {year - 1, day + 365}
      day > 366 && :calendar.is_leap_year(year)   -> {year, day - 366}
      day > 365                                   -> {year, day - 365}
      true                                        -> {year, day}
    end
    {_, month, first_of_month} = Enum.take_while(@ordinal_day_map, fn {_, _, oday} -> oday <= day end) |> List.last
    {year, month, day - first_of_month}
  end

  def days_in_month(year, month) when is_year(year) and is_month(month) do
    :calendar.last_day_of_the_month(year, month)
  end
  def days_in_month(year, month) do
    valid_year?  = year > 0
    valid_month? = month in @valid_months
    cond do
      !valid_year? && valid_month? ->
        {:error, :invalid_year}
      valid_year? && !valid_month? ->
        {:error, :invalid_month}
      true ->
        {:error, :invalid_year_and_month}
    end
  end

  @doc """
  Given a {year, month, day} tuple, normalizes it so
  that the day does not exceed the maximum valid days in that month
  """
  def normalize_date_tuple({year, month, day}) do
    # Check if we got past the last day of the month
    max_day = days_in_month(year, month)
    {year, month, min(day, max_day)}
  end

  def round_month(m) do
    case mod(m, 12) do
      0     -> 12
      other -> other
    end
  end

  defp mod(a, b), do: rem(rem(a, b) + b, b)
end
