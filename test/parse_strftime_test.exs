defmodule DateFormatTest.ParseStrftime do
  use ExUnit.Case, async: true
  use Timex

  test "parse datetime" do
    date = Date.from({{2014, 7, 19}, {14, 20, 34}}, Timezone.get("+7"))
    assert {:ok, ^date} = parse("Sat, 19 Jul 2014 14:20:34 +0700", "%a, %d %b %Y %T %z")
  end

  test "issue #66" do
    date = Date.from({{2015,7,6}, {0,0,0}}, "CEST")
    assert {:ok, ^date} = parse("Mon Jul 06 2015 00:00:00 GMT+0200 (CEST)", "%a %b %d %Y %H:%M:%S %Z%z (%Z)")

    date2 = Date.from({{2015,7,6}, {0,0,0}}, "CEST")
    assert {:ok, ^date2} = parse("Mon Jul 06 2015 00:00:00 GMT +0200 (CEST)", "%a %b %d %Y %H:%M:%S %Z %z (%Z)")
  end

  defp parse(date, fmt) do
    DateFormat.parse(date, fmt, :strftime)
  end
end
