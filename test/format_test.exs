defmodule DateFormatTest.GeneralFormatting do
  use ExUnit.Case, async: true
  use Timex

  test "from_now/1" do
    ref_date = Timex.to_datetime({{2016,2,8}, {12,0,0}})
    utc_date = Timex.to_datetime({{2016,2,8}, {12,0,1}})
    cst_date = Timex.Timezone.convert(utc_date, "America/Chicago")
    assert Timex.from_now(utc_date, ref_date) == Timex.from_now(cst_date, ref_date)
  end

  test "fractional seconds padding obeys formatting rules" do
    t = Timex.parse!("2017-06-28 20:21:22.000000", "%F %T.%f", :strftime)
    assert {0, 6} = t.microsecond
    assert "000000" = Timex.format!(t, "%f", :strftime)
    assert "000" = Timex.format!(t, "%03f", :strftime)

    t = Timex.to_datetime({2017, 6, 22})
    assert {0, 0} = t.microsecond
    assert "" = Timex.format!(t, "%f", :strftime)
    assert "000" = Timex.format!(t, "%03f", :strftime)
  end
end
