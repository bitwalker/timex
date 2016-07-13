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
  @type diff_result :: Timex.Duration | integer | {:error, term}

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
  The default granularity is :seconds.

    - 0:  when equal
    - -1: when the first date/time comes before the second
    - 1:  when the first date/time comes after the second
    - {:error, reason}: when there was a problem comparing,
      perhaps due to a value being passed which is not a valid date/datetime

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
  """
  @spec diff(comparable, comparable, granularity) :: diff_result
  def diff(a, b, granularity \\ :microseconds)
end
