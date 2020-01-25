defimpl Inspect, for: Timex.TimezoneInfo do
  def inspect(date, %{:structs => false} = opts) do
    Inspect.Algebra.to_doc(date, opts)
  end

  def inspect(tzinfo, _) do
    total_offset = Timex.Timezone.total_offset(tzinfo)
    offset = format_offset(total_offset)
    "#<TimezoneInfo(#{tzinfo.full_name} - #{tzinfo.abbreviation} (#{offset}))>"
  end

  defp format_offset(total_offset) do
    offset_hours = div(total_offset, 60 * 60)
    offset_mins = div(rem(total_offset, 60 * 60), 60)
    offset_secs = rem(rem(total_offset, 60 * 60), 60)
    hour = "#{pad_numeric(offset_hours)}"
    min = "#{pad_numeric(offset_mins)}"
    secs = "#{pad_numeric(offset_secs)}"

    cond do
      offset_hours + offset_mins >= 0 -> "+#{hour}:#{min}:#{secs}"
      true -> "#{hour}:#{min}:#{secs}"
    end
  end

  defp pad_numeric(number) when is_integer(number), do: pad_numeric("#{number}")

  defp pad_numeric(<<?-, number_str::binary>>) do
    res = pad_numeric(number_str)
    <<?-, res::binary>>
  end

  defp pad_numeric(number_str) do
    min_width = 2
    len = String.length(number_str)

    cond do
      len < min_width -> String.duplicate("0", min_width - len) <> number_str
      true -> number_str
    end
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
