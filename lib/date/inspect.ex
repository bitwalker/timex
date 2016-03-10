defimpl Inspect, for: Timex.Date do
  def inspect(date, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(date, opts)
  end
  def inspect(date, _) do
    Timex.format!(date, "#<Date({YYYY}-{0M}-{0D})>")
  end
end
