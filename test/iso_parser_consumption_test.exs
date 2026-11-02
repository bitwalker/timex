defmodule ISOParserConsumptionTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.DateTime.Parsers.ISO8601Extended

  @formats ["{ISO:Extended}", "{ISO:Extended:Z}", "{RFC3339}", "{RFC3339z}"]

  test "all singleton ISO and RFC3339 formats reject unconsumed input" do
    for format <- @formats,
        input <- [
          "2025-03-09T12:34:56Z",
          "2025-03-09T12:34:56.123Z",
          "2025-03-09T12:34:56+05:45",
          "2025-03-09T12:34:56-0930",
          "2025-03-09T12:34:56+03"
        ],
        tail <- ["junk", " ", "\n", "Z", "+01:00", "é"] do
      assert {:error, reason} = Timex.parse(input <> tail, format)
      assert reason =~ "Expected end of input"
    end
  end

  test "complete singleton inputs preserve date values, precision and offsets" do
    for format <- @formats,
        {input, microsecond, offset} <- [
          {"2025-03-09T12:34:56Z", {0, 0}, 0},
          {"2025-03-09T12:34:56.123456789+05:45", {123_456, 6}, 20_700},
          {"2025-03-09T12:34:56.120-0930", {120_000, 3}, -34_200},
          {"2025-03-09T12:34:56+03", {0, 0}, 10_800}
        ] do
      assert {:ok,
              %DateTime{
                year: 2025,
                month: 3,
                day: 9,
                hour: 12,
                minute: 34,
                second: 56,
                microsecond: ^microsecond
              } = date} = Timex.parse(input, format)

      assert date.utc_offset + date.std_offset == offset
    end
  end

  test "partial numeric offsets and empty fractions return parse errors" do
    for format <- @formats,
        tail <- ["+", "-", "+0", "-0", "+05:", "+05:3", "+05:30:", ".Z"] do
      assert {:error, reason} = Timex.parse("2025-03-09T12:34:56" <> tail, format)
      assert is_binary(reason)
    end
  end

  test "the raising API reports trailing input as a parse error" do
    assert_raise Timex.Parse.ParseError, ~r/Expected end of input/, fn ->
      Timex.parse!("2025-03-09T12:34:56Zjunk", "{ISO:Extended}")
    end
  end

  test "lower-level scanners and compound formats can still consume a following literal" do
    input = "2025-03-09T12:34:56Ztail"
    assert {:ok, parts, _count, "tail"} = ISO8601Extended.parse_extended(input)
    assert parts[:year4] == 2025
    assert parts[:zname] == "Etc/UTC"

    assert {:ok, ~U[2025-03-09 12:34:56Z]} =
             Timex.parse(input, "{ISO:Extended}tail")
  end
end
