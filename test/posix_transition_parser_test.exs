defmodule PosixTransitionParserTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.Timezones.Posix
  alias Timex.{PosixTimezone, Timezone}

  test "complete rule names survive parser and public normalization round trips" do
    for zone <- [
          "ABC5DEF,M3.2.0,M11.1.0",
          "<+1030>-10:30<+1100>-11,M10.1.0/2:15,M4.1.0/2:45:30",
          "ABC0DEF,J60/0,300/23:59:59"
        ] do
      assert {:ok, tz, ""} = Posix.parse(zone)
      assert tz.name == zone
      assert Timezone.name_of(zone) == zone
      assert Timezone.name_of(Timezone.name_of(zone)) == zone
      assert {:ok, ^tz, ""} = Posix.parse(tz.name)
    end
  end

  test "names include only consumed rules while parser remainders remain composable" do
    zone = "ABC5DEF,M3.2.0,M11.1.0"
    assert {:ok, %{name: ^zone}, "payload"} = Posix.parse(zone <> "payload")
    assert {:ok, %{name: ^zone}, "payload"} = Posix.parse(zone <> "\npayload")
    refute Timezone.exists?(zone <> "payload")
    refute Timezone.exists?(zone <> "\npayload")
  end

  test "rule times use seconds from midnight and carry across calendar days" do
    for {time, seconds, expected} <- [
          {"0", 0, ~N[2024-03-01 00:00:00]},
          {"2", 7200, ~N[2024-03-01 02:00:00]},
          {"24", 86_400, ~N[2024-03-02 00:00:00]},
          {"24:59:59", 89_999, ~N[2024-03-02 00:59:59]},
          {"-1", -3600, ~N[2024-02-29 23:00:00]},
          {"+26:30", 95_400, ~N[2024-03-02 02:30:00]},
          {"167:59:59", 604_799, ~N[2024-03-07 23:59:59]},
          {"-167:59:59", -604_799, ~N[2024-02-23 00:00:01]}
        ] do
      zone = "ABC0DEF,J60/#{time},J300"
      assert {:ok, %{dst_start: {{:julian, 60}, ^seconds}} = tz, ""} = Posix.parse(zone)
      assert PosixTimezone.dst_start(tz, ~D[2024-01-01]) == expected
      assert tz.name == zone
    end
  end

  test "hour 24 and signed times can carry across year boundaries" do
    for {zone, expected} <- [
          {"ABC0DEF,J365/24,J60", ~N[2025-01-01 00:00:00]},
          {"ABC0DEF,0/-1,J60", ~N[2023-12-31 23:00:00]}
        ] do
      assert {:ok, tz, ""} = Posix.parse(zone)
      assert PosixTimezone.dst_start(tz, ~D[2024-01-01]) == expected
    end
  end

  test "transition hour extensions do not loosen timezone offset ranges" do
    for zone <- [
          "ABC25DEF",
          "ABC0DEF25",
          "ABC0DEF,J60/168,J300",
          "ABC0DEF,J60/-168,J300",
          "ABC0DEF,J60/1:60,J300",
          "ABC0DEF,J60/1:2:60,J300",
          "ABC0DEF,J60/+,J300"
        ] do
      assert {:error, _, _} = Posix.parse(zone)
      refute Timezone.exists?(zone)
    end
  end

  test "legacy Time-valued custom rules still evaluate after parser migration" do
    tz = %PosixTimezone{
      name: "Custom",
      std_abbr: "ABC",
      std_offset: -18_000,
      dst_abbr: "DEF",
      dst_offset: -14_400,
      dst_start: {{:mwd, {3, 2, 0}}, ~T[02:00:00]},
      dst_end: {{:mwd, {11, 1, 0}}, ~T[02:00:00]}
    }

    assert PosixTimezone.dst_start(tz, ~D[2024-01-01]) == ~N[2024-03-10 02:00:00]
    assert {:ok, %{std_offset: 3600}} = PosixTimezone.period_from_utc(tz, ~N[2024-07-01 12:00:00])
  end
end
