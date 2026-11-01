defmodule CanonicalTimezoneTest do
  use ExUnit.Case, async: true

  alias Timex.{Timezone, TimezoneInfo}

  test "canonical Etc/GMT names retain POSIX signs and matching period metadata" do
    instant = ~U[2025-01-01 00:00:00Z]

    for {zone, offset, abbreviation} <- [
          {"Etc/GMT-4", 14_400, "+04"},
          {"Etc/GMT+4", -14_400, "-04"},
          {"Etc/GMT-14", 50_400, "+14"},
          {"Etc/GMT+12", -43_200, "-12"},
          {"Etc/GMT", 0, "GMT"},
          {"Etc/GMT0", 0, "GMT"},
          {"Etc/GMT+0", 0, "GMT"},
          {"Etc/GMT-0", 0, "GMT"}
        ] do
      assert Timezone.name_of(zone) == zone
      assert Timezone.name_of(Timezone.name_of(zone)) == zone

      assert %TimezoneInfo{
               full_name: ^zone,
               offset_utc: ^offset,
               offset_std: 0,
               abbreviation: ^abbreviation
             } = Timezone.get(zone, instant)

      expected = DateTime.shift_zone!(instant, zone, Tzdata.TimeZoneDatabase)
      assert Timezone.convert(instant, zone) == expected
      assert DateTime.compare(Timezone.convert(expected, :utc), instant) == :eq
    end
  end

  test "naive conversion and formatting preserve the canonical zone's offset" do
    for {zone, offset} <- [{"Etc/GMT-4", 14_400}, {"Etc/GMT+4", -14_400}] do
      datetime = Timex.to_datetime(~N[2025-01-01 12:00:00], zone)
      assert %DateTime{time_zone: ^zone, hour: 12, utc_offset: ^offset} = datetime
      assert Timex.format!(datetime, "{Zname}") == zone
    end
  end

  test "parsing an accepted canonical name keeps its POSIX offset" do
    assert {:ok, %DateTime{time_zone: "Etc/GMT-4", hour: 12, utc_offset: 14_400}} =
             Timex.parse("2025-01-01 12:00:00 Etc/GMT-4", "{ISOdate} {ISOtime} {Zname}")
  end

  test "setting a canonical zone keeps wall fields and uses its database offset" do
    for {zone, offset} <- [{"Etc/GMT-4", 14_400}, {"Etc/GMT+4", -14_400}] do
      assert %DateTime{time_zone: ^zone, hour: 0, utc_offset: ^offset} =
               Timex.set(~U[2025-01-01 00:00:00Z], timezone: zone)
    end
  end

  test "arithmetic offset shorthands retain their existing sign convention" do
    for {zone, offset} <- [
          {4, 14_400},
          {-4, -14_400},
          {"+04:00", 14_400},
          {"-04:00", -14_400},
          {"GMT+4", 14_400},
          {"GMT-4", -14_400},
          {"Etc/UTC+4", 14_400},
          {"Etc/UTC-4", -14_400}
        ] do
      assert %TimezoneInfo{offset_utc: ^offset, offset_std: 0} =
               Timezone.get(zone, ~U[2025-01-01 00:00:00Z])

      assert %DateTime{utc_offset: ^offset, std_offset: 0} =
               Timezone.convert(~U[2025-01-01 00:00:00Z], zone)
    end
  end
end
