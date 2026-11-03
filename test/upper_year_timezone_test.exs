defmodule UpperYearTimezoneTest do
  use ExUnit.Case, async: true

  test "the last supported year's wall times resolve without expanding outside the calendar range" do
    wall = ~N[9999-12-31 23:59:59]

    for {zone, offset, expected_utc} <- [
          {"Europe/Amsterdam", 3600, ~U[9999-12-31 22:59:59Z]},
          {"Europe/Athens", 7200, ~U[9999-12-31 21:59:59Z]},
          {"Europe/Istanbul", 10_800, ~U[9999-12-31 20:59:59Z]},
          {"Etc/UTC", 0, ~U[9999-12-31 23:59:59Z]}
        ] do
      assert %DateTime{} = date = Timex.to_datetime(wall, zone)
      assert DateTime.to_naive(date) == wall
      assert date.utc_offset + date.std_offset == offset
      assert Timex.Timezone.convert(date, "Etc/UTC") == expected_utc
      assert Timex.Timezone.convert(expected_utc, zone) == date

      assert {:ok, ^date} = DateTime.from_naive(wall, zone, Timex.Timezone.Database)
      assert DateTime.from_naive!(wall, zone, Timex.Timezone.Database) == date
    end
  end

  test "UTC database lookups outside supported ISO years return timezone errors" do
    for iso_days <- [{-1, {0, 86_400}}, {3_652_425, {0, 86_400}}],
        zone <- ["Europe/Amsterdam", "Etc/UTC", "ABC0", "Etc/UTC+2"] do
      assert {:error, :time_zone_not_found} =
               Timex.Timezone.Database.time_zone_period_from_utc_iso_days(iso_days, zone)
    end
  end
end
