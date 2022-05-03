defmodule DateFormatTest.LFormatStrftime do
  use ExUnit.Case, async: true
  use Timex

  @aug182013_am Timex.to_datetime({{2013, 8, 18}, {11, 00, 5}})
  @aug182013_pm Timex.to_datetime({{2013, 8, 18}, {12, 30, 5}})

  describe "locale tr" do
    test "lformat %P" do
      formatter = Timex.Format.DateTime.Formatters.Strftime

      assert {:ok, "öö"} = formatter.lformat(@aug182013_am, "%P", "tr")
      assert {:ok, "ÖÖ"} = formatter.lformat(@aug182013_am, "%p", "tr")
      assert {:ok, "ös"} = formatter.lformat(@aug182013_pm, "%P", "tr")
      assert {:ok, "ÖS"} = formatter.lformat(@aug182013_pm, "%p", "tr")
    end
  end
end
