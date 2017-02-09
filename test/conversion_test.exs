defmodule ConversionTests do
  use ExUnit.Case, async: true
  use Timex

  ## Date conversions

  test "Date to_gregorian_seconds" do
    assert Duration.to_seconds(Duration.epoch()) == Timex.to_gregorian_seconds(Timex.epoch())
  end

  test "Date to_date" do
    date = ~D[2015-02-28]
    assert ^date = Timex.to_date({2015,2,28})
  end

  test "Date to_unix" do
    assert 0 == Timex.epoch |> Timex.to_unix
  end

  test "Date to_timestamp" do
    assert Duration.zero == Timex.epoch |> Timex.to_unix |> Duration.from_seconds
  end

  ## DateTime conversions

  test "DateTime with fractional offset to NaiveDateTime" do
    datetime = Timex.to_datetime({{2016, 3, 5}, {0,0,0}}, "Asia/Kolkata")
    assert ~N[2016-03-04T18:30:00] = Timex.to_naive_datetime(datetime)
  end

  test "to_gregorian_seconds" do
    assert Duration.to_seconds(Duration.epoch()) == Timex.epoch() |> Timex.to_gregorian_seconds()
  end

  test "to_datetime" do
    date = ~D[2015-02-28]
    datetime = Timex.to_datetime({2015, 2, 28}, "Etc/UTC")

    assert ^datetime = Timex.to_datetime(date, "Etc/UTC")

    datetime = Timex.to_datetime({{2015,2,28}, {12, 35, 1}}, "Etc/UTC")
    assert ^datetime = Timex.to_datetime(datetime, "Etc/UTC")

    datetime_utc = Timex.to_datetime({{2015,2,28}, {12, 35, 1}}, "Etc/UTC")
    datetime_berlin = Timex.to_datetime({{2015,2,28}, {13, 35, 1}}, "Europe/Berlin")

    assert ^datetime_berlin = Timex.to_datetime(datetime_utc, "Europe/Berlin")
  end

  test "to_unix" do
    assert 0 == Timex.epoch |> Timex.to_unix
  end

  ## Tuple conversions

  test "date tuple to_gregorian_seconds" do
    assert Duration.to_seconds(Duration.epoch) == Timex.to_gregorian_seconds({1970, 1, 1})
  end

  test "date tuple to_erl" do
    assert {2015,2,28} = Timex.to_erl({2015,2,28})
  end

  test "datetime tuple to_erl" do
    assert {{2015,2,28}, {0,0,0}} = Timex.to_erl({{2015,2,28},{0,0,0}})
  end

  test "date tuple to_date" do
    assert %Date{:year => 2015, :month => 2, :day => 28} = Timex.to_date({2015,2,28})
  end

  test "datetime tuple to_datetime" do
    datetime = Timex.to_datetime({{2015,2,28}, {12,31,2}}, "Etc/UTC")
    assert ^datetime = Timex.to_datetime(~N[2015-02-28T12:31:02], "Etc/UTC")
  end

  test "date tuple to_unix" do
    assert 0 == Timex.to_unix({1970,1,1})
  end

  test "datetime tuple to_unix" do
    assert 0 == Timex.to_unix({{1970,1,1}, {0,0,0}})
  end


  ## Map conversions

  test "map with timezone to_datetime" do
    datetime = %{"year" => "2015", "month" => "2",
      "day" => "28", "hour" => "13", "minute" => "37",
      "time_zone" => "Europe/Copenhagen"}
    |> Timex.Convert.convert_map
    assert ^datetime = Timex.to_datetime(~N[2015-02-28T13:37:00], "Europe/Copenhagen")
  end
end
