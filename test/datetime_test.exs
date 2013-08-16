# Test interop between Date and Time.
#Code.require_file "test_helper.exs", __DIR__

defmodule DateTimeTest do
  use ExUnit.Case, async: true

  test :epoch do
    assert Date.to_sec(Date.epoch, :zero) == Time.to_sec(Time.epoch)
    assert Date.epoch(:sec) == Time.epoch(:sec)
    assert Date.from(Time.epoch, :timestamp, :zero) == Date.epoch
  end
end
