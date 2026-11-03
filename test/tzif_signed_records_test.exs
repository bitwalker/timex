defmodule TzifSignedRecordsTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.ZoneInfo.Parser
  alias Parser.{LeapSecond, TransitionInfo}

  test "version one transition times and UTC offsets retain their signed values" do
    times = [-2_147_483_648, -1, 0, 2_147_483_647]
    leaps = [{-1, -1}]
    binary = header(<<0>>, length(times), length(leaps)) <> block(32, times, -21_600, leaps)
    assert {:ok, zone} = Parser.parse(binary)
    assert Enum.map(zone.transitions, & &1.starts_at) == times
    assert Enum.all?(zone.transitions, &(&1.gmt_offset == -21_600))
    assert zone.leaps == [%LeapSecond{epoch: -1, correction: -1}]
  end

  test "version two preserves 64-bit pre-epoch times and signed leap corrections" do
    times = [-2_208_988_800, -1, 2_147_483_648]
    leaps = [{-2_208_988_800, -1}, {1234, 0}]

    binary =
      header("2", 0, 0) <>
        block(32, [], -18_000, []) <>
        header("2", length(times), length(leaps)) <>
        block(64, times, -18_000, leaps) <> "\nABC5\n"

    assert {:ok, zone} = Parser.parse(binary)
    assert Enum.map(zone.transitions, & &1.starts_at) == times
    assert Enum.all?(zone.transitions, &(&1.gmt_offset == -18_000))

    assert zone.leaps == [
             %LeapSecond{epoch: -2_208_988_800, correction: -1},
             %LeapSecond{epoch: 1234, correction: 0}
           ]
  end

  test "historical transitions in existing timezone fixtures remain before epoch" do
    for directory <- ["tzif", "tzif2"] do
      binary = File.read!(Path.join([__DIR__, "include", directory, "America", "Chicago"]))
      assert {:ok, zone} = Parser.parse(binary)

      assert Enum.any?(zone.transitions, fn
               %TransitionInfo{starts_at: time, gmt_offset: -21_600} when time < 0 -> true
               _ -> false
             end)
    end
  end

  defp header(version, transitions, leaps) do
    "TZif" <>
      version <>
      :binary.copy(<<0>>, 15) <>
      <<0::32, 0::32, leaps::32, transitions::32, 1::32, 4::32>>
  end

  defp block(bits, times, offset, leaps) do
    transitions = for time <- times, into: <<>>, do: <<time::signed-big-integer-size(bits)>>

    leap_records =
      for {time, correction} <- leaps,
          into: <<>>,
          do: <<time::signed-big-integer-size(bits), correction::signed-32>>

    transitions <>
      :binary.copy(<<0>>, length(times)) <>
      <<offset::signed-32, 0, 0>> <> "ABC\0" <> leap_records
  end
end
