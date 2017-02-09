defmodule DateFormatTest.GeneralFormatting do
  use ExUnit.Case, async: true
  use Timex

  test "from_now/1" do
    ref_date = Timex.to_datetime({{2016,2,8}, {12,0,0}})
    utc_date = Timex.to_datetime({{2016,2,8}, {12,0,1}})
    cst_date = Timex.Timezone.convert(utc_date, "America/Chicago")
    assert Timex.from_now(utc_date, ref_date) == Timex.from_now(cst_date, ref_date)
  end
end
