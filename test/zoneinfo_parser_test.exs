defmodule ZoneInfoParserTest do
  use ExUnit.Case, async: true
  alias Timex.Timezone.Local
  alias Timex.Parse.ZoneInfo.Parser.Zone
  alias Timex.Parse.ZoneInfo.Parser.TransitionInfo

  @epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  @seconds1 :calendar.datetime_to_gregorian_seconds({{2021, 3, 15}, {0, 0, 0}}) - @epoch
  @seconds2 :calendar.datetime_to_gregorian_seconds({{2021, 3, 13}, {0, 0, 0}}) - @epoch

  test "parse_tzfile with TZIF v1" do
    # TZIF Version 1
    chicago = File.cwd!() |> Path.join("test/include/tzif/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds1)
    assert {:ok, "CST"} = chicago |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds2)

    # TZIF Version 1
    new_york = File.cwd!() |> Path.join("test/include/tzif/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds1)
    assert {:ok, "EST"} = new_york |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds2)
  end

  test "parse_tzfile with TZIF v2" do
    # TZIF Version 2
    chicago = File.cwd!() |> Path.join("test/include/tzif2/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds1)
    assert {:ok, "CST"} = chicago |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds2)

    # TZIF Version 2
    new_york = File.cwd!() |> Path.join("test/include/tzif2/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds1)
    assert {:ok, "EST"} = new_york |> File.read!() |> Local.parse_tzfile() |> get_abbr(@seconds2)
  end

  defp get_abbr({:ok, %Zone{transitions: transitions}}, epoch) do
    transition =
      transitions
      |> Enum.reduce_while(nil, fn %TransitionInfo{starts_at: starts} = txinfo, acc ->
        cond do
          starts > epoch ->
            {:halt, acc}

          starts == epoch ->
            {:halt, txinfo}

          :else ->
            {:cont, txinfo}
        end
      end)

    case transition do
      nil ->
        nil

      %TransitionInfo{abbreviation: abbr} ->
        {:ok, abbr}
    end
  end

  defp get_abbr(other, _), do: other
end
