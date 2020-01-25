defimpl Timex.Comparable, for: NaiveDateTime do
  alias Timex.AmbiguousDateTime
  alias Timex.Comparable.Utils
  alias Timex.Comparable.Diff
  require Timex.Macros

  def compare(a, :epoch, granularity), do: compare(a, Timex.epoch(), granularity)
  def compare(a, :zero, granularity), do: compare(a, Timex.zero(), granularity)
  def compare(_, :distant_past, _granularity), do: +1
  def compare(_, :distant_future, _granularity), do: -1
  def compare(a, a, _granularity), do: 0

  def compare(_, %AmbiguousDateTime{} = b, _granularity),
    do: {:error, {:ambiguous_comparison, b}}

  def compare(a, b, granularity),
    do: Utils.to_compare_result(diff(a, b, granularity))

  def diff(_, %AmbiguousDateTime{} = b, _granularity),
    do: {:error, {:ambiguous_comparison, b}}

  defdelegate diff(a, b, granularity), to: Diff
end
