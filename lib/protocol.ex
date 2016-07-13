defprotocol Timex.Protocol do
  @moduledoc """
  This protocol defines the API for functions which take a `Date`,
  `NaiveDateTime`, or `DateTime` as input.
  """

  @doc """
  Convert a date/time value to a Julian calendar date number
  """
  def to_julian(datetime)

  @doc """
  Convert a date/time value to gregorian seconds (seconds since start of year zero)
  """
  def to_gregorian_seconds(datetime)

  @doc """
  Convert a date/time value to gregorian microseconds (microseconds since the start of year zero)
  """
  def to_gregorian_microseconds(datetime)

  @doc """
  Convert a date/time value to seconds since the UNIX Epoch
  """
  def to_unix(datetime)

  @doc """
  Convert a date/time value to a Date
  """
  def to_date(datetime)

  @doc """
  Convert a date/time value to a DateTime.
  An optional timezone can be provided, UTC will be assumed if one is not provided.
  """
  def to_datetime(datetime, timezone \\ :utc)

  @doc """
  Convert a date/time value to a NaiveDateTime
  """
  def to_naive_datetime(datetime)

  @doc """
  Convert a date/time value to it's Erlang tuple variant
  i.e. Date becomes `{y,m,d}`, DateTime/NaiveDateTime become
  `{{y,m,d},{h,mm,s}}`
  """
  def to_erl(datetime)

  @doc """
  Get the century a date/time value is in
  """
  def century(datetime)

  @doc """
  Return a boolean indicating whether the date/time value is in a leap year
  """
  def is_leap?(datetime)

  @doc """
  Shift a date/time value using a list of shift unit/value pairs
  """
  def shift(datetime, options)

  @doc """
  Set fields on a date/time value using a list of unit/value pairs
  """
  def set(datetime, options)

  @doc """
  Get a new version of the date/time value representing the beginning of the day
  """
  def beginning_of_day(datetime)

  @doc """
  Get a new version of the date/time value representing the end of the day
  """
  def end_of_day(datetime)

  @doc """
  Get a new version of the date/time value representing the beginning of it's week,
  providing a weekday name (as an atom) for the day which starts the week, i.e. `:mon`.
  """
  def beginning_of_week(datetime, weekstart)

  @doc """
  Get a new version of the date/time value representing the ending of it's week,
  providing a weekday name (as an atom) for the day which starts the week, i.e. `:mon`.
  """
  def end_of_week(datetime, weekstart)

  @doc """
  Get a new version of the date/time value representing the beginning of it's year
  """
  def beginning_of_year(datetime)

  @doc """
  Get a new version of the date/time value representing the ending of it's year
  """
  def end_of_year(datetime)

  @doc """
  Get a new version of the date/time value representing the beginning of it's quarter
  """
  def beginning_of_quarter(datetime)

  @doc """
  Get a new version of the date/time value representing the ending of it's quarter
  """
  def end_of_quarter(datetime)

  @doc """
  Get a new version of the date/time value representing the beginning of it's month
  """
  def beginning_of_month(datetime)

  @doc """
  Get a new version of the date/time value representing the ending of it's month
  """
  def end_of_month(datetime)

  @doc """
  Get the quarter for the given date/time value
  """
  def quarter(datetime)

  @doc """
  Get the number of days in the month for the given date/time value
  """
  def days_in_month(datetime)

  @doc """
  Get the week number of the given date/time value, starting at 1
  """
  def week_of_month(datetime)

  @doc """
  Get the ordinal weekday number of the given date/time value
  """
  def weekday(datetime)

  @doc """
  Get the ordinal day number of the given date/time value
  """
  def day(datetime)

  @doc """
  Determine if the provided date/time value is valid.
  """
  def is_valid?(datetime)

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that the given date/time value falls on.
  """
  def iso_week(datetime)

  @doc """
  Shifts the given date/time value to the ISO day given
  """
  def from_iso_day(datetime, day)
end

defimpl Timex.Protocol, for: Any do
  def to_julian(_datetime), do: {:error, :invalid_date}
  def to_gregorian_seconds(_datetime), do: {:error, :invalid_date}
  def to_gregorian_microseconds(_datetime), do: {:error, :invalid_date}
  def to_unix(_datetime), do: {:error, :invalid_date}
  def to_date(_datetime), do: {:error, :invalid_date}
  def to_datetime(_datetime, _timezone), do: {:error, :invalid_date}
  def to_naive_datetime(_datetime), do: {:error, :invalid_date}
  def to_erl(_datetime), do: {:error, :invalid_date}
  def century(_datetime), do: {:error, :invalid_date}
  def is_leap?(_datetime), do: {:error, :invalid_date}
  def shift(_datetime, _options), do: {:error, :invalid_date}
  def set(_datetime, _options), do: {:error, :invalid_date}
  def beginning_of_day(_datetime), do: {:error, :invalid_date}
  def end_of_day(_datetime), do: {:error, :invalid_date}
  def beginning_of_week(_datetime, _weekstart), do: {:error, :invalid_date}
  def end_of_week(_datetime, _weekstart), do: {:error, :invalid_date}
  def beginning_of_year(_datetime), do: {:error, :invalid_date}
  def end_of_year(_datetime), do: {:error, :invalid_date}
  def beginning_of_quarter(_datetime), do: {:error, :invalid_date}
  def end_of_quarter(_datetime), do: {:error, :invalid_date}
  def beginning_of_month(_datetime), do: {:error, :invalid_date}
  def end_of_month(_datetime), do: {:error, :invalid_date}
  def quarter(_datetime), do: {:error, :invalid_date}
  def days_in_month(_datetime), do: {:error, :invalid_date}
  def week_of_month(_datetime), do: {:error, :invalid_date}
  def weekday(_datetime), do: {:error, :invalid_date}
  def day(_datetime), do: {:error, :invalid_date}
  def is_valid?(_datetime), do: {:error, :invalid_date}
  def iso_week(_datetime), do: {:error, :invalid_date}
  def from_iso_day(_datetime, _day), do: {:error, :invalid_date}
end
