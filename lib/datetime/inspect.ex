defimpl Inspect, for: Timex.DateTime do
  alias Timex.DateTime
  alias Timex.TimezoneInfo

  def inspect(datetime, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(datetime, opts)
  end
  def inspect(%DateTime{:timezone => %TimezoneInfo{:full_name => "UTC"}} = datetime, _) do
    Timex.format!(datetime, "#<DateTime({YYYY}-{0M}-{0D}T{h24}:{m}:{s}Z)>")
  end
  def inspect(%DateTime{} = datetime, _) do
    Timex.format!(datetime, "#<DateTime({YYYY}-{0M}-{0D}T{h24}:{m}:{s} {Zname} ({Z::}))>")
  end
end

defimpl Inspect, for: Timex.AmbiguousDateTime do
  alias Timex.AmbiguousDateTime

  def inspect(datetime, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(datetime, opts)
  end

  def inspect(%AmbiguousDateTime{:before => before, :after => aft}, _opts) do
    "#<Ambiguous(#{inspect before} ~ #{inspect aft})>"
  end
end
