defprotocol Timex.Comparable do
  @moduledoc """
  This protocol is used for comparing and diffing different date/time representations
  """
  alias Timex.Types

  @type granularity :: :years | :months | :weeks | :calendar_weeks | :days | :hours | :minutes | :seconds | :timestamp
  @type constants :: :epoch | :zero | :distant_past | :distant_future
  @type comparable :: DateTime.t | Date.t | Types.date | Types.datetime | Types.gregorian | constants
  @type compare_result :: -1 | 0 | 1 | {:error, term}

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
  - :timestamp

  and the dates will be compared with the cooresponding accuracy.
  The default granularity is :seconds.

    - 0:  when equal
    - -1: when the first date/time comes before the second
    - 1:  when the first date/time comes after the second
    - {:error, reason}: when there was a problem comparing,
      perhaps due to a value being passed which is not a valid date/datetime

  """
  @spec compare(comparable, comparable, granularity) :: compare_result
  def compare(a, b, granularity \\ :seconds)

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
  - :timestamp

  and the result will be a non-negative integer value of those units or a timestamp.


  """
  @spec diff(comparable, comparable, granularity) :: Types.timestamp | non_neg_integer | {:error, term}
  def diff(a, b, granularity \\ :seconds)
end
