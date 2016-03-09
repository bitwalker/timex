defimpl Timex.Convertable, for: Timex.DateTime do
  alias Timex.Date
  alias Timex.DateTime
  alias Timex.TimezoneInfo

  def to_gregorian(%DateTime{
      :year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec,
      :timezone => %TimezoneInfo{:abbreviation => abbrev}} = datetime) do
    # Use the correct abbreviation depending on whether we're in DST or not
    offset =  Timex.Timezone.diff(datetime, %TimezoneInfo{})
    case rem(offset, 60) do
      0 -> {{y, m, d}, {h, min, sec}, {div(offset, 60), abbrev}}
      _ -> {{y, m, d}, {h, min, sec}, {offset / 60, abbrev}}
    end
  end

  def to_julian(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}) do
    Timex.Calendar.Julian.julian_date({{y,m,d}, {h,min,sec}})
  end

  def to_gregorian_seconds(%DateTime{} = date), do: DateTime.to_seconds(date, :zero)

  def to_erlang_datetime(%DateTime{:year => y, :month => m, :day => d, :hour => h, :minute => min, :second => sec}) do
    {{y, m, d}, {h, min, sec}}
  end

  def to_date(%DateTime{} = datetime),      do: Date.from(datetime)
  def to_datetime(%DateTime{} = datetime),  do: datetime
  def to_unix(%DateTime{} = datetime),      do: DateTime.to_seconds(datetime, :epoch)
  def to_timestamp(%DateTime{} = datetime), do: DateTime.to_timestamp(datetime, :epoch)
end
