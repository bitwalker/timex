defmodule FractionalOffsetRoundtripTest do
  use ExUnit.Case, async: true

  test "parsed fixed offsets preserve fractional hours through shifting and generated-zone conversion" do
    for {offset, seconds} <- [
          {"+08:45", 31_500},
          {"+09:30", 34_200},
          {"-09:30", -34_200},
          {"+05:45", 20_700},
          {"+05:00", 18_000},
          {"+00:00", 0}
        ],
        {format, parser} <- [
          {"{ISO:Extended}", Timex.Parse.DateTime.Tokenizers.Default},
          {"%FT%T%:z", :strftime}
        ] do
      assert {:ok, parsed} = Timex.parse("2017-01-02T02:00:00" <> offset, format, parser)
      assert %DateTime{} = shifted = Timex.shift(parsed, hours: -2)
      assert DateTime.to_naive(shifted) == ~N[2017-01-02 00:00:00]
      assert shifted.utc_offset + shifted.std_offset == seconds
      assert DateTime.diff(shifted, parsed) == -7200

      assert %DateTime{} = utc = Timex.Timezone.convert(shifted, "Etc/UTC")
      assert %DateTime{} = returned = Timex.Timezone.convert(utc, shifted.time_zone)
      assert returned == shifted
      assert Timex.to_datetime(~N[2017-01-02 00:00:00], shifted.time_zone) == shifted
      assert Timex.format!(returned, "{ISO:Extended}") == "2017-01-02T00:00:00" <> offset
    end
  end

  test "numeric offsets accept both signs and optional leading hour zeroes" do
    wall = ~N[2017-01-02 00:00:00]

    for {names, seconds} <- [
          {["+09:30", "+9:30"], 34_200},
          {["-09:30", "-9:30"], -34_200},
          {["+08:45", "+8:45"], 31_500},
          {["+05:45", "+5:45"], 20_700}
        ],
        name <- names do
      assert %DateTime{} = date = Timex.to_datetime(wall, name)
      assert DateTime.to_naive(date) == wall
      assert date.utc_offset + date.std_offset == seconds
    end
  end

  test "fractional Etc/GMT aliases retain the POSIX sign convention through conversion" do
    wall = ~N[2017-01-02 00:00:00]

    for {names, seconds} <- [
          {["Etc/GMT-9:30", "Etc/GMT-09:30"], 34_200},
          {["Etc/GMT+9:30", "Etc/GMT+09:30"], -34_200},
          {["Etc/GMT-8:45", "Etc/GMT-08:45"], 31_500},
          {["Etc/GMT-5:45", "Etc/GMT-05:45"], 20_700},
          {["Etc/GMT-5", "Etc/GMT-05"], 18_000},
          {["Etc/GMT+5", "Etc/GMT+05"], -18_000},
          {["Etc/GMT+0", "Etc/GMT-0", "Etc/GMT+00", "Etc/GMT-00:00"], 0}
        ],
        name <- names do
      assert %DateTime{} = date = Timex.to_datetime(wall, name)
      assert DateTime.to_naive(date) == wall
      assert date.utc_offset + date.std_offset == seconds

      assert %DateTime{} = utc = Timex.Timezone.convert(date, "Etc/UTC")
      assert Timex.Timezone.convert(utc, name) == date
    end
  end

  test "malformed synthetic Etc/GMT aliases fail without partial offset interpretation" do
    for name <- [
          "Etc/GMT+",
          "Etc/GMT-",
          "Etc/GMT+99",
          "Etc/GMT+9:99",
          "Etc/GMT+9:3x",
          "Etc/GMT+9:3",
          "Etc/GMT+09:3",
          "Etc/GMT+9GMT",
          "Etc/GMT+9:30:45",
          "Etc/GMT+9:30junk",
          "Etc/GMT+9:30\n",
          "Etc/GMT--9:30"
        ] do
      assert {:error, :time_zone_not_found} = Timex.Timezone.name_of(name)
      assert {:error, :time_zone_not_found} = Timex.to_datetime(~N[2017-01-02 00:00:00], name)
    end
  end
end
