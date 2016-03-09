defimpl Timex.Comparable, for: Timex.AmbiguousDateTime do
  alias Timex.Comparable
  alias Timex.Convertable
  alias Timex.DateTime
  alias Timex.AmbiguousDateTime

  @doc """
  See docs for `Timex.compare/3`
  """
  def compare(_, :distant_future, _granularity), do: -1
  def compare(_, :distant_past, _granularity), do: 1
  def compare(%AmbiguousDateTime{:after => a}, %AmbiguousDateTime{:after => b}, granularity) do
    Comparable.compare(a, b, granularity)
  end
  def compare(a, b, granularity) do
    case Convertable.to_datetime(b) do
      {:error, _} = err ->
        err
      %DateTime{}  ->
        {:error, {:ambiguous_comparison, a}}
      %AmbiguousDateTime{} = adt ->
        compare(a, adt, granularity)
    end
  end

  def diff(%AmbiguousDateTime{:after => a}, %AmbiguousDateTime{:after => b}, granularity) do
    Comparable.diff(a, b, granularity)
  end
  def diff(a, b, granularity) do
    case Convertable.to_datetime(b) do
      {:error, _} = err -> err
      %DateTime{} ->
        {:error, {:ambiguous_comparison, a}}
      %AmbiguousDateTime{} = adt ->
        diff(a, adt, granularity)
    end
  end
end
