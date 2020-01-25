defmodule ZoneInfoParserTest do
  use ExUnit.Case, async: true
  alias Timex.Timezone.Local

  @seconds1 :calendar.datetime_to_gregorian_seconds({{2014, 3, 24}, {0, 0, 0}})
  @seconds2 :calendar.datetime_to_gregorian_seconds({{2014, 2, 24}, {0, 0, 0}})

  test "parse_tzfile with TZIF v1" do
    # TZIF Version 1
    chicago = File.cwd!() |> Path.join("test/include/tzif/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read!() |> Local.parse_tzfile(@seconds1)
    assert {:ok, "CST"} = chicago |> File.read!() |> Local.parse_tzfile(@seconds2)

    # TZIF Version 1
    new_york = File.cwd!() |> Path.join("test/include/tzif/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read!() |> Local.parse_tzfile(@seconds1)
    assert {:ok, "EST"} = new_york |> File.read!() |> Local.parse_tzfile(@seconds2)
  end

  test "parse_tzfile with TZIF v2" do
    # TZIF Version 2
    chicago = File.cwd!() |> Path.join("test/include/tzif2/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read!() |> Local.parse_tzfile(@seconds1)
    assert {:ok, "CST"} = chicago |> File.read!() |> Local.parse_tzfile(@seconds2)

    # TZIF Version 2
    new_york = File.cwd!() |> Path.join("test/include/tzif2/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read!() |> Local.parse_tzfile(@seconds1)
    assert {:ok, "EST"} = new_york |> File.read!() |> Local.parse_tzfile(@seconds2)
  end
end
