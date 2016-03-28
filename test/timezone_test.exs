defmodule TimezoneTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex.Timezone
  doctest Timex.Timezone.Local
  doctest Timex.Timezone.Database

  test "get" do
    %TimezoneInfo{:full_name => name, :abbreviation => abbrev, :offset_utc => offset} = Timezone.get("America/Chicago", Timex.datetime{{2015,1,1}, {1,0,0}})
    assert name === "America/Chicago"
    assert abbrev === "CST"
    assert offset === -360
    %TimezoneInfo{:full_name => name, :abbreviation => abbrev, :offset_utc => offset} = Timezone.get("Europe/Stockholm", Timex.datetime{{2015,1,1}, {1,0,0}})
    assert name === "Europe/Stockholm"
    assert abbrev === "CET"
    assert offset === 60
    %TimezoneInfo{:full_name => name, :offset_utc => offset} = Timezone.get(:utc)
    assert name === "UTC"
    assert offset === 0
    %TimezoneInfo{:full_name => name, :offset_utc => offset} = Timezone.get(2)
    assert name === "Etc/GMT-2"
    assert offset === 120
    %TimezoneInfo{:full_name => name, :offset_utc => offset} = Timezone.get(-3)
    assert name === "Etc/GMT+3"
    assert offset === -180
    %TimezoneInfo{:abbreviation => name, :offset_utc => offset, :offset_std => offset_std} = Timezone.get("America/Chicago", Timex.datetime({{2015, 5, 1}, {12, 0, 0}}))
    assert name === "CDT"
    assert (offset + offset_std) === -300
  end

  test "local" do
    local = Timezone.local
    is_error = case local do
      %TimezoneInfo{} -> false
      {:error, _}     -> true
      _               -> true
    end
    assert is_error == false
  end

  test "diff" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago", Timex.datetime({{2015, 1, 1}, {12, 0, 0}}))
    cdt = Timezone.get("America/Chicago", Timex.datetime({{2015, 3, 30}, {12, 0, 0}}))
    gmt_plus_two    = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3)
    # How many minutes do I apply to UTC when shifting to CST
    assert Timex.datetime({{2014,2,24},{0,0,0}}, utc) |> Timezone.diff(cst) === -360
    # How many minutes do I apply to UTC when shifting to CDT
    assert Timex.datetime({{2014,3,30},{0,0,0}}, utc) |> Timezone.diff(cdt) === -300
    # And vice versa
    assert Timex.datetime({{2014,2,24},{0,0,0}}, cst) |> Timezone.diff(utc) === 360
    assert Timex.datetime({{2014,3,30},{0,0,0}}, cdt) |> Timezone.diff(utc) === 300
    # How many minutes do I apply to gmt_plus_two when shifting to gmt_minus_three?
    assert Timex.datetime({{2014,2,24},{0,0,0}}, gmt_plus_two) |> Timezone.diff(gmt_minus_three) === -300
    # And vice versa
    assert Timex.datetime({{2014,2,24},{0,0,0}}, gmt_minus_three) |> Timezone.diff(gmt_plus_two) === 300
  end

  test "convert" do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago", Timex.datetime({{2014, 2, 24}, {12,0,0}}))
    est = Timezone.get("America/New_York", Timex.datetime({{2014, 2, 24}, {12,0,0}}))
    gmt_plus_two    = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3)

    chicago_noon = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 12, minute: 0, month: 2, millisecond: 123, second: 0,timezone: cst , year: 2014}

    dinnertime = Timezone.convert(chicago_noon,utc)

    gmt = Timex.datetime({{1960, 10, 14}, {13, 45, 0}}, "Europe/London")
    gmt_to_utc = gmt |> DateTime.universal
    assert gmt.hour == gmt_to_utc.hour

    # convert to same timezone should result in same datetime
    assert ^chicago_noon = chicago_noon |> Timezone.convert(cst)

    assert %DateTime{hour: 18, timezone: utc, millisecond: 123} = dinnertime
    # If it's noon in CST, then it's 6'oclock in the evening in UTC
    assert %DateTime{hour: 18, millisecond: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, millisecond: 123, timezone: cst} |> Timezone.convert(utc)
    # If it's noon in UTC, then it's 6'oclock in the morning in CST
    assert %DateTime{hour: 6, millisecond: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, millisecond: 123, timezone: utc} |> Timezone.convert(cst)
    # If it's noon in CST, then it's 1'oclock in the afternoon in EST
    assert %DateTime{hour: 13, millisecond: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, millisecond: 123, timezone: cst} |> Timezone.convert(est)
    # If it's noon in EST, then it's 11'oclock in the morning in CST
    assert %DateTime{hour: 11, millisecond: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, millisecond: 123, timezone: est} |> Timezone.convert(cst)
    # If it's noon in GMT+2, then it's 7'oclock in the morning in GMT-3
    assert %DateTime{hour: 7, millisecond: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, millisecond: 123, timezone: gmt_plus_two} |> Timezone.convert(gmt_minus_three)
    # If it's noon in GMT-3, then it's 5'oclock in the evening in GMT+2
    assert %DateTime{hour: 17, millisecond: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, millisecond: 123, timezone: gmt_minus_three} |> Timezone.convert(gmt_plus_two)
  end

  test "converting across zone boundaries" do
    utc_date = DateTime.from_seconds(1394344799)
    cst_date = utc_date |> Timezone.convert("America/Chicago")

    assert ^utc_date = Timex.datetime({{2014,3,9}, {5,59,59}})
    assert ^cst_date = Timex.datetime({{2014,3,8}, {23,59,59}}, "America/Chicago")
    assert ^utc_date = cst_date |> Timezone.convert("UTC")
  end

  test "issue #142 - invalid results produced when converting across DST in Europe/Zurich" do
    # Hour of 2am is repeated twice for this change
    datetime1 = {{2015,10,25}, {3,12,34}}

    assert {{2015,10,25}, {2,12,34}} = Timex.datetime(datetime1, "Europe/Zurich") |> Timezone.convert("UTC") |> Timex.to_erlang_datetime

    # Causes infinite loop
    datetime2 = {{2015,10,25},{2,12,34}}
    assert {{2015,10,25}, {3,12,34}} = Timex.datetime(datetime2, "UTC") |> Timezone.convert("Europe/Zurich") |> Timex.to_erlang_datetime

    # Is not technically ambiguous, but we make it so because in general
    # the date time represented here *is* ambiguous, i.e. 2AM is a repeat hour,
    # but we have extra context when converting from UTC to disambiguate
    datetime3 = {{2015,10,25},{0,12,34}}
    #assert {{2015,10,25},{2,12,34}} = Timex.datetime(datetime3, "UTC") |> Timezone.convert("Europe/Zurich") |> Timex.to_erlang_datetime
    assert %AmbiguousDateTime{} = Timex.datetime(datetime3, "UTC") |> Timezone.convert("Europe/Zurich")

    # Should not error out about missing key
    # Should be ambiguous, because 1AM in UTC is during the second 2AM hour of Europe/Zurich
    datetime4 = {{2015,10,25},{1,12,34}}
    assert %AmbiguousDateTime{} = Timex.datetime(datetime4, "UTC") |> Timezone.convert("Europe/Zurich")
  end
end
