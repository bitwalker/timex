defimpl Timex.Convertable, for: Timex.Date do
  alias Timex.Date

  def to_gregorian(%Date{:year => y, :month => m, :day => d}) do
    {{y, m, d}, {0, 0, 0}, {0, "GMT"}}
  end

  def to_julian(%Date{:year => y, :month => m, :day => d}) do
    Timex.Calendar.Julian.julian_date(y, m, d)
  end

  def to_gregorian_seconds(%Date{} = date), do: Date.to_seconds(date, :zero)

  def to_erlang_datetime(%Date{:year => y, :month => m, :day => d}) do
    {{y, m, d}, {0, 0, 0}}
  end

  def to_date(%Date{} = date),      do: date
  def to_datetime(%Date{} = date),  do: Date.to_datetime(date)
  def to_unix(%Date{} = date),      do: Date.to_seconds(date, :epoch)
  def to_timestamp(%Date{} = date), do: Date.to_timestamp(date, :epoch)
end
