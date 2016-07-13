defimpl Inspect, for: Timex.Duration do
  alias Timex.Duration

  def inspect(d, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(d, opts)
  end

  def inspect(d, _opts) do
    "#<Duration(#{Duration.to_string(d)})>"
  end
end
