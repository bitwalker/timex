defimpl Inspect, for: Timex.AmbiguousDateTime do
  alias Timex.AmbiguousDateTime

  def inspect(datetime, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(datetime, opts)
  end

  def inspect(%AmbiguousDateTime{:before => before, :after => aft}, _opts) do
    "#<Ambiguous(#{inspect before} ~ #{inspect aft})>"
  end
end


defimpl Inspect, for: DateTime do
  def instpect(datetime, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(datetime, opts)
  end

  def inspect(%DateTime{} = d, _opts) do
    "#<DateTime(#{DateTime.to_iso8601(d)} #{d.time_zone})>"
  end
end
