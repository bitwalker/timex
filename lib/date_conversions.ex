defrecord Date.Gregorian, [:date, :time, :tz]

defprotocol Date.Conversions do
  def to_gregorian(date)
end

defimpl Date.Conversions, for: Date.Gregorian do
  def to_gregorian(Date.Gregorian[date: date, time: time, tz: tz]) do
    { date, time, tz }
  end
end