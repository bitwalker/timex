defprotocol Timex.Comparable do
  @moduledoc """
  This protocol is used for comparing and diffing different date/time representations
  """
  alias Timex.Types

  @type granularity :: :years | :months | :weeks | :calendar_weeks | :days |
                       :hours | :minutes | :seconds | :milliseconds | :microseconds |
                       :duration
  @type constants :: :epoch | :zero | :distant_past | :distant_future
  @type comparable :: Date.t | DateTime.t | NaiveDateTime.t | Types.date | Types.datetime
  @type compare_result :: -1 | 0 | 1 | {:error, term}
  @type diff_result :: Timex.Duration.t | integer | {:error, term}

  @doc """
  Compare two date or datetime types.

  You can optionally specify a comparison granularity, any of the following:

  - :years
  - :months
  - :weeks
  - :calendar_weeks (weeks of the calendar as opposed to actual weeks in terms of days)
  - :days
  - :hours
  - :minutes
  - :seconds
  - :milliseconds
  - :microseconds (default)
  - :duration

  and the dates will be compared with the cooresponding accuracy.
  The default granularity is :microseconds.

    - 0:  when equal
    - -1: when the first date/time comes before the second
    - 1:  when the first date/time comes after the second
    - {:error, reason}: when there was a problem comparing,
      perhaps due to a value being passed which is not a valid date/datetime

  ## Examples

      iex> use Timex
      iex> date1 = ~D[2014-03-04]
      iex> date2 = ~D[2015-03-04]
      iex> Timex.compare(date1, date2, :years)
      -1
      iex> Timex.compare(date2, date1, :years)
      1
      iex> Timex.compare(date1, date1)
      0
  """
  @spec compare(comparable, comparable, granularity) :: compare_result
  def compare(a, b, granularity \\ :microseconds)

  @doc """
  Get the difference between two date or datetime types.

  You can optionally specify a diff granularity, any of the following:

  - :years
  - :months
  - :calendar_weeks (weeks of the calendar as opposed to actual weeks in terms of days)
  - :weeks
  - :days
  - :hours
  - :minutes
  - :seconds
  - :milliseconds
  - :microseconds (default)
  - :duration

  and the result will be an integer value of those units or a Duration struct.
  The diff value will be negative if `a` comes before `b`, and positive if `a` comes
  after `b`. This behaviour mirrors `compare/3`.

  When using granularity of :months, the number of days in the month varies. This
  behavior mirrors `Timex.shift/2`.

  ## Examples

      iex> use Timex
      iex> date1 = ~D[2015-01-28]
      iex> date2 = ~D[2015-02-28]
      iex> Timex.diff(date1, date2, :months)
      -1
      iex> Timex.diff(date2, date1, :months)
      1

      iex> use Timex
      iex> date1 = ~D[2015-01-31]
      iex> date2 = ~D[2015-02-28]
      iex> Timex.diff(date1, date2, :months)
      -1
      iex> Timex.diff(date2, date1, :months)
      0
  """
  @spec diff(comparable, comparable, granularity) :: diff_result
  def diff(a, b, granularity \\ :microseconds)
end
