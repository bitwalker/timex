defmodule TimezoneTests do
  use ExUnit.Case, async: true
  use Timex

  test :get do
    %TimezoneInfo{:full_name => name, :abbreviation => abbrev, :offset_utc => offset} = Timezone.get("America/Chicago", Date.from{{2015,1,1}, {1,0,0}})
    assert name === "America/Chicago"
    assert abbrev === "CST"
    assert offset === -360
    %TimezoneInfo{:full_name => name, :abbreviation => abbrev, :offset_utc => offset} = Timezone.get("Europe/Stockholm", Date.from{{2015,1,1}, {1,0,0}})
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
    %TimezoneInfo{:abbreviation => name, :offset_utc => offset, :offset_std => offset_std} = Timezone.get("America/Chicago", Date.from({{2015, 5, 1}, {12, 0, 0}}))
    assert name === "CDT"
    assert (offset + offset_std) === -300
  end

  test :local do
    assert Timezone.local() !== nil
  end

  test :diff do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago", Date.from({{2015, 1, 1}, {12, 0, 0}}))
    cdt = Timezone.get("America/Chicago", Date.from({{2015, 3, 30}, {12, 0, 0}}))
    gmt_plus_two    = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3) 
    # How many minutes do I apply to UTC when shifting to CST
    assert Date.from({{2014,2,24},{0,0,0}}, utc) |> Timezone.diff(cst) === -360
    # How many minutes do I apply to UTC when shifting to CDT
    assert Date.from({{2014,3,30},{0,0,0}}, utc) |> Timezone.diff(cdt) === -300
    # And vice versa
    assert Date.from({{2014,2,24},{0,0,0}}, cst) |> Timezone.diff(utc) === 360
    assert Date.from({{2014,3,30},{0,0,0}}, cdt) |> Timezone.diff(utc) === 300
    # How many minutes do I apply to gmt_plus_two when shifting to gmt_minus_three?
    assert Date.from({{2014,2,24},{0,0,0}}, gmt_plus_two) |> Timezone.diff(gmt_minus_three) === -300
    # And vice versa
    assert Date.from({{2014,2,24},{0,0,0}}, gmt_minus_three) |> Timezone.diff(gmt_plus_two) === 300
  end

  test :convert do
    utc = Timezone.get(:utc)
    cst = Timezone.get("America/Chicago", Date.from({{2014, 2, 24}, {12,0,0}}))
    est = Timezone.get("America/New_York", Date.from({{2014, 2, 24}, {12,0,0}}))
    gmt_plus_two    = Timezone.get(2)
    gmt_minus_three = Timezone.get(-3)

    chicago_noon = %Timex.DateTime{calendar: :gregorian, day: 24, hour: 12, minute: 0, month: 2, ms: 123, second: 0,timezone: cst , year: 2014}
   
    dinnertime = Timezone.convert(chicago_noon,utc) 


    # convert to same timezone should result in same datetime
    assert ^chicago_noon = chicago_noon |> Timezone.convert(cst)

    assert %DateTime{hour: 18, timezone: utc, ms: 123} = dinnertime
    # If it's noon in CST, then it's 6'oclock in the evening in UTC
    assert %DateTime{hour: 18, ms: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, ms: 123, timezone: cst} |> Timezone.convert(utc)
    # If it's noon in UTC, then it's 6'oclock in the morning in CST
    assert %DateTime{hour: 6, ms: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, ms: 123, timezone: utc} |> Timezone.convert(cst)
    # If it's noon in CST, then it's 1'oclock in the afternoon in EST
    assert %DateTime{hour: 13, ms: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, ms: 123, timezone: cst} |> Timezone.convert(est)
    # If it's noon in EST, then it's 11'oclock in the morning in CST
    assert %DateTime{hour: 11, ms: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, ms: 123, timezone: est} |> Timezone.convert(cst)
    # If it's noon in GMT+2, then it's 7'oclock in the morning in GMT-3
    assert %DateTime{hour: 7, ms: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, ms: 123, timezone: gmt_plus_two} |> Timezone.convert(gmt_minus_three)
    # If it's noon in GMT-3, then it's 5'oclock in the evening in GMT+2
    assert %DateTime{hour: 17, ms: 123} = %DateTime{year: 2014, month: 2, day: 24, hour: 12, ms: 123, timezone: gmt_minus_three} |> Timezone.convert(gmt_plus_two)
  end

  test :parse_tzfile do
    # TZIF Version 1
    chicago = System.cwd |> Path.join("test/include/tzif/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "CST"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,2,24}, {0,0,0}}))

    # TZIF Version 2
    chicago = System.cwd |> Path.join("test/include/tzif2/America/Chicago")
    assert {:ok, "CDT"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "CST"} = chicago |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,2,24}, {0,0,0}}))

    # TZIF Version 1
    new_york = System.cwd |> Path.join("test/include/tzif/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "EST"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,2,24}, {0,0,0}}))

    # TZIF Version 2
    new_york = System.cwd |> Path.join("test/include/tzif2/America/New_York")
    assert {:ok, "EDT"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,3,24}, {0,0,0}}))
    assert {:ok, "EST"} = new_york |> File.read! |> Timezone.Local.parse_tzfile(Date.from({{2014,2,24}, {0,0,0}}))
  end
end
