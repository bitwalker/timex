defmodule PosixTimezoneNameParserTest do
  use ExUnit.Case, async: true

  test "formatted explicit POSIX names round trip in both datetime syntaxes" do
    for zone <- [
          "ABC5DEF,M3.2.0,M11.1.0",
          "<+1030>-10:30<+1100>-11,M10.1.0/2:15,M4.1.0/2:45:30",
          "ABC0DEF,J60/-1,J300/24:59:59"
        ],
        {format, formatter, tokenizer} <- [
          {"{ISOdate} {h24}:{m}:{s} {Zname}", Timex.Format.DateTime.Formatters.Default,
           Timex.Parse.DateTime.Tokenizers.Default},
          {"%F %T %Z", :strftime, :strftime}
        ] do
      date = Timex.to_datetime(~N[2024-07-01 12:00:00], zone)
      text = Timex.format!(date, format, formatter)
      assert {:ok, ^date} = Timex.parse(text, format, tokenizer)
    end
  end

  test "complete POSIX names preserve subsequent comma, period and angle delimiters" do
    zone = "ABC5DEF,M3.2.0,M11.1.0"

    for separator <- [",", ".", ">", "<", "+"],
        {format, tokenizer} <- [
          {"{0M}-{0D} {h24}:{m}:{s} {Zname}" <> separator <> "{YYYY}",
           Timex.Parse.DateTime.Tokenizers.Default},
          {"%m-%d %T %Z" <> separator <> "%Y", :strftime}
        ] do
      text = "07-01 12:00:00 " <> zone <> separator <> "2024"
      assert {:ok, date} = Timex.parse(text, format, tokenizer)
      assert date.time_zone == zone
      assert {date.year, date.month, date.day} == {2024, 7, 1}
      assert {date.hour, date.minute, date.second} == {12, 0, 0}
      assert date.utc_offset + date.std_offset == -14_400
    end
  end

  test "name lexing does not permit malformed POSIX rules or discard trailing data" do
    for zone <- [
          "ABC5DEF,M3.2.0",
          "ABC5DEF,M3.2.0,M11.1.0junk",
          "<ab:c>0",
          "ABC0DEF,J60/168,J300"
        ] do
      assert {:error, _} =
               Timex.parse("2024-07-01 12:00:00 " <> zone, "{ISOdate} {h24}:{m}:{s} {Zname}")
    end
  end
end
