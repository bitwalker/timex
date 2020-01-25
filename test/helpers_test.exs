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

  describe ".iso_day_to_date_tuple" do
    test "last day of year is beginning of iso week" do
      assert {2007, 12, 31} === Helpers.iso_day_to_date_tuple(2007, 365)
    end

    test "last day of leap year is beginning of iso week" do
      assert {2040, 12, 31} === Helpers.iso_day_to_date_tuple(2040, 366)
    end

    test "last day of year is iso day 365 and end of iso week" do
      assert {2027, 12, 31} === Helpers.iso_day_to_date_tuple(2027, 365)
    end

    test "last day of leap year is iso day 366 and end of iso week" do
      assert {2028, 12, 31} === Helpers.iso_day_to_date_tuple(2028, 366)
    end

    test "first day of year is iso day 1 and beginning of iso week" do
      assert {2001, 1, 1} === Helpers.iso_day_to_date_tuple(2001, 1)
    end

    test "first day of leap year is iso day 1 and beginning of iso week" do
      assert {2024, 1, 1} === Helpers.iso_day_to_date_tuple(2024, 1)
    end

    test "first day of year is iso day 1 and end of iso week" do
      assert {2023, 1, 1} === Helpers.iso_day_to_date_tuple(2023, 1)
    end

    test "first day of leap year is iso day 1 and end of iso week" do
      assert {2012, 1, 1} === Helpers.iso_day_to_date_tuple(2012, 1)
    end

    test "first day of iso week is leap day" do
      assert {2016, 2, 29} === Helpers.iso_day_to_date_tuple(2016, 60)
    end

    test "last day of iso week is leap day" do
      assert {2032, 2, 29} === Helpers.iso_day_to_date_tuple(2032, 60)
    end

    test "iso day 0 is an invalid day" do
      assert {:error, :invalid_day} === Helpers.iso_day_to_date_tuple(1, 0)
    end

    test "iso day 367 is an invalid day" do
      assert {:error, :invalid_day} === Helpers.iso_day_to_date_tuple(1, 367)
    end

    test "year -1 is an invalid year" do
      assert {:error, :invalid_year} === Helpers.iso_day_to_date_tuple(-1, 1)
    end

    test "year -1 and day 0 is an invalid day and year" do
      assert {:error, :invalid_year_and_day} === Helpers.iso_day_to_date_tuple(-1, 0)
    end

    test "day that is valid on leap year that isn't on regular year is invalid" do
      assert {:error, :invalid_day} === Helpers.iso_day_to_date_tuple(1, 366)
    end
  end
end
