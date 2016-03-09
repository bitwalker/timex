defprotocol Timex.Convertable do
  @moduledoc """
  This protocol is used to convert between various common datetime formats.
  """

  @doc """
  Converts a date/time representation to an Erlang datetime tuple + timezone tuple

  ## Examples:

      iex> use Timex
      ...> datetime = Timex.datetime({{2015, 3, 5}, {12, 0, 0}}, "America/Chicago")
      ...> Timex.to_gregorian(datetime)
      {{2015, 3, 5}, {12, 0, 0}, {6, "CST"}}
  """
  def to_gregorian(date)

  @doc """
  Converts a date/time representation to a Julian date number

  ## Examples:

      iex> use Timex
      ...> Timex.to_julian({{2016,3,9}, {11,0,0}})
      2457457.4
  """
  def to_julian(date)

  @doc """
  Converts a date/time representation to the number of seconds since the start of
  year zero of the Gregorian calendar.

  ## Examples:

      iex> use Timex
      ...> Timex.to_gregorian_seconds({{2015, 3, 5}, {12, 0, 0}})
      63592776000
  """
  def to_gregorian_seconds(date)

  @doc """
  Converts a date/time representation to an Erlang datetime tuple

  ## Examples:

      iex> use Timex
      ...> datetime = Timex.datetime({{2015, 3, 5}, {12, 0, 0}}, "America/Chicago")
      ...> Timex.to_erlang_datetime(datetime)
      {{2015, 3, 5}, {12, 0, 0}}
  """
  def to_erlang_datetime(date)

  @doc """
  Converts a date/time representation to a Date struct

  ## Examples:

      iex> use Timex
      ...> Timex.to_date({{2015, 3, 5}, {12, 0, 0}})
      %Timex.Date{:year => 2015, :month => 3, :day => 5}
  """
  def to_date(date)

  @doc """
  Converts a date/time representation to a DateTime struct

  ## Examples:

      iex> use Timex
      ...> Timex.to_date({{2015, 3, 5}, {12, 0, 0}})
      %Timex.Date{:year => 2015, :month => 3, :day => 5}
  """
  def to_datetime(date)

  @doc """
  Converts a date/time representation to a UNIX timestamp (i.e. seconds since UNIX epoch)
  Returns {:error, :not_representable} if the date/time occurs before the UNIX epoch

  ## Examples:

      iex> use Timex
      ...> Timex.to_unix({{2015, 3, 5}, {12, 0, 0}})
      1425556800
  """
  def to_unix(date)

  @doc """
  Converts a date/time representation to an Erlang timestamp tuple, relative to the UNIX epoch

  ## Examples:

  iex> use Timex
  ...> Timex.to_timestamp({{2015, 3, 5}, {12, 0, 0}})
  {1425, 556800, 0}
  """
  def to_timestamp(date)
end
