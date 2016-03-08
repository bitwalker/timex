defimpl Timex.Comparable, for: Timex.Date do
  alias Timex.Date
  alias Timex.DateTime
  alias Timex.Convertable

  @doc """
  See docs for `Timex.compare/3`
  """
  def compare(_, :distant_future, _granularity), do: -1
  def compare(_, :distant_past, _granularity), do: 1
  def compare(a, b, granularity) do
    DateTime.compare(Date.to_datetime(a), Convertable.to_datetime(b), granularity)
  end

  @doc """
  See docs for `Timex.diff/3`
  """
  def diff(a, b, granularity) do
    DateTime.diff(Date.to_datetime(a), Convertable.to_datetime(b), granularity)
  end
end
