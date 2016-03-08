defimpl Timex.Comparable, for: Tuple do
  alias Timex.Comparable
  alias Timex.Convertable

  @doc """
  See docs for `Timex.compare/3`
  """
  def compare(_, :distant_future, _granularity), do: -1
  def compare(_, :distant_past, _granularity), do: 1
  def compare(a, b, granularity) do
    case Convertable.to_datetime(a) do
      {:error, _} = err -> err
      datetime ->
        Comparable.compare(datetime, b, granularity)
    end
  end

  def diff(a, b, granularity) do
    case Convertable.to_datetime(a) do
      {:error, _} = err -> err
      datetime ->
        Comparable.diff(datetime, b, granularity)
    end
  end
end
