defmodule Date.Helpers do
  def from(date, time, tz) do
    Date.Gregorian[date: date, time: time, tz: tz]
  end

  def from({date, time}, tz) do
    Date.Gregorian[date: date, time: time, tz: tz]
  end
end


