defmodule TzifVersionFourTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.ZoneInfo.Parser
  alias Parser.{LeapSecond, Rule, Zone}

  test "version four parses extended footer transitions" do
    binary = file("ABC0DEF,J60/-1,J300/26")
    assert {:ok, %Zone{version: 4, rule: %Rule{} = rule}} = Parser.parse(binary)
    assert rule.start_time == {{:julian, 60, [allow_leap_days: false]}, -3600}
    assert rule.end_time == {{:julian, 300, [allow_leap_days: false]}, 93_600}
  end

  test "version four preserves truncated leap records and expiration marker" do
    leaps = [{1_483_228_826, 27}, {1_719_532_827, 27}]
    binary = file("UTC0", leaps)
    assert {:ok, %Zone{version: 4, leaps: parsed}} = Parser.parse(binary)

    assert parsed == [
             %LeapSecond{epoch: 1_483_228_826, correction: 27},
             %LeapSecond{epoch: 1_719_532_827, correction: 27}
           ]
  end

  test "version four shares complete footer validation and empty-footer behavior" do
    assert {:ok, %Zone{version: 4, rule: nil}} = Parser.parse(file(""))

    for footer <- ["ABC0DEF,J60/168,J300", "<abc><def>", "ABC0DEF,J60,J300junk"] do
      assert {:error, _} = Parser.parse(file(footer))
    end
  end

  test "the second header must match the declared file version" do
    binary = header("4", 0) <> block(32, []) <> header("3", 0) <> block(64, []) <> "\nUTC0\n"
    assert {:error, {:invalid_version_header, 4}} = Parser.parse(binary)
  end

  defp file(footer, leaps \\ []) do
    header("4", 0) <>
      block(32, []) <>
      header("4", length(leaps)) <>
      block(64, leaps) <> "\n" <> footer <> "\n"
  end

  defp header(version, leap_count) do
    "TZif" <>
      version <>
      :binary.copy(<<0>>, 15) <>
      <<0::32, 0::32, leap_count::32, 0::32, 1::32, 4::32>>
  end

  defp block(bits, leaps) do
    records =
      for {time, correction} <- leaps,
          into: <<>>,
          do: <<time::signed-big-integer-size(bits), correction::signed-32>>

    <<0::signed-32, 0, 0>> <> "ABC\0" <> records
  end
end
