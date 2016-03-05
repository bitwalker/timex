defmodule HelpersTests do
  use ExUnit.Case, async: true
  doctest Timex.Helpers

  alias Timex.Helpers

  test "days_in_month with invalid year and month" do
    assert {:error, :invalid_year} = Helpers.days_in_month(-1, 3)
    assert {:error, :invalid_month} = Helpers.days_in_month(1, -3)
    assert {:error, :invalid_year_and_month} = Helpers.days_in_month(-1, -3)
  end

  test "normalize_date_tuple" do
    assert {1, 1, 31} = Helpers.normalize_date_tuple({1, 1, 32})
  end

  test "round_month" do
    assert 2 = Helpers.round_month(14)
    assert 12 = Helpers.round_month(12)
    assert 1 = Helpers.round_month(1)
    assert 3 = Helpers.round_month(3)
    assert 11 = Helpers.round_month(-1)
  end
end
