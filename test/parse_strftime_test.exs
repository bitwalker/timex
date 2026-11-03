defmodule DateFormatTest.ParseStrftime do
  use ExUnit.Case, async: true
  use Timex

  test "parse datetime" do
    date = Timex.to_datetime({{2014, 7, 19}, {14, 20, 34}}, "Etc/UTC+7")
    assert {:ok, ^date} = parse("Sat, 19 Jul 2014 14:20:34 +0700", "%a, %d %b %Y %T %z")
  end

  test "issue #215" do
    assert {:ok, _date} = parse("14-Dec-00", "%e-%b-%y")
  end

  test "month names accept all letter cases while preserving directive distinctions" do
    for name <- ["March", "march", "MARCH", "mArCh"] do
      assert {:ok, ~N[2024-03-18 00:00:00]} = parse("18 #{name} 2024", "%d %B %Y")
    end

    for name <- ["Mar", "mar", "MAR", "mAr"], directive <- ["%b", "%h"] do
      assert {:ok, ~N[2024-03-18 00:00:00]} = parse("18 #{name} 2024", "%d #{directive} %Y")
      assert {:error, _} = parse("18 #{name} 2024", "%d %B %Y")
    end

    assert {:error, _} = parse("18 MARCH 2024", "%d %b %Y")
    assert {:error, _} = parse("18 Notamonth 2024", "%d %B %Y")
    assert {:error, _} = parse("18 Xxx 2024", "%d %b %Y")
  end

  test "localized month names use Unicode case conversion and restore the process locale" do
    original_locale = Timex.Translator.current_locale()

    for {locale, directive, names, expected} <- [
          {"de", "%B", ["März", "märz", "MÄRZ", "mÄrZ"], ~N[2024-03-18 00:00:00]},
          {"fr", "%b", ["août", "AOÛT", "AoÛt"], ~N[2024-08-18 00:00:00]}
        ] do
      Gettext.with_locale(Timex.Gettext, locale, fn ->
        for name <- names do
          assert {:ok, ^expected} = parse("18 #{name} 2024", "%d #{directive} %Y")
        end

        assert {:ok, ~N[2024-03-18 00:00:00]} = parse("18 MARCH 2024", "%d %B %Y")
        assert {:ok, ~N[2024-03-18 00:00:00]} = parse("18 MAR 2024", "%d %b %Y")
      end)

      assert Timex.Translator.current_locale() == original_locale
    end
  end

  test "issue #319 - should parse microseconds even if 0" do
    assert {:ok, %NaiveDateTime{microsecond: {0, 6}}} =
             parse("2017-06-15T12:42:20.000000", "%FT%T.%f")
  end

  test "parse format with microseconds" do
    date = Timex.to_naive_datetime({{2015, 7, 13}, {14, 1, 21}})
    date = %{date | :microsecond => {53021, 6}}
    assert {:ok, ^date} = parse("20150713 14:01:21.053021", "%Y%m%d %H:%M:%S.%f")

    assert {:ok, ~N[2017-04-05 15:34:37.348]} =
             parse("2017-04-05 15:34:37.348", "%Y-%m-%d %H:%M:%S.%f")
  end

  test "parse format with milliseconds" do
    date = Timex.to_naive_datetime({{2015, 7, 13}, {14, 1, 21}})
    date = %{date | :microsecond => {38000, 3}}
    assert {:ok, ^date} = parse("20150713 14:01:21.038", "%Y%m%d %H:%M:%S.%L")
  end

  test "issue #356 - millisecond parsing" do
    {:ok, ms1} = parse("000", "%L")
    {:ok, ms2} = parse("010", "%L")
    {:ok, ms3} = parse("100", "%L")

    assert elem(ms1.microsecond, 0) == 0
    assert elem(ms2.microsecond, 0) == 10 * 1_000
    assert elem(ms3.microsecond, 0) == 100 * 1_000
  end

  test "issue #446 - strftime_iso_kitchen should not discard dates" do
    input_datetime_str = "July 23, 2018 05:34:04 PM PST8PDT"

    expected_datetime = %DateTime{
      calendar: Calendar.ISO,
      day: 23,
      hour: 17,
      microsecond: {0, 0},
      minute: 34,
      month: 7,
      second: 4,
      std_offset: 3600,
      time_zone: "PST8PDT",
      utc_offset: -28800,
      year: 2018,
      zone_abbr: "PDT"
    }

    assert Timex.parse!(input_datetime_str, "%B %d, %Y %r %Z", :strftime) == expected_datetime
  end

  defp parse(date, fmt) do
    Timex.parse(date, fmt, :strftime)
  end
end
