defmodule Timex.Helpers do
  @moduledoc false
  use Timex.Constants
  import Timex.Macros
  alias Timex.Types

  @doc """
  Given a {year, day} tuple where the day is the iso day of that year, returns 
  the date tuple of format {year, month, day}.

  ## Examples

      iex> Timex.Helpers.iso_day_to_date_tuple(1988, 240)
      {1988, 8, 27}

  If the given day or year are invalid a tuple of the format {:error, :reason}
  is returned. For example:

      iex> Timex.Helpers.iso_day_to_date_tuple(-50, 20)
      {:error, :invalid_year}

      iex> Timex.Helpers.iso_day_to_date_tuple(50, 400)
      {:error, :invalid_day}

      iex> Timex.Helpers.iso_day_to_date_tuple(-50, 400)
      {:error, :invalid_year_and_day}

  Days which are valid on leap years but not on non-leap years are invalid on
  non-leap years. For example:

      iex> Timex.Helpers.iso_day_to_date_tuple(2028, 366)
      {2028, 12, 31}

      iex> Timex.Helpers.iso_day_to_date_tuple(2027, 366)
      {:error, :invalid_day}
  """
  @spec iso_day_to_date_tuple(Types.year(), Types.day()) ::
          Types.valid_datetime() | {:error, term}
  def iso_day_to_date_tuple(year, day) when is_year(year) and is_iso_day_of_year(year, day) do
    {month, first_of_month} =
      cond do
        :calendar.is_leap_year(year) ->
          List.last(Enum.take_while(@ordinals_leap, fn {_m, odom} -> odom <= day end))

        :else ->
          List.last(Enum.take_while(@ordinals, fn {_m, odom} -> odom <= day end))
      end

    {year, month, day - (first_of_month - 1)}
  end

  def iso_day_to_date_tuple(year, _) when is_year(year), do: {:error, :invalid_day}

  def iso_day_to_date_tuple(year, day) when is_iso_day_of_year(year, day) do
    {:error, :invalid_year}
  end

  def iso_day_to_date_tuple(_, _), do: {:error, :invalid_year_and_day}

  def days_in_month(year, month) when is_year(year) and is_month(month) do
    :calendar.last_day_of_the_month(year, month)
  end

  def days_in_month(year, month) do
    valid_year? = year > 0
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
      0 -> 12
      other -> other
    end
  end

  defp mod(a, b), do: rem(rem(a, b) + b, b)
end
