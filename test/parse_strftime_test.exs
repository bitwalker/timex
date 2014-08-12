defmodule DateFormatTest.ParseStrftime do
  use ExUnit.Case, async: true
  use Timex

  test :parse_datetime do
    date = Date.from({{2014, 7, 19}, {14, 20, 34}}, Timezone.get("+7"))
    assert {:ok, ^date} = parse("Sat, 19 Jul 2014 14:20:34 +0700", "%a, %d %b %Y %T %z")
  end

  defp parse(date, fmt) do
    DateFormat.parse(date, fmt, :strftime)
  end
end

