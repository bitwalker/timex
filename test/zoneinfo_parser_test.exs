defmodule ZoneInfoParserTest do
  use ExUnit.Case, async: true
  use Timex

  test "parse_tzfile with TZIF v1" do
    # TZIF Version 1
    chicago = System.cwd |> Path.join("test/include/tzif/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,3,24}, {0,0,0}}))
    assert {:ok, "CST"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,2,24}, {0,0,0}}))

    # TZIF Version 1
    new_york = System.cwd |> Path.join("test/include/tzif/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,3,24}, {0,0,0}}))
    assert {:ok, "EST"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,2,24}, {0,0,0}}))
  end

  test "parse_tzfile with TZIF v2" do
    # TZIF Version 2
    chicago = System.cwd |> Path.join("test/include/tzif2/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,3,24}, {0,0,0}}))
    assert {:ok, "CST"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,2,24}, {0,0,0}}))

    # TZIF Version 2
    new_york = System.cwd |> Path.join("test/include/tzif2/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,3,24}, {0,0,0}}))
    assert {:ok, "EST"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Timex.datetime({{2014,2,24}, {0,0,0}}))
  end
end
