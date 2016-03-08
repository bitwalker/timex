defimpl Timex.Comparable, for: Timex.AmbiguousDateTime do
  alias Timex.Comparable
  alias Timex.AmbiguousDateTime

  @doc """
  See docs for `Timex.compare/3`
  """
  def compare(_, :distant_future, _granularity), do: -1
  def compare(_, :distant_past, _granularity), do: 1
  def compare(%AmbiguousDateTime{:after => a}, %AmbiguousDateTime{:after => b}, granularity) do
    Comparable.compare(a, b, granularity)
  end
  def compare(a, _b, _granularity),
    do: {:error, {:ambiguous_comparison, a}}

  def diff(%AmbiguousDateTime{:after => a}, %AmbiguousDateTime{:after => b}, granularity) do
    Comparable.compare(a, b, granularity)
  end
  def diff(a, _b, _granularity),
    do: {:error, {:ambiguous_comparison, a}}
end
