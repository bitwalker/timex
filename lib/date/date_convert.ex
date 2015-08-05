defprotocol Timex.Date.Convert do
  def to_gregorian(date)
  def to_erlang_datetime(date)
end

defimpl Timex.Date.Convert, for: Timex.DateTime do
  alias Timex.DateTime,     as: DateTime
  alias Timex.TimezoneInfo, as: TimezoneInfo

  @doc """
  Converts a DateTime struct to an Erlang datetime tuple + timezone tuple

  ## Examples:

      iex> {{2015, 3, 5}, {12, 0, 0}} |> Date.from("America/Chicago") |> Date.Convert.to_gregorian
      {{2015, 3, 5}, {12, 0, 0}, {5, "CDT"}}
  """
  def to_gregorian(
    %DateTime{
      :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec,
      :timezone => %TimezoneInfo{:abbreviation => abbrev, :offset_std => std}
    }) do
    # Use the correct abbreviation depending on whether we're in DST or not
    { {y, m, d}, {h, min, sec}, {std / 60, abbrev}}
  end

  @doc """
  Converts a DateTime struct to an Erlang datetime tuple
  """
  def to_erlang_datetime(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}) do
    { {y, m, d}, {h, min, sec} }
  end
end
