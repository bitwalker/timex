defimpl Inspect, for: Timex.TimezoneInfo do
  def inspect(date, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(date, opts)
  end

  def inspect(tzinfo, _) do
    offset = Timex.TimezoneInfo.format_offset(tzinfo)
    "#<TimezoneInfo(#{tzinfo.full_name} - #{tzinfo.abbreviation} (#{offset}))>"
  end
end

defimpl Inspect, for: Timex.AmbiguousTimezoneInfo do
  alias Timex.AmbiguousTimezoneInfo

  def inspect(date, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(date, opts)
  end

  def inspect(%AmbiguousTimezoneInfo{:before => before, :after => aft}, _opts) do
    "#<Ambiguous(#{inspect(before)} ~ #{inspect(aft)})>"
  end
end
