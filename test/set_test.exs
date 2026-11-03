defmodule SetTests do
  use ExUnitProperties
  use ExUnit.Case, async: true
  use Timex

  property "setting all the properties from the target date should become a target date for a DateTime" do
    check all(
            input_date <- PropertyHelpers.date_time_generator(:struct),
            {{year, month, day}, {hour, minute, second}} = target_date <-
              PropertyHelpers.date_time_generator(:tuple)
          ) do
      date =
        Timex.set(input_date,
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second
        )

      assert Timex.to_erl(date) == target_date
    end
  end

  property "setting all the properties from the target date should become a target date for a tuple" do
    check all(
            input_date <- PropertyHelpers.date_time_generator(:tuple),
            {{year, month, day}, {hour, minute, second}} = target_date <-
              PropertyHelpers.date_time_generator(:tuple)
          ) do
      date =
        Timex.set(input_date,
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second
        )

      assert Timex.to_erl(date) == target_date
    end
  end

  test "sets DateTime time values from time struct" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3, 4}})
    new_date = Timex.set(original_date, time: ~T[09:52:33.000])

    assert original_date.year == new_date.year
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
    assert new_date.microsecond == {0, 3}
  end

  test "sets DateTime time values from time tuple" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3, 4}})
    new_date = Timex.set(original_date, time: {9, 52, 33})

    assert original_date.year == new_date.year
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
    assert new_date.microsecond == {4, 6}
  end

  test "sets DateTime time values from time struct with more than one change requested" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {1, 2, 3, 4}})
    new_date = Timex.set(original_date, time: ~T[09:52:33.000], year: 1989)

    assert new_date.year == 1989
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
    assert new_date.microsecond == {0, 3}
  end

  test "sets NaiveDateTime time values from time struct" do
    original_date = Timex.to_naive_datetime({{2017, 7, 21}, {1, 2, 3, 4}})
    new_date = Timex.set(original_date, time: ~T[09:52:33.000])

    assert original_date.year == new_date.year
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
    assert new_date.microsecond == {0, 3}
  end

  test "sets NaiveDateTime time values from time tuple" do
    original_date = Timex.to_naive_datetime({{2017, 7, 21}, {1, 2, 3, 4}})
    new_date = Timex.set(original_date, time: {9, 52, 33})

    assert original_date.year == new_date.year
    assert original_date.month == new_date.month
    assert original_date.day == new_date.day

    assert new_date.hour == 9
    assert new_date.minute == 52
    assert new_date.second == 33
    assert new_date.microsecond == {4, 6}
  end

  test "sets from date struct" do
    original_date = Timex.to_datetime({{2017, 7, 21}, {12, 0, 0}})
    new_date = Timex.set(original_date, date: ~D[2018-09-02], hour: 16)

    assert new_date.year == 2018
    assert new_date.month == 9
    assert new_date.day == 2

    assert new_date.hour == 16
    assert new_date.minute == 0
    assert new_date.second == 0
  end

  describe "validated final values" do
    test "clamps retained days after month and year changes in every representation" do
      for date <- representations(~D[2018-01-31]) do
        assert_date_fields(Timex.set(date, month: 2), {2018, 2, 28})
        assert_date_fields(Timex.set(date, month: 2, validate: true), {2018, 2, 28})
      end

      for date <- representations(~D[2020-02-29]) do
        assert_date_fields(Timex.set(date, year: 2021), {2021, 2, 28})
      end
    end

    test "clamps the day only after all field replacements" do
      options = [
        [day: 31, month: 1, year: 2021],
        [year: 2021, month: 1, day: 31],
        [month: 1, day: 31, year: 2021],
        [day: 31, year: 2021, month: 1],
        [year: 2021, day: 31, month: 1],
        [month: 1, year: 2021, day: 31],
        [day: 31, month: 2, month: 1],
        [date: {2021, 2, 31}, month: 1],
        [datetime: {{2021, 2, 31}, {9, 10, 11}}, month: 1],
        [date: ~D[2021-02-28], day: 31, month: 1]
      ]

      for date <- representations(~D[2021-02-28]), options <- options do
        assert_date_fields(Timex.set(date, options), {2021, 1, 31})
      end
    end

    test "day month and year order does not prematurely discard leap day" do
      options = [
        [day: 29, month: 2, year: 2020],
        [day: 29, year: 2020, month: 2],
        [month: 2, day: 29, year: 2020],
        [month: 2, year: 2020, day: 29],
        [year: 2020, day: 29, month: 2],
        [year: 2020, month: 2, day: 29]
      ]

      for date <- representations(~D[2019-02-28]), options <- options do
        assert_date_fields(Timex.set(date, options), {2020, 2, 29})
      end
    end

    test "the first validate flag controls the operation" do
      for date <- representations(~D[2018-01-31]) do
        assert_date_fields(
          Timex.set(date, validate: false, month: 2, validate: true),
          {2018, 2, 31}
        )

        assert_date_fields(
          Timex.set(date, validate: true, month: 2, validate: false),
          {2018, 2, 28}
        )
      end
    end

    test "later composite options replace earlier individual fields" do
      for date <- representations(~D[2020-02-29]) do
        assert_date_fields(Timex.set(date, month: 1, date: {2021, 2, 31}), {2021, 2, 28})

        assert_date_fields(
          Timex.set(date, year: 2020, datetime: {{2021, 2, 31}, {9, 10, 11}}),
          {2021, 2, 28}
        )

        assert_date_fields(
          Timex.set(date, date: {2021, 2, 31}, date: {2020, 2, 29}),
          {2020, 2, 29}
        )
      end
    end

    test "normalizes composite year and month before validating the day" do
      for date <- representations(~D[2021-01-31]) do
        assert_date_fields(Timex.set(date, datetime: {{-1, 13, 31}, {25, 61, 61}}), {0, 12, 31})
      end
    end

    test "preserves date-only and fractional tuple representations" do
      assert Timex.set({2018, 1, 31}, month: 2, hour: 12) == {2018, 2, 28}

      assert Timex.set({{2018, 1, 31}, {1, 2, 3, {123_000, 3}}}, month: 2) ==
               {{2018, 2, 28}, {1, 2, 3, {123_000, 3}}}

      assert Timex.set({{2018, 1, 31}, {1, 2, 3, 123}}, month: 2) ==
               {{2018, 2, 28}, {1, 2, 3, 123}}
    end

    test "returns errors for invalid options on fractional tuples" do
      assert Timex.set({{2018, 1, 31}, {1, 2, 3, {123_000, 3}}}, invalid: 2) ==
               {:error, {:bad_option, :invalid}}
    end

    test "validate false retains raw final fields including composite struct options" do
      for date <- representations(~D[2018-01-31]) do
        assert_date_fields(Timex.set(date, month: 2, validate: false), {2018, 2, 31})

        assert_date_fields(
          Timex.set(date, validate: false, date: ~D[2020-02-29], year: 2021),
          {2021, 2, 29}
        )
      end

      for date <- [~N[2018-01-31 12:00:00], ~U[2018-01-31 12:00:00Z]] do
        time = %{~T[12:00:00] | hour: 30}
        result = Timex.set(date, time: time, validate: false)
        assert result.hour == 30
      end
    end
  end

  describe "DateTime timezone metadata" do
    test "refreshes offsets after changing wall date or time and preserves precision" do
      winter = Timex.to_datetime(~N[2021-01-31 12:00:00.123], "America/New_York")
      summer = Timex.set(winter, month: 7)

      assert {summer.month, summer.day, summer.hour, summer.zone_abbr, summer.utc_offset,
              summer.std_offset} ==
               {7, 31, 12, "EDT", -18_000, 3_600}

      assert summer.microsecond == {123_000, 3}

      before_transition = Timex.to_datetime(~N[2021-03-14 01:30:00.123], "America/New_York")
      after_transition = Timex.set(before_transition, hour: 3)

      assert {after_transition.hour, after_transition.zone_abbr, after_transition.std_offset} ==
               {3, "EDT", 3_600}

      assert after_transition.microsecond == {123_000, 3}
    end

    test "resolves explicit timezone against the final wall value regardless of option order" do
      for options <- [
            [timezone: "America/New_York", month: 7],
            [month: 7, timezone: "America/New_York"],
            [timezone: "Missing/Timezone", month: 7, timezone: "America/New_York"],
            [timezone: Timex.Timezone.get("America/New_York", ~D[2021-01-31]), month: 7]
          ] do
        result = Timex.set(~U[2021-01-31 12:00:00.123Z], options)

        assert {result.hour, result.time_zone, result.zone_abbr, result.std_offset} ==
                 {12, "America/New_York", "EDT", 3_600}

        assert result.microsecond == {123_000, 3}
      end
    end

    test "reports gaps and overlaps instead of attaching stale offsets" do
      original = Timex.to_datetime(~N[2021-01-14 02:30:00.123], "America/New_York")

      assert %Timex.AmbiguousDateTime{type: :gap, before: before_gap, after: after_gap} =
               Timex.set(original, month: 3)

      assert {before_gap.hour, before_gap.minute, before_gap.zone_abbr} == {1, 59, "EST"}
      assert {after_gap.hour, after_gap.minute, after_gap.zone_abbr} == {3, 0, "EDT"}

      original = Timex.to_datetime(~N[2021-01-07 01:30:00.123], "America/New_York")

      assert %Timex.AmbiguousDateTime{
               type: :ambiguous,
               before: before_overlap,
               after: after_overlap
             } =
               Timex.set(original, month: 11)

      assert {before_overlap.hour, before_overlap.zone_abbr, before_overlap.microsecond} ==
               {1, "EDT", {123_000, 3}}

      assert {after_overlap.hour, after_overlap.zone_abbr, after_overlap.microsecond} ==
               {1, "EST", {123_000, 3}}

      assert Timex.set(before_overlap, []) == before_overlap
    end

    test "unknown timezone returns a structured error" do
      assert Timex.set(~U[2021-01-31 12:00:00Z], timezone: "Missing/Timezone") ==
               {:error, :time_zone_not_found}
    end

    test "validate false preserves raw date fields and existing timezone metadata" do
      original = Timex.to_datetime(~N[2021-01-31 12:00:00.123], "America/New_York")
      result = Timex.set(original, month: 2, validate: false)

      assert {result.month, result.day, result.zone_abbr, result.std_offset, result.microsecond} ==
               {2, 31, "EST", 0, {123_000, 3}}
    end
  end

  defp representations(%Date{year: year, month: month, day: day} = date) do
    [
      date,
      Timex.to_naive_datetime({{year, month, day}, {12, 0, 0, {123_000, 3}}}),
      Timex.to_datetime({{year, month, day}, {12, 0, 0, {123_000, 3}}}),
      {year, month, day},
      {{year, month, day}, {12, 0, 0}},
      {{year, month, day}, {12, 0, 0, {123_000, 3}}}
    ]
  end

  defp assert_date_fields(%{year: year, month: month, day: day}, expected),
    do: assert({year, month, day} == expected)

  defp assert_date_fields({{year, month, day}, _time}, expected),
    do: assert({year, month, day} == expected)

  defp assert_date_fields({year, month, day}, expected),
    do: assert({year, month, day} == expected)
end
