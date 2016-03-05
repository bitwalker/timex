defmodule ConvertableTests do
  use ExUnit.Case, async: true
  use Timex
  doctest Timex.Convertable

  ## Date conversions

  test "Date to_gregorian_seconds" do
    assert Time.to_seconds(Time.epoch) == Date.epoch |> Timex.to_gregorian_seconds
  end

  test "Date to_date" do
    date = Timex.date({2015, 2, 28})
    assert ^date = Timex.to_date(date)
  end

  test "Date to_datetime" do
    date = Timex.date({2015, 2, 28})
    datetime = Timex.datetime({2015, 2, 28})

    assert ^datetime = Timex.to_datetime(date)
  end

  test "Date to_unix" do
    assert 0 == Date.epoch |> Timex.to_unix
  end

  test "Date to_timestamp" do
    assert Time.zero == Date.epoch |> Timex.to_timestamp
  end

  ## DateTime conversions

  test "DateTime to_gregorian with fractional offset" do
    datetime = Timex.datetime({2016, 3, 5}, "Asia/Kolkata")
    assert {{2016,3,5},{0,0,0},{-5.5,"IST"}} = Timex.to_gregorian(datetime)
  end

  test "DateTime to_gregorian_seconds" do
    assert Time.to_seconds(Time.epoch) == DateTime.epoch |> Timex.to_gregorian_seconds
  end

  test "DateTime to_datetime" do
    datetime = Timex.datetime({{2015,2,28}, {12, 35, 1}})
    assert ^datetime = Timex.to_datetime(datetime)
  end

  test "DateTime to_unix" do
    assert 0 == DateTime.epoch |> Timex.to_unix
  end

  test "DateTime to_timestamp" do
    assert Time.zero == DateTime.epoch |> Timex.to_timestamp
  end

  ## Tuple conversions

  test "date tuple to_gregorian" do
    assert {{2015, 2, 28}, {0,0,0}, {0, "UTC"}} = Timex.to_gregorian({2015, 2, 28})
  end

  test "datetime tuple to_gregorian" do
    assert {{2015, 2, 28}, {12,31,2}, {0, "UTC"}} = Timex.to_gregorian({{2015, 2, 28}, {12,31,2}})
  end

  test "timestamp tuple to_gregorian" do
    assert {{2015, 2, 28}, {0,0,0}, {0, "UTC"}} = Timex.to_gregorian(Date.to_timestamp(Timex.date({2015,2,28})))
  end

  test "date tuple to_gregorian_seconds" do
    assert Time.to_seconds(Time.epoch) == Timex.to_gregorian_seconds({1970, 1, 1})
  end

  test "date tuple to_erlang_datetime" do
    assert {{2015,2,28}, {0,0,0}} = Timex.to_erlang_datetime({2015,2,28})
  end

  test "datetime tuple to_erlang_datetime" do
    assert {{2015,2,28}, {0,0,0}} = Timex.to_erlang_datetime({{2015,2,28},{0,0,0}})
  end

  test "timestamp tuple to_erlang_datetime" do
    assert {{2015, 2, 28}, {0,0,0}} = Timex.to_erlang_datetime(Date.to_timestamp(Timex.date({2015,2,28})))
  end

  test "date tuple to_date" do
    assert %Date{:year => 2015, :month => 2, :day => 28} = Timex.to_date({2015,2,28})
  end

  test "date tuple to_datetime" do
    assert %DateTime{:year => 2015, :month => 2, :day => 28} = Timex.to_datetime({2015,2,28})
  end

  test "datetime tuple to_datetime" do
    datetime = Timex.datetime({{2015,2,28}, {12,31,2}})
    assert ^datetime = Timex.to_datetime({{2015,2,28},{12,31,2}})
  end

  test "date tuple to_unix" do
    assert 0 == Timex.to_unix({1970,1,1})
  end

  test "datetime tuple to_unix" do
    assert 0 == Timex.to_unix({{1970,1,1}, {0,0,0}})
    assert 0 == Timex.to_unix({{1970,1,1}, {0,0,0,0}})
  end

  test "invalid datetime tuple to_unix" do
    assert {:error, :invalid_date} == Timex.to_unix({{2015,2,29}, {0,0,0}})
    assert {:error, :invalid_date} == Timex.to_unix({{2015,2,29}, {0,0,0,0}})
  end

  test "timestamp tuple to_unix" do
    assert 0 == Timex.to_unix(Time.zero)
  end

  test "date tuple to_timestamp" do
    assert {0,0,0} = Timex.to_timestamp({1970,1,1})
    assert {:error, :invalid_date} = Timex.to_timestamp({2015,2,29})
  end

  test "datetime tuple to_timestamp" do
    assert {0,0,0} = Timex.to_timestamp({{1970,1,1},{0,0,0}})
    assert {:error, :invalid_date} = Timex.to_timestamp({{2015,2,29},{0,0,0}})
  end


end
