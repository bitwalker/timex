defprotocol Date.Convert do
  def to_gregorian(date)
  def to_erlang_datetime(date)
end

defimpl Date.Convert, for: DateTime do
  def to_gregorian(DateTime[year: y, month: m, day: d, hour: h, minute: min, second: sec, timezone: TimezoneInfo[standard_abbreviation: abbrev, gmt_offset_std: offset]]) do
    { {y, m, d}, {h, min, sec}, {offset / 60, abbrev} }
  end
  def to_erlang_datetime(DateTime[year: y, month: m, day: d, hour: h, minute: min, second: sec]) do
    { {y, m, d}, {h, min, sec} }
  end
end