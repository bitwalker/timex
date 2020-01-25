defmodule TimezoneTests do
  use ExUnit.Case, async: true
  use ExUnitProperties
  use Timex
  doctest Timex.Timezone
  doctest Timex.Timezone.Local
  doctest Timex.Timezone.Utils

  test "get" do
    %TimezoneInfo{} = tz = Timezone.get("America/Chicago", ~N[2015-01-01T01:00:00])
    assert tz.full_name === "America/Chicago"
    assert tz.abbreviation === "CST"
    assert tz.offset_utc === -21600

    %TimezoneInfo{} =
      tz = Timezone.get("Europe/Stockholm", Timex.to_datetime({{2015, 1, 1}, {1, 0, 0}}))

    assert tz.full_name === "Europe/Stockholm"
    assert tz.abbreviation === "CET"
    assert tz.offset_utc === 3600
    %TimezoneInfo{} = tz = Timezone.get(:utc)
    assert tz.full_name === "Etc/UTC"
    assert tz.offset_utc === 0
    %TimezoneInfo{} = tz = Timezone.get(2)
    assert tz.full_name === "Etc/GMT-2"
    assert tz.offset_utc === 7200
    %TimezoneInfo{} = tz = Timezone.get(-3)
    assert tz.full_name === "Etc/GMT+3"
    assert tz.offset_utc === -10800
    %TimezoneInfo{} = tz = Timezone.get("America/Chicago", ~N[2015-05-01T12:00:00])
    assert tz.full_name === "America/Chicago"
    assert tz.abbreviation === "CDT"
    assert Timezone.total_offset(tz.offset_std, tz.offset_utc) === -18000
  end

  test "local" do
    local = Timezone.local()

    is_error =
      case local do
        %TimezoneInfo{} -> false
        {:error, _} -> true
        _ -> true
      end

    assert is_error == false
  end

  test "diff" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago", ~N[2015-01-01T12:00:00])
    cdt = Timezone.get("America/Chicago", ~N[2015-03-30T12:00:00])
    gmt_plus_two = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3)
    # How many minutes do I apply to UTC when shifting to CST
    assert Timex.to_datetime({{2014, 2, 24}, {0, 0, 0}}, utc) |> Timezone.diff(cst) === -21600
    # How many minutes do I apply to UTC when shifting to CDT
    assert Timex.to_datetime({{2014, 3, 30}, {0, 0, 0}}, utc) |> Timezone.diff(cdt) === -18000
    # And vice versa
    assert Timex.to_datetime({{2014, 2, 24}, {0, 0, 0}}, cst) |> Timezone.diff(utc) === 21600
    assert Timex.to_datetime({{2014, 3, 30}, {0, 0, 0}}, cdt) |> Timezone.diff(utc) === 18000
    # How many minutes do I apply to gmt_plus_two when shifting to gmt_minus_three?
    assert Timex.to_datetime({{2014, 2, 24}, {0, 0, 0}}, gmt_plus_two)
           |> Timezone.diff(gmt_minus_three) === -18000

    # And vice versa
    assert Timex.to_datetime({{2014, 2, 24}, {0, 0, 0}}, gmt_minus_three)
           |> Timezone.diff(gmt_plus_two) === 18000
  end

  property "convert always returns DateTime or AmbiguousDateTime" do
    check all(
            input_date <- PropertyHelpers.date_time_generator(:tuple),
            timezone <- PropertyHelpers.timezone_generator()
          ) do
      result = Timezone.convert(input_date, timezone)
      assert match?(%DateTime{}, result) || match?(%Timex.AmbiguousDateTime{}, result)
    end
  end

  test "convert" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago", ~N[2014-02-24T12:00:00])
    est = Timezone.get("America/New_York", ~N[2014-02-24T12:00:00])
    gmt_plus_two = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3)

    chicago_noon = %DateTime{
      day: 24,
      hour: 12,
      minute: 0,
      month: 2,
      microsecond: {123_000, 3},
      second: 0,
      time_zone: cst.full_name,
      zone_abbr: cst.abbreviation,
      utc_offset: cst.offset_utc,
      std_offset: cst.offset_std,
      year: 2014
    }

    dinnertime = Timezone.convert(chicago_noon, utc)

    gmt = Timex.to_datetime({{1960, 10, 14}, {13, 45, 0}}, "Europe/London")
    gmt_to_utc = Timezone.convert(gmt, :utc)
    assert gmt.hour == gmt_to_utc.hour

    # convert to same timezone should result in same datetime
    assert ^chicago_noon = chicago_noon |> Timezone.convert(cst)

    utc_name = utc.full_name
    assert %DateTime{hour: 18, time_zone: ^utc_name, microsecond: {123_000, _}} = dinnertime
    # If it's noon in CST, then it's 6'oclock in the evening in UTC
    assert %DateTime{hour: 18} =
             Timex.to_datetime({{2014, 2, 24}, {12, 0, 0}}, cst) |> Timezone.convert(utc)

    # If it's noon in UTC, then it's 6'oclock in the morning in CST
    assert %DateTime{hour: 6} =
             Timex.to_datetime({{2014, 2, 24}, {12, 0, 0}}, utc) |> Timezone.convert(cst)

    # If it's noon in CST, then it's 1'oclock in the afternoon in EST
    assert %DateTime{hour: 13} =
             Timex.to_datetime({{2014, 2, 24}, {12, 0, 0}}, cst) |> Timezone.convert(est)

    # If it's noon in EST, then it's 11'oclock in the morning in CST
    assert %DateTime{hour: 11} =
             Timex.to_datetime({{2014, 2, 24}, {12, 0, 0}}, est) |> Timezone.convert(cst)

    # If it's noon in GMT+2, then it's 7'oclock in the morning in GMT-3
    assert %DateTime{hour: 7} =
             Timex.to_datetime({{2014, 2, 24}, {12, 0, 0}}, gmt_plus_two)
             |> Timezone.convert(gmt_minus_three)

    # If it's noon in GMT-3, then it's 5'oclock in the evening in GMT+2
    assert %DateTime{hour: 17} =
             Timex.to_datetime({{2014, 2, 24}, {12, 0, 0}}, gmt_minus_three)
             |> Timezone.convert(gmt_plus_two)

    # Return {:error, term} if an invalid date is given
    assert {:error, :invalid_date} = Timezone.convert(nil, cst)
  end

  test "converting across zone boundaries" do
    utc_date = Timex.from_unix(1_394_344_799)
    cst_date = utc_date |> Timezone.convert("America/Chicago")

    assert ^utc_date = Timex.to_datetime({{2014, 3, 9}, {5, 59, 59}}, "Etc/UTC")
    assert ^cst_date = Timex.to_datetime({{2014, 3, 8}, {23, 59, 59}}, "America/Chicago")
    assert ^utc_date = cst_date |> Timezone.convert("UTC")
  end

  test "converting with custom time zone" do
    offset = 3 * 60 * 60 + 15 * 60
    custom_tx = Timex.TimezoneInfo.create("Custom/TZ", "ATZ", offset, 0, :min, :max)
    noon = Timex.to_datetime({{2017, 3, 15}, {12, 0, 0}}, "Etc/UTC")

    assert {{2017, 3, 15}, {15, 15, 0}} = noon |> Timezone.convert(custom_tx) |> Timex.to_erl()
  end

  test "issue #142 - invalid results produced when converting across DST in Europe/Zurich" do
    # Hour of 2am is repeated twice for this change
    datetime1 = {{2015, 10, 25}, {3, 12, 34}}

    assert {{2015, 10, 25}, {2, 12, 34}} =
             Timex.to_datetime(datetime1, "Europe/Zurich")
             |> Timezone.convert("UTC")
             |> Timex.to_erl()

    # Causes infinite loop
    datetime2 = {{2015, 10, 25}, {2, 12, 34}}

    assert {{2015, 10, 25}, {3, 12, 34}} =
             Timex.to_datetime(datetime2, "UTC")
             |> Timezone.convert("Europe/Zurich")
             |> Timex.to_erl()
  end

  @tag skip: true
  test "issue #142 - ambiguity" do
    # Is not technically ambiguous, but we make it so because in general
    # the date time represented here *is* ambiguous, i.e. 2AM is a repeat hour,
    # but we have extra context when converting from UTC to disambiguate
    datetime3 = {{2015, 10, 25}, {0, 12, 34}}

    assert {{2015, 10, 25}, {2, 12, 34}} =
             Timex.to_datetime(datetime3, "UTC")
             |> Timezone.convert("Europe/Zurich")
             |> Timex.to_erl()

    datetime4 = {{2015, 10, 25}, {1, 12, 34}}

    assert {{2015, 10, 25}, {2, 12, 34}} =
             Timex.to_datetime(datetime4, "UTC")
             |> Timezone.convert("Europe/Zurich")
             |> Timex.to_erl()
  end

  @tag skip: true
  test "Issue #220 - Timex.Timezone.convert gives wrong result date/tz sets resulting ambiguous timezones" do
    datetime = {{2016, 10, 30}, {0, 0, 0}}

    converted =
      datetime
      |> Timex.to_datetime("Etc/UTC")
      |> Timezone.convert("Europe/Amsterdam")

    assert {{2016, 10, 30}, {2, 0, 0}} = converted
  end

  test "another issue related to #142" do
    datetime = {{2016, 10, 30}, {3, 59, 0}}

    assert 63_645_015_540 =
             Timex.to_gregorian_seconds(Timex.to_datetime(datetime, "Europe/Vienna"))
  end
end
