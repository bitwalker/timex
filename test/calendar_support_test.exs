defmodule CalendarSupportTest do
  use ExUnit.Case, async: true

  # A real calendar with different year fields for the same ISO day. Delegating
  # the remaining callbacks keeps it usable on every supported Elixir version.
  defmodule Holocene do
    for {name, arity} <- Calendar.ISO.__info__(:functions),
        {name, arity} not in [
          naive_datetime_to_iso_days: 7,
          naive_datetime_from_iso_days: 1,
          date_to_iso_days: 3,
          date_from_iso_days: 1,
          valid_date?: 3,
          day_of_week: 3
        ] do
      args = Macro.generate_arguments(arity, __MODULE__)
      defdelegate unquote(name)(unquote_splicing(args)), to: Calendar.ISO
    end

    def naive_datetime_to_iso_days(y, m, d, h, min, s, us),
      do: Calendar.ISO.naive_datetime_to_iso_days(y - 10_000, m, d, h, min, s, us)

    def naive_datetime_from_iso_days(days) do
      {y, m, d, h, min, s, us} = Calendar.ISO.naive_datetime_from_iso_days(days)
      {y + 10_000, m, d, h, min, s, us}
    end

    def date_to_iso_days(y, m, d), do: Calendar.ISO.date_to_iso_days(y - 10_000, m, d)

    def date_from_iso_days(days) do
      {y, m, d} = Calendar.ISO.date_from_iso_days(days)
      {y + 10_000, m, d}
    end

    def valid_date?(y, m, d), do: Calendar.ISO.valid_date?(y - 10_000, m, d)
  end

  @dates [~D[2026-01-01], ~N[2026-01-01 00:00:00], ~U[2026-01-01 00:00:00Z]]
  @unary_operations ~w(to_date to_naive_datetime to_datetime to_erl to_julian
    to_gregorian_seconds to_gregorian_microseconds to_unix century is_leap?
    beginning_of_day end_of_day beginning_of_week end_of_week
    beginning_of_month end_of_month beginning_of_quarter end_of_quarter
    beginning_of_year end_of_year quarter days_in_month week_of_month weekday
    day iso_week)a

  test "date operations reject unsupported calendars before interpreting their fields" do
    for date <- @dates do
      date = %{date | calendar: Holocene, year: 12_026}
      error = {:error, {:unsupported_calendar, Holocene}}

      for operation <- @unary_operations do
        assert apply(Timex, operation, [date]) == error, "#{operation}/1"
      end

      assert Timex.to_datetime(date, "America/New_York") == error
      assert Timex.weekday(date, :sun) == error
      assert Timex.beginning_of_week(date, :sun) == error
      assert Timex.end_of_week(date, :sun) == error
      assert Timex.from_iso_day(32, date) == error
      assert Timex.shift(date, months: 1) == error
      assert Timex.set(date, month: 2) == error
      assert Timex.is_valid?(date) == false
    end
  end

  test "unsupported years return the same error for all date representations" do
    for date <- @dates, year <- [-1755, 10_000] do
      date = %{date | year: year}
      error = {:error, {:unsupported_year, year}}

      for operation <- @unary_operations do
        assert apply(Timex, operation, [date]) == error, "#{operation}/1"
      end

      assert Timex.shift(date, days: 1) == error
      assert Timex.set(date, month: 2) == error
      assert Timex.is_valid?(date) == false
    end
  end

  test "comparisons reject unsupported operands including identity shortcuts" do
    for date <- @dates,
        unsupported <- [%{date | year: -1755}, %{date | calendar: Holocene, year: 12_026}],
        {a, b} <- [{date, unsupported}, {unsupported, date}, {unsupported, unsupported}] do
      error =
        if unsupported.calendar == Holocene,
          do: {:error, {:unsupported_calendar, Holocene}},
          else: {:error, {:unsupported_year, -1755}}

      for unit <- [:years, :months, :days, :calendar_weeks, :microseconds] do
        assert Timex.diff(a, b, unit) == error
        assert Timex.compare(a, b, unit) == error
      end

      assert Timex.diff(a, b) == error
      assert Timex.compare(a, b) == error
      assert_raise ArgumentError, ~r/unsupported_/, fn -> Timex.equal?(a, b) end
    end
  end

  test "explicit standard-library conversion preserves the instant before using Timex" do
    date = %Date{calendar: Holocene, year: 12_026, month: 1, day: 1}
    assert {:ok, iso_date} = Date.convert(date, Calendar.ISO)
    assert iso_date == ~D[2026-01-01]
    assert Timex.to_naive_datetime(iso_date) == ~N[2026-01-01 00:00:00]
  end

  test "integer year APIs enforce the same supported year range" do
    for year <- [-1755, 10_000] do
      error = {:error, {:unsupported_year, year}}
      assert Timex.century(year) == error
      assert Timex.is_leap?(year) == error
      assert Timex.iso_week(year, 1, 1) == error
      assert Timex.from_iso_day(32, year) == error
      assert Timex.from_iso_triplet({year, 1, 1}) == error
      assert Timex.days_in_month(year, 1) == error
      assert Timex.week_of_month(year, 1, 1) == error
      assert Timex.beginning_of_month(year, 1) == error
      assert Timex.end_of_month(year, 1) == error
      assert Timex.end_of_quarter(year, 1) == error
      assert Timex.beginning_of_year(year) == error
      assert Timex.end_of_year(year) == error
    end
  end

  test "date maps and tuples enforce supported years without changing invalid-input errors" do
    for value <- [
          {-1755, 1, 1},
          {{-1755, 1, 1}, {0, 0, 0}},
          %{year: -1755, month: 1, day: 1},
          %{"year" => "-1755", "month" => "1", "day" => "1"}
        ] do
      assert Timex.to_date(value) == {:error, {:unsupported_year, -1755}}
    end

    assert Timex.to_date(%{year: 2026, month: 1, day: 1, calendar: Holocene}) ==
             {:error, {:unsupported_calendar, Holocene}}

    assert Timex.to_date(%{"year" => "2026", :month => 1, :day => 1, :calendar => Holocene}) ==
             {:error, {:unsupported_calendar, Holocene}}

    assert Timex.to_date(%{"calendar" => Holocene, :year => 2026, :month => 1, :day => 1}) ==
             {:error, {:unsupported_calendar, Holocene}}

    assert Timex.to_gregorian_microseconds(%{
             "year" => -1755,
             :year => 2026,
             :month => 1,
             :day => 1
           }) ==
             {:error, {:unsupported_year, -1755}}

    assert_raise Timex.ConvertError, fn -> Timex.to_date(%{}) end
    assert Timex.to_date(:invalid) == {:error, :invalid_date}
  end

  test "setter composite options reject unsupported calendars before extracting fields" do
    date = %Date{calendar: Holocene, year: 12_026, month: 2, day: 1}
    time = %{~T[12:00:00] | calendar: Holocene}
    error = {:error, {:unsupported_calendar, Holocene}}

    for options <- [[date: date], [time: time], [datetime: {date, time}]],
        validate? <- [true, false] do
      assert Timex.set(~N[2026-01-01 00:00:00], options ++ [validate: validate?]) == error
    end
  end

  test "operations reject results outside supported years with raw setters as an opt-out" do
    for date <- @dates do
      assert Timex.set(date, year: 10_000) == {:error, {:unsupported_year, 10_000}}
      assert %{year: 10_000} = Timex.set(date, year: 10_000, validate: false)

      assert Timex.shift(%{date | year: 9999}, years: 1) ==
               {:error, {:unsupported_year, 10_000}}
    end
  end

  test "elapsed shifts report unsupported instants before asking the timezone database" do
    for date <- [~N[9999-12-31 23:59:59], ~U[9999-12-31 23:59:59Z]] do
      assert Timex.shift(date, seconds: 1) == {:error, {:unsupported_year, 10_000}}
    end

    for date <- [~N[0000-01-01 00:00:00], ~U[0000-01-01 00:00:00Z]] do
      assert Timex.shift(date, seconds: -1) == {:error, {:unsupported_year, -1}}
    end

    for {wall, zone, seconds, year} <- [
          {~N[9999-12-31 23:59:59], "Etc/UTC+1", 1, 10_000},
          {~N[0000-01-01 00:00:00], "Etc/UTC-1", -1, -1}
        ] do
      date = Timex.to_datetime(wall, zone)
      assert Timex.shift(date, seconds: seconds) == {:error, {:unsupported_year, year}}
    end
  end

  test "normalization propagates unsupported upper years while retaining negative-year clamping" do
    assert Timex.normalize(:year, 10_000) == {:error, {:unsupported_year, 10_000}}
    assert Timex.normalize(:date, {10_000, 1, 1}) == {:error, {:unsupported_year, 10_000}}
    assert Timex.normalize(:day, {10_000, 1, 1}) == {:error, {:unsupported_year, 10_000}}
    assert Timex.normalize(:date, {-1, 1, 1}) == {0, 1, 1}
  end

  test "comparisons reject UTC instants beyond the supported years even with supported wall years" do
    before_zero = %DateTime{
      year: 0,
      month: 1,
      day: 1,
      hour: 0,
      minute: 0,
      second: 0,
      time_zone: "+01",
      zone_abbr: "+01",
      utc_offset: 3600,
      std_offset: 0
    }

    after_limit = %{
      before_zero
      | year: 9999,
        month: 12,
        day: 31,
        hour: 23,
        time_zone: "-01",
        zone_abbr: "-01",
        utc_offset: -3600
    }

    for {date, year} <- [{before_zero, -1}, {after_limit, 10_000}] do
      assert Timex.compare(date, date) == {:error, {:unsupported_year, year}}
    end

    for {date, year} <- [{before_zero, -1}, {after_limit, 10_000}],
        {a, b} <- [{date, ~U[2026-01-01 00:00:00Z]}, {~U[2026-01-01 00:00:00Z], date}],
        unit <- [:years, :months, :calendar_weeks, :microseconds] do
      assert Timex.diff(a, b, unit) == {:error, {:unsupported_year, year}}
    end
  end

  test "ISO week conversion rejects a calculated date beyond the supported range" do
    assert Timex.from_iso_triplet({9999, 53, 7}) == {:error, {:unsupported_year, 10_000}}
  end

  test "ambiguous comparisons validate their date bounds" do
    unsupported = %{~U[2026-01-01 00:00:00Z] | calendar: Holocene, year: 12_026}
    ambiguous = %Timex.AmbiguousDateTime{before: unsupported, after: unsupported}
    assert Timex.compare(ambiguous, ambiguous) == {:error, {:unsupported_calendar, Holocene}}
    assert Timex.diff(ambiguous, ambiguous) == {:error, {:unsupported_calendar, Holocene}}
  end

  test "bang weekday reports unsupported inputs with ArgumentError" do
    assert_raise ArgumentError, ~r/unsupported_year/, fn ->
      Timex.weekday!(%{~D[2026-01-01] | year: -1})
    end
  end

  test "calendar week differences work when the containing week crosses a supported boundary" do
    assert Timex.diff(~D[9999-12-31], ~D[9999-12-20], :calendar_weeks) == 2
    assert Timex.diff(~D[9999-12-20], ~D[9999-12-31], :calendar_weeks) == -2
    assert Timex.diff(~D[0000-01-01], ~D[0000-01-20], :calendar_weeks) == -4
    assert Timex.diff(~D[0000-01-20], ~D[0000-01-01], :calendar_weeks) == 4
  end

  test "gap results also enforce supported years on both boundaries" do
    assert Timex.to_datetime(~N[0000-01-01 00:30:00], "STD0DST,J1/0,J2/0") ==
             {:error, {:unsupported_year, -1}}
  end

  test "ISO week metadata can name the preceding year at the year-zero boundary" do
    assert Timex.iso_week(~D[0000-01-01]) == {-1, 52}
    assert Timex.iso_week(~D[0000-01-02]) == {-1, 52}
    assert Timex.iso_triplet(~D[0000-01-01]) == {-1, 52, 6}
    assert Timex.week_of_month(~D[0000-01-01]) == 1
    assert Timex.week_of_month(~D[0000-01-02]) == 1
    assert Timex.iso_week(~D[9999-12-31]) == {9999, 52}
  end

  test "year zero and year 9999 remain supported including timezone conversion" do
    assert Timex.diff(~D[0000-01-02], ~D[0000-01-01], :days) == 1
    assert Timex.diff(~D[9999-01-01], ~D[9998-01-01], :years) == 1

    assert %DateTime{year: 9999, time_zone: "Europe/Amsterdam"} =
             Timex.to_datetime(~N[9999-01-01 12:00:00], "Europe/Amsterdam")

    assert Timex.is_valid?(~D[0000-01-01])
    assert Timex.is_valid?(~D[9999-12-31])
    assert Timex.compare(~D[2026-01-01], :distant_past) == 1
    assert Timex.compare(~D[2026-01-01], :distant_future) == -1
    assert Timex.diff(~T[12:00:01], ~T[12:00:00], :seconds) == 1
    assert Timex.quarter(4) == 2
  end
end

defmodule CalendarSupportLocalTest do
  use ExUnit.Case, async: false

  test "local conversion validates the resulting wall year" do
    original = Application.fetch_env(:timex, :local_timezone)

    on_exit(fn ->
      case original do
        {:ok, timezone} -> Application.put_env(:timex, :local_timezone, timezone)
        :error -> Application.delete_env(:timex, :local_timezone)
      end
    end)

    for {timezone, input, year} <- [
          {"Etc/GMT+1", ~U[0000-01-01 00:00:00Z], -1},
          {"Etc/GMT-1", ~U[9999-12-31 23:30:00Z], 10_000}
        ] do
      Application.put_env(:timex, :local_timezone, timezone)
      assert Timex.local(input) == {:error, {:unsupported_year, year}}
    end
  end
end
