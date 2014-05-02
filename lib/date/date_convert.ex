defprotocol Timex.Date.Convert do
  def to_gregorian(date)
  def to_erlang_datetime(date)
end

defimpl Timex.Date.Convert, for: Timex.DateTime do
  alias Timex.DateTime,     as: DateTime
  alias Timex.Timezone,     as: Timezone
  alias Timex.TimezoneInfo, as: TimezoneInfo
  
  def to_gregorian(
    %DateTime{
      :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec,
      :timezone => %TimezoneInfo{:standard_abbreviation => abbrev, :dst_abbreviation => dst_abbrev, :gmt_offset_std => std, :gmt_offset_dst => dst}
    } = date) do
    # Use the correct abbreviation depending on whether we're in DST or not
    if Timezone.Dst.is_dst?(date) do
      { {y, m, d}, {h, min, sec}, {(std + dst) / 60, dst_abbrev} }
    else
      { {y, m, d}, {h, min, sec}, {std / 60, abbrev} }
    end
  end
  def to_erlang_datetime(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}) do
    { {y, m, d}, {h, min, sec} }
  end
end