defmodule DurationParserTests do
  use ExUnit.Case, async: true

  alias Timex.Duration
  alias Timex.Parse.ParseError

  defmodule CustomParser do
    def parse("bare duration"),
      do: %Timex.Duration{megaseconds: 0, seconds: 42, microseconds: 0}

    def parse("wrapped duration"),
      do: {:ok, %Timex.Duration{megaseconds: 0, seconds: 42, microseconds: 0}}

    def parse("binary error"), do: {:error, "invalid custom duration"}
    def parse("structured error"), do: {:error, {:invalid_duration, 42}}
  end

  for input <- ["bare duration", "wrapped duration"] do
    test "custom parser accepts #{input}" do
      expected = %Duration{megaseconds: 0, seconds: 42, microseconds: 0}

      assert Duration.parse(unquote(input), CustomParser) == {:ok, expected}
      assert Duration.parse!(unquote(input), CustomParser) == expected
    end
  end

  test "custom parser binary errors raise ParseError with the original message" do
    assert Duration.parse("binary error", CustomParser) == {:error, "invalid custom duration"}

    assert_raise ParseError, "invalid custom duration", fn ->
      Duration.parse!("binary error", CustomParser)
    end
  end

  test "custom parser structured errors raise ParseError with the inspected reason" do
    assert Duration.parse("structured error", CustomParser) == {:error, {:invalid_duration, 42}}

    assert_raise ParseError, "{:invalid_duration, 42}", fn ->
      Duration.parse!("structured error", CustomParser)
    end
  end

  test "one-argument parsing continues to use ISO8601" do
    expected = %Duration{megaseconds: 0, seconds: 42, microseconds: 0}

    assert Duration.parse("PT42S") == {:ok, expected}
    assert Duration.parse!("PT42S") == expected
  end
end
