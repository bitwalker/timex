# WIP. Nothing interesing here

defrecord TimeDelta.Struct, days: 0, seconds: 0, micro: 0

defmodule TimeDelta do
  @moduledoc "Time delta construction"

  def from_value(value, :microseconds) do
    normalize TimeDelta.Struct.new([micro: value])
  end

  def from_value(value, :milliseconds) do
    normalize TimeDelta.Struct.new([micro: value * 1000])
  end

  def from_value(value, :seconds) do
    normalize TimeDelta.Struct.new([seconds: value])
  end

  def from_value(value, :minutes) do
    normalize TimeDelta.Struct.new([seconds: value * 60])
  end

  def from_value(value, :hours) do
    normalize TimeDelta.Struct.new([seconds: value * 3600])
  end

  def from_value(value, :days) do
    normalize TimeDelta.Struct.new([days: value])
  end

  def from_value(value, :weeks) do
    normalize TimeDelta.Struct.new([days: value * 7])
  end

  def add(td1, td2) do
    td = td1.update_days(fn(val) -> val + td2.days end)
    td = td.update_seconds(fn(val) -> val + td2.seconds end)
    td = td.update_micro(fn(val) -> val + td2.micro end)
    normalize td
  end

  def from_values(pairs) do
    Enum.reduce pairs, TimeDelta.Struct.new, fn({val, type}, acc) ->
      add(acc, TimeDelta.from_value(val, type))
    end
  end

  defp normalize(record) do
    if record.micro >= 1000000 do
      new_micro = rem record.micro, 1000000
      new_seconds = record.seconds + div record.micro, 1000000
    else
      new_micro = record.micro
      new_seconds = record.seconds
    end

    if new_seconds >= 3600 * 24 do
      new_days = record.days + div new_seconds, 3600 * 24
      new_seconds = rem new_seconds, 3600 * 24
    else
      new_days = record.days
    end

    TimeDelta.Struct.new [days: new_days, seconds: new_seconds, micro: new_micro]
  end
end

