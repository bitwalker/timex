# Test interop between Date and Time.

defmodule DateTimeTest do
  use ExUnit.Case, async: true

  test :epoch do
    assert Date.to_sec(Date.epoch, 0) == Time.to_sec(Time.epoch)
    assert Date.epoch(:sec) == Time.epoch(:sec)
    assert Date.from(Time.epoch, :timestamp, 0) == Date.epoch
  end
end
