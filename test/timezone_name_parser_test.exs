defmodule TimezoneNameParserTest do
  use ExUnit.Case, async: true

  alias Timex.Parse.DateTime.Tokenizers.Default
  alias Timex.Parse.DateTime.Tokenizers.Directive

  defmodule WeightedTokenizer do
    use Timex.Parse.DateTime.Tokenizer

    def tokenize(format) do
      with {:ok, directives} <- Default.tokenize(format) do
        {:ok,
         Enum.map(directives, fn
           %Directive{type: :year4} = directive ->
             %{directive | weight: 20}

           %Directive{type: :year2} = directive ->
             %{directive | weight: 10}

           %Directive{type: :zname, parser: parser} = directive ->
             parser =
               Combine.Parsers.Base.map(parser, fn [zname: name] ->
                 [zname: String.replace(name, "UTC_ALIAS", "Etc/UTC")]
               end)

             %{directive | parser: parser, weight: 30}

           directive ->
             directive
         end)}
      end
    end

    def apply(_, _, _), do: :unrecognized
  end

  defmodule IgnoredZoneTokenizer do
    use Timex.Parse.DateTime.Tokenizer

    def tokenize(format) do
      with {:ok, directives} <- Default.tokenize(format) do
        {:ok,
         Enum.map(directives, fn
           %Directive{type: :zname, parser: parser} = directive ->
             parser = fn state ->
               parsed = parser.(state)
               %{parsed | results: state.results}
             end

             %{directive | parser: parser}

           directive ->
             directive
         end)}
      end
    end

    def apply(_, _, _), do: :unrecognized
  end

  defmodule StrictAliasTokenizer do
    use Timex.Parse.DateTime.Tokenizer

    def tokenize(format) do
      with {:ok, directives} <- Default.tokenize(format) do
        {:ok,
         Enum.map(directives, fn
           %Directive{type: :zname, parser: parser} = directive ->
             parser =
               Combine.Parsers.Base.map(parser, fn
                 [zname: "UTC_ALIAS"] -> [zname: "Etc/UTC"]
                 _ -> {:error, "unknown alias"}
               end)

             %{directive | parser: parser}

           directive ->
             directive
         end)}
      end
    end

    def apply(_, _, _), do: :unrecognized
  end

  defmodule CustomSeparatorTokenizer do
    use Timex.Parse.DateTime.Tokenizer

    def tokenize(format) do
      with {:ok, directives} <- Default.tokenize(format) do
        {:ok,
         Enum.map(directives, fn
           %Directive{type: :literal, value: "+"} = directive ->
             %{directive | parser: Combine.Parsers.Text.char("|")}

           directive ->
             directive
         end)}
      end
    end

    def apply(_, _, _), do: :unrecognized
  end

  test "plus-bearing canonical names parse with their database offsets in both formats" do
    for {zone, offset} <- [{"Etc/GMT+4", -14_400}, {"Etc/GMT-4", 14_400}] do
      text = "2025-01-01 12:00:00 " <> zone

      for result <- [
            Timex.parse(text, "{ISOdate} {ISOtime} {Zname}"),
            Timex.parse(text, "%F %T %Z", :strftime)
          ] do
        assert {:ok, %DateTime{time_zone: ^zone, hour: 12, utc_offset: ^offset}} = result
      end
    end
  end

  test "synthetic offsets with plus signs and colons parse through timezone-name fields" do
    assert {:ok, %DateTime{time_zone: "Etc/UTC+4:30", utc_offset: 16_200}} =
             Timex.parse("2025-01-01 12:00:00 Etc/UTC+4:30", "{ISOdate} {ISOtime} {Zname}")
  end

  test "formatted canonical names round trip through the same format" do
    for zone <- ["Etc/GMT+4", "Etc/GMT-4"] do
      date = DateTime.shift_zone!(~U[2025-01-01 12:00:00Z], zone, Tzdata.TimeZoneDatabase)
      format = "{ISOdate} {ISOtime} {Zname}+"
      assert {:ok, ^date} = Timex.parse(Timex.format!(date, format), format)
    end
  end

  test "literal plus separators retain their previous interpretation" do
    assert {:ok, ~U[2025-01-01 12:00:00Z]} =
             Timex.parse("2025-01-01 12:00:00 UTC+", "{ISOdate} {ISOtime} {Zname}+")

    assert {:ok, ~U[2025-01-01 12:00:00Z]} =
             Timex.parse("2025-01-01 UTC+12:00:00", "{ISOdate} {Zname}+{ISOtime}")

    assert {:ok, ~U[2025-01-01 12:00:00Z]} =
             Timex.parse("2025-01-01 UTC+12:00:00", "%F %Z+%T", :strftime)
  end

  test "separators inside a name do not hide the actual field boundary" do
    for {zone, separator, offset} <- [
          {"Etc/GMT+4", "+", -14_400},
          {"Etc/GMT-4", "-", 14_400},
          {"Etc/UTC+4:30", ":", 16_200}
        ] do
      text = "2025-01-01 " <> zone <> separator <> "12"
      format = "{ISOdate} {Zname}" <> separator <> "{h24}"
      assert {:ok, %DateTime{hour: 12, utc_offset: ^offset}} = Timex.parse(text, format)
    end
  end

  test "adjacent numeric fields use the longest recognized zone that fits the suffix" do
    assert {:ok, ~U[2025-01-01 12:00:00Z]} =
             Timex.parse("2025-01-01 UTC12", "{ISOdate} {Zname}{h24}")

    assert {:ok, %DateTime{time_zone: "Etc/GMT+4", hour: 12, utc_offset: -14_400}} =
             Timex.parse("2025-01-01 Etc/GMT+412", "{ISOdate} {Zname}{0h24}")
  end

  test "multiple timezone-name fields retain token order" do
    assert {:ok, %DateTime{time_zone: "Etc/GMT+4", hour: 8, utc_offset: -14_400}} =
             Timex.parse("2025-01-01 UTC+Etc/GMT+4+12", "{ISOdate} {Zname}+{Zname}+{h24}")
  end

  test "abbreviation fields share the timezone-name boundary rules" do
    assert {:ok, %DateTime{time_zone: "Etc/GMT+4", hour: 12, utc_offset: -14_400}} =
             Timex.parse("2025-01-01 Etc/GMT+4+12", "{ISOdate} {Zabbr}+{h24}")
  end

  test "compound timezone formats retain literal plus delimiters" do
    assert {:ok, ~U[2025-01-01 12:00:00Z]} =
             Timex.parse("Wed, 01 Jan 2025 12:00:00 UTC+", "{RFC1123}+")

    assert {:ok, %DateTime{time_zone: "Etc/GMT+4", utc_offset: -14_400}} =
             Timex.parse("Wed, 01 Jan 2025 12:00:00 Etc/GMT+4+", "{RFC1123}+")
  end

  test "custom parsers and directive weights survive timezone boundary selection" do
    assert {:ok, %DateTime{year: 2025, time_zone: "Etc/UTC+4", hour: 12, utc_offset: 14_400}} =
             Timex.parse(
               "2025-01-01 24 UTC_ALIAS+4+12",
               "{YYYY}-{0M}-{0D} {YY} {Zname}+{h24}",
               WeightedTokenizer
             )
  end

  test "custom timezone directives may consume input without producing a token" do
    assert {:ok, ~N[2025-01-01 12:00:00]} =
             Timex.parse(
               "2025-01-01 discarded+12",
               "{ISOdate} {Zname}+{h24}",
               IgnoredZoneTokenizer
             )
  end

  test "validating custom timezone parsers can retry a rejected greedy match" do
    assert {:ok, ~U[2025-01-01 12:00:00Z]} =
             Timex.parse(
               "2025-01-01 UTC_ALIAS+12",
               "{ISOdate} {Zname}+{h24}",
               StrictAliasTokenizer
             )
  end

  test "custom separator parsers retain authority over literal metadata" do
    assert {:ok, %DateTime{time_zone: "Etc/GMT+4", hour: 12, utc_offset: -14_400}} =
             Timex.parse(
               "2025-01-01 Etc/GMT+4|12",
               "{ISOdate} {Zname}+{h24}",
               CustomSeparatorTokenizer
             )
  end

  @tag timeout: 5000
  test "a missing literal separator does not reparse every prefix of a long name" do
    input = "2025-01-01 " <> String.duplicate("X", 200_000) <> "!"
    assert {:error, _} = Timex.parse(input, "{ISOdate} {Zname}+")
  end

  @tag timeout: 5000
  test "repeated literal characters do not trigger quadratic timezone retries" do
    input = "2025-01-01 " <> String.duplicate("X+", 100_000) <> "!"
    assert {:error, _} = Timex.parse(input, "{ISOdate} {Zname}+")
  end

  @tag timeout: 5000
  test "an impossible adjacent numeric suffix does not reparse every timezone prefix" do
    input = "2025-01-01 " <> String.duplicate("X", 200_000) <> "!"
    assert {:error, _} = Timex.parse(input, "{ISOdate} {Zname}{h24}")
  end

  test "unknown zones and malformed suffixes remain errors" do
    assert {:error, _} = Timex.parse("2025-01-01 No/Such_Zone", "{ISOdate} {Zname}")
    assert {:error, _} = Timex.parse("2025-01-01 No/Such_Zone+12", "{ISOdate} {Zname}+{h24}")
    assert {:error, _} = Timex.parse("2025-01-01 Etc/GMT+4+bad", "{ISOdate} {Zname}+{h24}")
    assert {:error, _} = Timex.parse("2025-01-01 12:00:00 +", "{ISOdate} {ISOtime} {Zname}+")
  end
end
