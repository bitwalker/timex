defimpl Inspect, for: Timex.AmbiguousDateTime do
  alias Timex.AmbiguousDateTime

  def inspect(datetime, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(datetime, opts)
  end

  def inspect(%AmbiguousDateTime{:before => before, :after => aft}, _opts) do
    "#<Ambiguous(#{inspect before} ~ #{inspect aft})>"
  end
end


# Only provide Inspect for versions < 1.5.0-rc*
if System.version |> Version.parse! |> Version.compare(Version.parse!("1.5.0-rc.1")) == :lt do
  defimpl Inspect, for: DateTime do
    def inspect(%DateTime{} = d, _opts) do
      "#<DateTime(#{DateTime.to_iso8601(d)} #{d.time_zone})>"
    end
  end
end
