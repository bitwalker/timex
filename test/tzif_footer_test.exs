defmodule TzifFooterTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.ZoneInfo.Parser
  alias Parser.{Rule, Zone}
  alias Timex.Timezone.Local

  test "ordinary footer rules preserve legacy field types and POSIX-west offsets" do
    assert {:ok, %Zone{version: 2, rule: rule}} = parse_footer("CST6CDT,M3.2.0,M11.1.0")

    assert rule == %Rule{
             std_abbr: "CST",
             std_offset: 21_600,
             dst_abbr: "CDT",
             dst_offset: 18_000,
             start_time: {{:mwd, {3, 2, 0}}, ~T[02:00:00.000000]},
             end_time: {{:mwd, {11, 1, 0}}, ~T[02:00:00.000000]}
           }
  end

  test "fixed zones and quoted fractional offsets use validated defaults" do
    for {footer, std, dst, abbreviation, daylight} <- [
          {"UTC0", 0, 0, "UTC", "UTC"},
          {"ABC5", 18_000, 18_000, "ABC", "ABC"},
          {"<+0545>-5:45<+0645>", -20_700, -24_300, "+0545", "+0645"},
          {"ABC-0:30:15DEF-1:45:30", -1815, -6330, "ABC", "DEF"}
        ] do
      assert {:ok,
              %{
                rule: %Rule{
                  std_offset: ^std,
                  dst_offset: ^dst,
                  std_abbr: ^abbreviation,
                  dst_abbr: ^daylight
                }
              }} = parse_footer(footer)
    end
  end

  test "Julian variants retain legacy tags and options at the binary parser boundary" do
    assert {:ok, %{rule: rule}} = parse_footer("ABC0DEF,J60/1,300/3")
    assert rule.start_time == {{:julian, 60, [allow_leap_days: false]}, ~T[01:00:00.000000]}
    assert rule.end_time == {{:julian, 300, [allow_leap_days: true]}, ~T[03:00:00.000000]}
  end

  test "version two hour24 transitions parse without constructing an invalid Time" do
    assert {:ok, %{rule: rule}} = parse_footer("ABC0DEF,J60/24,J300/24:59:59")
    assert rule.start_time == {{:julian, 60, [allow_leap_days: false]}, 86_400}
    assert rule.end_time == {{:julian, 300, [allow_leap_days: false]}, 89_999}
  end

  test "version two rejects signed and extended transition syntax" do
    for time <- ["+0", "-0", "+2", "-1", "25", "167:59:59"] do
      assert {:error, _} = parse_footer("ABC0DEF,J60/#{time},J300", 2)
    end
  end

  test "version three accepts signed extended transition hours and validates their limit" do
    assert {:ok, %Zone{version: 3, rule: rule}} =
             parse_footer("ABC0DEF,J60/-167:59:59,J300/+167:59:59", 3)

    assert rule.start_time == {{:julian, 60, [allow_leap_days: false]}, -604_799}
    assert rule.end_time == {{:julian, 300, [allow_leap_days: false]}, 604_799}

    for time <- ["168", "-168", "1:60", "1:2:60"] do
      assert {:error, _} = parse_footer("ABC0DEF,J60/#{time},J300", 3)
    end
  end

  test "empty framed footers have no future rule" do
    for version <- [2, 3] do
      assert {:ok, %Zone{rule: nil}} = parse_footer("", version)
    end
  end

  test "malformed footer content returns errors rather than accepting a prefix" do
    for footer <- [
          "<abc><def>",
          "<ab:c>0DEF",
          "ABC0DEF,J60junk,J300",
          "ABC0DEF,J60,J300junk",
          "ABC0DEF,M3junk.2.0,M11.1.0",
          "ABC0DEF,M3.2.0",
          "ABC1:60DEF",
          "ABC1:2:60DEF",
          "ABC0DEF+",
          "ABC0DEF,J60,J300\0"
        ] do
      assert {:error, _} = parse_footer(footer)
    end
  end

  test "both footer framing newlines are required, including for an empty footer" do
    for suffix <- ["", "\n", "\nUTC0", "UTC0\n"] do
      assert {:error, _} = Local.parse_tzfile(tzif_body(2) <> suffix)
    end
  end

  test "bytes after the closing newline retain existing outer payload behavior" do
    assert {:ok, %Zone{rule: %Rule{std_abbr: "UTC"}}} =
             Local.parse_tzfile(tzif_body(2) <> "\nUTC0\n" <> <<0, 255, 10>>)
  end

  test "the existing Chicago binary fixture also accepts an hour24 footer" do
    data = File.read!(Path.join(__DIR__, "include/tzif2/America/Chicago"))
    {offset, 1} = data |> :binary.matches("\n") |> Enum.reverse() |> Enum.at(1)
    binary = binary_part(data, 0, offset + 1) <> "ABC0DEF,J60/24,J300\n"
    assert {:ok, %Zone{rule: %Rule{start_time: {_, 86_400}}}} = Local.parse_tzfile(binary)
  end

  defp parse_footer(footer, version \\ 2),
    do: Local.parse_tzfile(tzif_body(version) <> "\n" <> footer <> "\n")

  defp tzif_body(version) do
    header =
      "TZif" <>
        Integer.to_string(version) <>
        :binary.copy(<<0>>, 15) <>
        <<0::32, 0::32, 0::32, 1::32, 1::32, 4::32>>

    type = <<0::signed-32, 0, 0>> <> "ABC\0"
    header <> <<0::signed-32, 0>> <> type <> header <> <<0::signed-64, 0>> <> type
  end
end
