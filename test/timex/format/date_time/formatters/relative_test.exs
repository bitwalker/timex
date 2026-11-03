defmodule Timex.Format.DateTime.Formatters.RelativeTest do
  use ExUnit.Case, async: true
  alias Timex.Format.DateTime.Formatters.Relative
  doctest Relative

  test "date targets compare calendar days independently of the reference clock" do
    for time <- [~T[00:00:00], ~T[12:00:00], ~T[23:59:59.999999]],
        {date, expected} <- [
          {~D[2025-12-30], "2 days ago"},
          {~D[2025-12-31], "yesterday"},
          {~D[2026-01-01], "now"},
          {~D[2026-01-02], "tomorrow"},
          {~D[2026-01-03], "in 2 days"}
        ] do
      reference = NaiveDateTime.new!(~D[2026-01-01], time)
      assert Relative.relative_to(date, reference, "{relative}") == {:ok, expected}
      assert Timex.from_now(date, reference) == expected
      assert Timex.from_now(Date.to_erl(date), reference) == expected
    end
  end

  test "date targets use the UTC date of an aware reference and retain localization" do
    # The reference is Jan 1 in UTC, and Jan 2 in Manila.
    reference = Timex.to_datetime(~N[2026-01-02 01:00:00], "Asia/Manila")
    assert Relative.relative_to(~D[2026-01-02], reference, "{relative}") == {:ok, "tomorrow"}
    assert Timex.from_now(~D[2026-01-02], reference, "ru") == "завтра"
    assert Timex.from_now(~D[2026-01-03], ~D[2026-01-01]) == "in 2 days"
    assert Timex.from_now(~N[2026-01-02 00:00:00], ~N[2026-01-01 12:00:00]) == "in 12 hours"
  end

  test "elapsed day thresholds truncate symmetrically and preserve equivalent aware instants" do
    reference = ~U[2026-01-01 12:00:00Z]
    manila_reference = Timex.Timezone.convert(reference, "Asia/Manila")

    for {delta, future, past} <- [
          {86_399_999_999, "in 23 hours", "23 hours ago"},
          {86_400_000_000, "tomorrow", "yesterday"},
          {86_400_000_001, "tomorrow", "yesterday"},
          {172_799_999_999, "tomorrow", "yesterday"},
          {172_800_000_000, "in 2 days", "2 days ago"},
          {172_800_000_001, "in 2 days", "2 days ago"}
        ],
        {delta, expected} <- [{delta, future}, {-delta, past}] do
      target = DateTime.add(reference, delta, :microsecond)
      manila_target = Timex.Timezone.convert(target, "Asia/Manila")
      assert Timex.from_now(target, reference) == expected
      assert Timex.from_now(manila_target, manila_reference) == expected
      assert Timex.from_now(target, manila_reference) == expected
    end
  end

  test "unsupported targets and references return conversion errors before formatting" do
    reference = ~N[2026-01-01 12:00:00]

    for invalid <- [
          ~T[12:00:00],
          :invalid,
          {},
          {2026, 13, 1},
          {2026, 2, 30},
          {{2026, 2, 30}, {12, 0, 0}},
          {{2026, 1, 1}, {12, 0, 0, {123, 7}}}
        ] do
      assert {:error, _} = Relative.format(invalid, "{relative}")
      assert {:error, _} = Relative.lformat(invalid, "{relative}", "en")
      assert {:error, _} = Relative.relative_to(invalid, reference, "{relative}")
      assert {:error, _} = Relative.relative_to(reference, invalid, "{relative}")
      assert {:error, _} = Timex.format(invalid, "{relative}", :relative)
      assert {:error, _} = Timex.lformat(invalid, "{relative}", "en", :relative)
      assert_raise Timex.Format.FormatError, fn -> Relative.format!(invalid, "{relative}") end
    end

    assert_raise Timex.Format.FormatError, fn ->
      Timex.format!(~T[12:00:00], "{relative}", :relative)
    end

    assert Timex.format!(~T[12:00:00], "{h24}:{m}:{s}") == "12:00:00"
  end

  test "unsupported Date calendars return an explicit error before calling calendar callbacks" do
    date = %{~D[2026-01-01] | calendar: UnknownCalendar}

    assert Relative.relative_to(date, ~D[2026-01-01], "{relative}") ==
             {:error, {:unsupported_calendar, UnknownCalendar}}
  end

  test "invalid date structs return errors rather than raising in conversion or arithmetic" do
    invalid_date = %{~D[2026-01-01] | month: 13}
    invalid_datetime = %{~N[2026-01-01 12:00:00] | month: 13}

    for invalid <- [
          invalid_date,
          invalid_datetime,
          %{~U[2026-01-01 12:00:00Z] | month: 13},
          %{~D[2026-01-01] | year: nil},
          %{~N[2026-01-01 12:00:00] | month: :bad},
          %{~U[2026-01-01 12:00:00Z] | utc_offset: nil}
        ] do
      assert {:error, _} = Relative.relative_to(invalid, ~N[2026-01-01 12:00:00], "{relative}")
    end
  end
end
