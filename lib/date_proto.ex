defprotocol Date.Conversions do
  def to_gregorian(date)
end

###

defrecord Date.Gregorian, [:date, :time, :tz]

defmodule Date.Helpers do
  def from(date, time, tz) do
    Date.Gregorian[date: date, time: time, tz: tz]
  end

  def from({date, time}, tz) do
    Date.Gregorian[date: date, time: time, tz: tz]
  end
end

###

defimpl Date.Conversions, for: Date.Gregorian do
  def to_gregorian(Date.Gregorian[date: date, time: time, tz: tz]) do
    { date, time, tz }
  end
end
