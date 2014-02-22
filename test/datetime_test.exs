defmodule DateTimeTests do
  use ExUnit.Case, async: true

  test :epoch do
    assert (Date.epoch |> Date.to_secs(:zero)) == Time.to_secs(Time.epoch)
    assert Date.epoch(:secs) == Time.epoch(:secs)
    assert Date.from(Time.epoch, :timestamp, :zero) == Date.epoch
  end
end
