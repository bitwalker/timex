defprotocol Date.Conversions do
  def to_gregorian(date)
end

defrecord DateRec, date: {0,0,0}, time: {0,0,0}, tz: {0,""}

defmodule Date.Utils do
  def from(date, time, tz) do
    DateRec.new(date: date, time: time, tz: tz)
  end

  def from({date, time}, tz) do
    DateRec.new(date: date, time: time, tz: tz)
  end
end

defimpl Date.Conversions, for: DateRec do
  def to_gregorian(date) do
    { date.date, date.time, date.tz }
  end
end
