defprotocol Timex.Protocol do
  @moduledoc """
  This protocol defines the API for functions which take a `Date`,
  `NaiveDateTime`, or `DateTime` as input.
  """

  @fallback_to_any true

  alias Timex.Types

  @doc """
  Convert a date/time value to a Julian calendar date number
  """
  @spec to_julian(Types.valid_datetime()) :: integer | {:error, term}
  def to_julian(datetime)

  @doc """
  Convert a date/time value to gregorian seconds (seconds since start of year zero)
  """
  @spec to_gregorian_seconds(Types.valid_datetime()) :: non_neg_integer | {:error, term}
  def to_gregorian_seconds(datetime)

  @doc """
  Convert a date/time value to gregorian microseconds (microseconds since the start of year zero)
  """
  @spec to_gregorian_microseconds(Types.valid_datetime()) :: non_neg_integer | {:error, term}
  def to_gregorian_microseconds(datetime)

  @doc """
  Convert a date/time value to seconds since the UNIX Epoch
  """
  @spec to_unix(Types.valid_datetime()) :: non_neg_integer | {:error, term}
  def to_unix(datetime)

  @doc """
  Convert a date/time value to a Date
  """
  @spec to_date(Types.valid_datetime()) :: Date.t() | {:error, term}
  def to_date(datetime)

  @doc """
  Convert a date/time value to a DateTime.
  An optional timezone can be provided, UTC will be assumed if one is not provided.
  """
  @spec to_datetime(Types.valid_datetime()) :: DateTime.t() | {:error, term}
  @spec to_datetime(Types.valid_datetime(), Types.valid_timezone()) ::
          DateTime.t() | Timex.AmbiguousDateTime.t() | {:error, term}
  def to_datetime(datetime, timezone \\ :utc)

  @doc """
  Convert a date/time value to a NaiveDateTime
  """
  @spec to_naive_datetime(Types.valid_datetime()) :: NaiveDateTime.t() | {:error, term}
  def to_naive_datetime(datetime)

  @doc """
  Convert a date/time value to it's Erlang tuple variant
  i.e. Date becomes `{y,m,d}`, DateTime/NaiveDateTime become
  `{{y,m,d},{h,mm,s}}`
  """
  @spec to_erl(Types.valid_datetime()) :: Types.date() | Types.datetime() | {:error, term}
  def to_erl(datetime)

  @doc """
  Get the century a date/time value is in
  """
  @spec century(Types.year() | Types.valid_datetime()) :: non_neg_integer | {:error, term}
  def century(datetime)

  @doc """
  Return a boolean indicating whether the date/time value is in a leap year
  """
  @spec is_leap?(Types.valid_datetime() | Types.year()) :: boolean | {:error, term}
  def is_leap?(datetime)

  @doc """
  Shift a date/time value using a list of shift unit/value pairs
  """
  @spec shift(Types.valid_datetime(), Timex.shift_options()) ::
          Types.valid_datetime() | Timex.AmbiguousDateTime.t() | {:error, term}
  def shift(datetime, options)

  @doc """
  Set fields on a date/time value using a list of unit/value pairs
  """
  @spec set(Types.valid_datetime(), Timex.set_options()) ::
          Types.valid_datetime() | {:error, term}
  def set(datetime, options)

  @doc """
  Get a new version of the date/time value representing the beginning of the day
  """
  @spec beginning_of_day(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  def beginning_of_day(datetime)

  @doc """
  Get a new version of the date/time value representing the end of the day
  """
  @spec end_of_day(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  def end_of_day(datetime)

  @doc """
  Get a new version of the date/time value representing the beginning of it's week,
  providing a weekday name (as an atom) for the day which starts the week, i.e. `:mon`.
  """
  @spec beginning_of_week(Types.valid_datetime(), Types.weekstart()) ::
          Types.valid_datetime() | {:error, term}
  def beginning_of_week(datetime, weekstart)

  @doc """
  Get a new version of the date/time value representing the ending of it's week,
  providing a weekday name (as an atom) for the day which starts the week, i.e. `:mon`.
  """
  @spec end_of_week(Types.valid_datetime(), Types.weekstart()) ::
          Types.valid_datetime() | {:error, term}
  def end_of_week(datetime, weekstart)

  @doc """
  Get a new version of the date/time value representing the beginning of it's year
  """
  @spec beginning_of_year(Types.year() | Types.valid_datetime()) ::
          Types.valid_datetime() | {:error, term}
  def beginning_of_year(datetime)

  @doc """
  Get a new version of the date/time value representing the ending of it's year
  """
  @spec end_of_year(Types.year() | Types.valid_datetime()) ::
          Types.valid_datetime() | {:error, term}
  def end_of_year(datetime)

  @doc """
  Get a new version of the date/time value representing the beginning of it's quarter
  """
  @spec beginning_of_quarter(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  def beginning_of_quarter(datetime)

  @doc """
  Get a new version of the date/time value representing the ending of it's quarter
  """
  @spec end_of_quarter(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  def end_of_quarter(datetime)

  @doc """
  Get a new version of the date/time value representing the beginning of it's month
  """
  @spec beginning_of_month(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  def beginning_of_month(datetime)

  @doc """
  Get a new version of the date/time value representing the ending of it's month
  """
  @spec end_of_month(Types.valid_datetime()) :: Types.valid_datetime() | {:error, term}
  def end_of_month(datetime)

  @doc """
  Get the quarter for the given date/time value
  """
  @spec quarter(Types.month() | Types.valid_datetime()) :: 1..4 | {:error, term}
  def quarter(datetime)

  @doc """
  Get the number of days in the month for the given date/time value
  """
  @spec days_in_month(Types.valid_datetime()) :: Types.num_of_days() | {:error, term}
  def days_in_month(datetime)

  @doc """
  Get the week number of the given date/time value, starting at 1
  """
  @spec week_of_month(Types.valid_datetime()) :: Types.week_of_month() | {:error, term}
  def week_of_month(datetime)

  @doc """
  Get the ordinal weekday number of the given date/time value
  """
  @spec weekday(Types.valid_datetime()) :: Types.weekday() | {:error, term}
  def weekday(datetime)

  @doc """
  Get the ordinal weekday number of the given date/time value and relative to the given weekstart
  """
  @spec weekday(Types.valid_datetime(), Calendar.day_of_week()) ::
          Types.weekday() | {:error, term}
  def weekday(datetime, weekstart)

  @doc """
  Get the ordinal day number of the given date/time value
  """
  @spec day(Types.valid_datetime()) :: Types.daynum() | {:error, term}
  def day(datetime)

  @doc """
  Determine if the provided date/time value is valid.
  """
  @spec is_valid?(Types.valid_datetime()) :: boolean | {:error, term}
  def is_valid?(datetime)

  @doc """
  Return a pair {year, week number} (as defined by ISO 8601) that the given date/time value falls on.
  """
  @spec iso_week(Types.valid_datetime()) :: {Types.year(), Types.weeknum()} | {:error, term}
  def iso_week(datetime)

  @doc """
  Shifts the given date/time value to the ISO day given
  """
  @spec from_iso_day(Types.valid_datetime(), non_neg_integer) ::
          Types.valid_datetime() | {:error, term}
  def from_iso_day(datetime, day)
end

defimpl Timex.Protocol, for: Any do
  def to_julian(%{__struct__: _} = d), do: Timex.to_julian(Map.from_struct(d))
  def to_julian(_datetime), do: {:error, :invalid_date}

  def to_gregorian_seconds(%{__struct__: _} = d),
    do: Timex.to_gregorian_seconds(Map.from_struct(d))

  def to_gregorian_seconds(_datetime), do: {:error, :invalid_date}

  def to_gregorian_microseconds(%{__struct__: _} = d),
    do: Timex.to_gregorian_microseconds(Map.from_struct(d))

  def to_gregorian_microseconds(_datetime), do: {:error, :invalid_date}

  def to_unix(%{__struct__: _} = d), do: Timex.to_unix(Map.from_struct(d))
  def to_unix(_datetime), do: {:error, :invalid_date}

  def to_date(%{__struct__: _} = d), do: Timex.to_date(Map.from_struct(d))
  def to_date(_datetime), do: {:error, :invalid_date}

  def to_datetime(%{__struct__: _} = d, timezone),
    do: Timex.to_datetime(Map.from_struct(d), timezone)

  def to_datetime(_datetime, _timezone), do: {:error, :invalid_date}

  def to_naive_datetime(%{__struct__: _} = d), do: Timex.to_naive_datetime(Map.from_struct(d))
  def to_naive_datetime(_datetime), do: {:error, :invalid_date}

  def to_erl(%{__struct__: _} = d), do: Timex.to_erl(Map.from_struct(d))
  def to_erl(_datetime), do: {:error, :invalid_date}

  def century(%{__struct__: _} = d), do: Timex.century(Map.from_struct(d))
  def century(_datetime), do: {:error, :invalid_date}

  def is_leap?(%{__struct__: _} = d), do: Timex.is_leap?(Map.from_struct(d))
  def is_leap?(_datetime), do: {:error, :invalid_date}

  def shift(%{__struct__: _} = d, options), do: Timex.shift(Map.from_struct(d), options)
  def shift(_datetime, _options), do: {:error, :invalid_date}

  def set(%{__struct__: _} = d, options), do: Timex.set(Map.from_struct(d), options)
  def set(_datetime, _options), do: {:error, :invalid_date}

  def beginning_of_day(%{__struct__: _} = d), do: Timex.beginning_of_day(Map.from_struct(d))
  def beginning_of_day(_datetime), do: {:error, :invalid_date}

  def end_of_day(%{__struct__: _} = d), do: Timex.end_of_day(Map.from_struct(d))
  def end_of_day(_datetime), do: {:error, :invalid_date}

  def beginning_of_week(%{__struct__: _} = d, weekstart),
    do: Timex.beginning_of_week(Map.from_struct(d), weekstart)

  def beginning_of_week(_datetime, _weekstart), do: {:error, :invalid_date}

  def end_of_week(%{__struct__: _} = d, weekstart),
    do: Timex.end_of_week(Map.from_struct(d), weekstart)

  def end_of_week(_datetime, _weekstart), do: {:error, :invalid_date}

  def beginning_of_year(%{__struct__: _} = d), do: Timex.beginning_of_year(Map.from_struct(d))
  def beginning_of_year(_datetime), do: {:error, :invalid_date}

  def end_of_year(%{__struct__: _} = d), do: Timex.end_of_year(Map.from_struct(d))
  def end_of_year(_datetime), do: {:error, :invalid_date}

  def beginning_of_quarter(%{__struct__: _} = d),
    do: Timex.beginning_of_quarter(Map.from_struct(d))

  def beginning_of_quarter(_datetime), do: {:error, :invalid_date}

  def end_of_quarter(%{__struct__: _} = d), do: Timex.end_of_quarter(Map.from_struct(d))
  def end_of_quarter(_datetime), do: {:error, :invalid_date}

  def beginning_of_month(%{__struct__: _} = d), do: Timex.beginning_of_month(Map.from_struct(d))
  def beginning_of_month(_datetime), do: {:error, :invalid_date}

  def end_of_month(%{__struct__: _} = d), do: Timex.end_of_month(Map.from_struct(d))
  def end_of_month(_datetime), do: {:error, :invalid_date}

  def quarter(%{__struct__: _} = d), do: Timex.quarter(Map.from_struct(d))
  def quarter(_datetime), do: {:error, :invalid_date}

  def days_in_month(%{__struct__: _} = d), do: Timex.days_in_month(Map.from_struct(d))
  def days_in_month(_datetime), do: {:error, :invalid_date}

  def week_of_month(%{__struct__: _} = d), do: Timex.week_of_month(Map.from_struct(d))
  def week_of_month(_datetime), do: {:error, :invalid_date}

  def weekday(%{__struct__: _} = d), do: Timex.weekday(Map.from_struct(d))
  def weekday(_datetime), do: {:error, :invalid_date}

  def weekday(%{__struct__: _} = d, weekstart), do: Timex.weekday(Map.from_struct(d), weekstart)
  def weekday(_datetime, _weekstart), do: {:error, :invalid_date}

  def day(%{__struct__: _} = d), do: Timex.day(Map.from_struct(d))
  def day(_datetime), do: {:error, :invalid_date}

  def is_valid?(%{__struct__: _} = d), do: Timex.is_valid?(Map.from_struct(d))
  def is_valid?(_datetime), do: false

  def iso_week(%{__struct__: _} = d), do: Timex.iso_week(Map.from_struct(d))
  def iso_week(_datetime), do: {:error, :invalid_date}

  def from_iso_day(%{__struct__: _} = d, _day), do: Timex.from_iso_day(Map.from_struct(d))
  def from_iso_day(_datetime, _day), do: {:error, :invalid_date}
end
