defmodule TimeFormatHumanizedTest do
  use ExUnit.Case, async: true
  doctest Timex.Format.Time.Formatters.Humanized

  test "format" do
  	assert Timex.Format.Time.Formatters.Humanized.format({0, -65, 0}) == "1 minutes, 5 seconds"
  	assert Timex.Format.Time.Formatters.Humanized.format({0, -65, 30}) == "1 minutes, 4 seconds, 30 microseconds"
  end

end
